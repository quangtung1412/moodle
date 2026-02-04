#!/bin/bash
# Moodle Docker Restore Script
# This script restores database and moodledata from backup

set -e

# Check if backup timestamp is provided
if [ -z "$1" ]; then
    echo "Usage: $0 TIMESTAMP"
    echo ""
    echo "Available backups:"
    ls -1 ./backups/moodle_db_*.sql.gz 2>/dev/null | sed 's/.*moodle_db_\(.*\)\.sql\.gz/  \1/' || echo "  No backups found"
    echo ""
    echo "Example: $0 20260204_143000"
    exit 1
fi

TIMESTAMP="$1"
BACKUP_DIR="./backups"
MYSQL_CONTAINER="moodle_mysql"
MOODLE_CONTAINER="moodle_app"

# Check if backup files exist
DB_BACKUP="$BACKUP_DIR/moodle_db_${TIMESTAMP}.sql.gz"
MOODLEDATA_BACKUP="$BACKUP_DIR/moodledata_${TIMESTAMP}.tar.gz"
CONFIG_BACKUP="$BACKUP_DIR/config_${TIMESTAMP}.php"
INFO_FILE="$BACKUP_DIR/backup_${TIMESTAMP}_info.txt"

if [ ! -f "$DB_BACKUP" ]; then
    echo "Error: Database backup not found: $DB_BACKUP"
    exit 1
fi

if [ ! -f "$MOODLEDATA_BACKUP" ]; then
    echo "Error: Moodledata backup not found: $MOODLEDATA_BACKUP"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

echo "=========================================="
echo "Moodle Docker Restore"
echo "=========================================="
echo "Timestamp: $TIMESTAMP"
echo ""
echo "Files to restore:"
echo "  Database:   $DB_BACKUP"
echo "  Moodledata: $MOODLEDATA_BACKUP"
echo "  Config:     $CONFIG_BACKUP"
echo ""

if [ -f "$INFO_FILE" ]; then
    echo "Backup information:"
    cat "$INFO_FILE" | head -15
    echo ""
fi

# Warning
echo "=========================================="
echo "WARNING: This will REPLACE current data!"
echo "=========================================="
echo ""
echo "Current database and moodledata will be DELETED."
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""
echo "Starting restore process..."
echo ""

# Step 1: Put Moodle in maintenance mode
echo "1. Enabling maintenance mode..."
docker exec "$MOODLE_CONTAINER" php /var/www/html/public/admin/cli/maintenance.php --enable || true
echo ""

# Step 2: Stop containers
echo "2. Stopping containers..."
docker-compose stop
echo ""

# Step 3: Start MySQL only
echo "3. Starting MySQL..."
docker-compose up -d mysql

echo "   Waiting for MySQL to be ready..."
sleep 10

# Wait for MySQL to be healthy
MAX_WAIT=60
WAITED=0
while ! docker exec "$MYSQL_CONTAINER" mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" --silent 2>/dev/null; do
    echo "   MySQL not ready yet, waiting... ($WAITED/$MAX_WAIT seconds)"
    sleep 5
    WAITED=$((WAITED + 5))
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "   Error: MySQL failed to start"
        exit 1
    fi
done
echo "   MySQL is ready!"
echo ""

# Step 4: Drop and recreate database
echo "4. Recreating database..."
docker exec "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS ${MYSQL_DATABASE};"
docker exec "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${MYSQL_DATABASE} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
echo "   Database recreated"
echo ""

# Step 5: Restore database
echo "5. Restoring database..."
echo "   Decompressing and importing (this may take several minutes)..."
gunzip -c "$DB_BACKUP" | docker exec -i "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}"
echo "   Database restored successfully"
echo ""

# Step 6: Start Moodle container
echo "6. Starting Moodle container..."
docker-compose up -d moodle
echo "   Waiting for Moodle to be ready..."
sleep 15
echo ""

# Step 7: Restore moodledata
echo "7. Restoring moodledata..."
echo "   Removing old moodledata..."
docker exec "$MOODLE_CONTAINER" rm -rf /var/www/moodledata/* || true

echo "   Extracting backup (this may take several minutes)..."
docker cp "$MOODLEDATA_BACKUP" "$MOODLE_CONTAINER":/tmp/moodledata_backup.tar.gz
docker exec "$MOODLE_CONTAINER" tar -xzf /tmp/moodledata_backup.tar.gz -C /var/www/
docker exec "$MOODLE_CONTAINER" rm /tmp/moodledata_backup.tar.gz
echo "   Moodledata restored successfully"
echo ""

# Step 8: Restore config.php
if [ -f "$CONFIG_BACKUP" ]; then
    echo "8. Restoring config.php..."
    docker cp "$CONFIG_BACKUP" "$MOODLE_CONTAINER":/var/www/html/config.php
    echo "   Config restored successfully"
else
    echo "8. Skipping config.php (backup not found)"
fi
echo ""

# Step 9: Fix permissions
echo "9. Fixing permissions..."
docker exec "$MOODLE_CONTAINER" chown -R www-data:www-data /var/www/moodledata
docker exec "$MOODLE_CONTAINER" chmod -R 0770 /var/www/moodledata
docker exec "$MOODLE_CONTAINER" chown root:www-data /var/www/html/config.php
docker exec "$MOODLE_CONTAINER" chmod 644 /var/www/html/config.php
echo "   Permissions fixed"
echo ""

# Step 10: Disable maintenance mode
echo "10. Disabling maintenance mode..."
docker exec "$MOODLE_CONTAINER" php /var/www/html/public/admin/cli/maintenance.php --disable
echo ""

# Step 11: Purge caches
echo "11. Purging caches..."
docker exec "$MOODLE_CONTAINER" php /var/www/html/public/admin/cli/purge_caches.php
echo ""

# Step 12: Restart all services
echo "12. Restarting all services..."
docker-compose restart
echo ""

echo "   Waiting for services to be ready..."
sleep 10

# Verify
echo "=========================================="
echo "Restore Complete!"
echo "=========================================="
echo ""
echo "Verification:"
echo ""

# Check if Moodle is accessible
if curl -f -s -o /dev/null http://localhost:9000/; then
    echo "✓ Moodle is accessible at http://localhost:9000"
else
    echo "✗ Warning: Cannot access Moodle at http://localhost:9000"
    echo "  Check logs: docker-compose logs moodle"
fi

# Check database
TABLE_COUNT=$(docker exec "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" -e "SHOW TABLES;" 2>/dev/null | tail -n +2 | wc -l || echo "0")
echo "✓ Database has $TABLE_COUNT tables"

# Check moodledata
if docker exec "$MOODLE_CONTAINER" test -d /var/www/moodledata; then
    echo "✓ Moodledata directory exists"
else
    echo "✗ Warning: Moodledata directory not found"
fi

echo ""
echo "Next steps:"
echo "1. Test login at http://localhost:9000"
echo "2. Check Site administration → Reports → Logs"
echo "3. Verify files and courses are intact"
echo "4. Run scheduled tasks: docker exec moodle_app php /var/www/html/public/admin/cli/cron.php"
echo ""
echo "If you encounter issues, check logs:"
echo "  docker-compose logs -f moodle"
echo ""
echo "=========================================="
