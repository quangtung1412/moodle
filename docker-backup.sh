#!/bin/bash
# Moodle Docker Backup Script
# This script backs up both database and moodledata

set -e

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MYSQL_CONTAINER="moodle_mysql"
MOODLE_CONTAINER="moodle_app"

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "=========================================="
echo "Moodle Docker Backup"
echo "=========================================="
echo "Timestamp: $TIMESTAMP"
echo "Backup directory: $BACKUP_DIR"
echo ""

# Backup database
echo "1. Backing up MySQL database..."
DB_BACKUP_FILE="$BACKUP_DIR/moodle_db_${TIMESTAMP}.sql"

docker exec "$MYSQL_CONTAINER" mysqldump \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    "${MYSQL_DATABASE}" > "$DB_BACKUP_FILE"

# Compress database backup
echo "   Compressing database backup..."
gzip "$DB_BACKUP_FILE"
DB_BACKUP_FILE="${DB_BACKUP_FILE}.gz"

echo "   Database backed up to: $DB_BACKUP_FILE"
DB_SIZE=$(du -h "$DB_BACKUP_FILE" | cut -f1)
echo "   Size: $DB_SIZE"
echo ""

# Backup moodledata
echo "2. Backing up moodledata directory..."
MOODLEDATA_BACKUP_FILE="$BACKUP_DIR/moodledata_${TIMESTAMP}.tar.gz"

docker exec "$MOODLE_CONTAINER" tar -czf /tmp/moodledata_backup.tar.gz -C /var/www moodledata

docker cp "$MOODLE_CONTAINER":/tmp/moodledata_backup.tar.gz "$MOODLEDATA_BACKUP_FILE"

docker exec "$MOODLE_CONTAINER" rm /tmp/moodledata_backup.tar.gz

echo "   Moodledata backed up to: $MOODLEDATA_BACKUP_FILE"
MOODLEDATA_SIZE=$(du -h "$MOODLEDATA_BACKUP_FILE" | cut -f1)
echo "   Size: $MOODLEDATA_SIZE"
echo ""

# Backup config.php
echo "3. Backing up config.php..."
CONFIG_BACKUP_FILE="$BACKUP_DIR/config_${TIMESTAMP}.php"

if docker exec "$MOODLE_CONTAINER" test -f /var/www/html/config.php; then
    docker cp "$MOODLE_CONTAINER":/var/www/html/config.php "$CONFIG_BACKUP_FILE"
    echo "   Config backed up to: $CONFIG_BACKUP_FILE"
else
    echo "   Warning: config.php not found, skipping"
fi
echo ""

# Create backup info file
echo "4. Creating backup info file..."
INFO_FILE="$BACKUP_DIR/backup_${TIMESTAMP}_info.txt"

cat > "$INFO_FILE" <<EOF
Moodle Docker Backup Information
================================

Backup Date: $(date)
Timestamp: $TIMESTAMP

Files:
------
Database:   moodle_db_${TIMESTAMP}.sql.gz ($DB_SIZE)
Moodledata: moodledata_${TIMESTAMP}.tar.gz ($MOODLEDATA_SIZE)
Config:     config_${TIMESTAMP}.php

Environment:
------------
MySQL Database: ${MYSQL_DATABASE}
MySQL User: ${MYSQL_USER}
Moodle WWW Root: ${MOODLE_WWWROOT:-Not set}

Docker Containers:
------------------
$(docker compose ps)

Database Tables:
----------------
$(docker exec "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" -e "SHOW TABLES;" | tail -n +2 | wc -l) tables

Restore Instructions:
---------------------
To restore this backup:

1. Stop containers:
   docker compose down

2. Remove old volumes (WARNING: destroys current data):
   docker volume rm moodle_mysql_data moodle_moodle_data

3. Start containers:
   docker compose up -d

4. Wait for MySQL to be ready:
   sleep 30

5. Restore database:
   gunzip -c $DB_BACKUP_FILE | docker exec -i $MYSQL_CONTAINER mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}"

6. Restore moodledata:
   docker exec -i $MOODLE_CONTAINER tar -xzf - -C /var/www < $MOODLEDATA_BACKUP_FILE

7. Restore config.php:
   docker cp $CONFIG_BACKUP_FILE $MOODLE_CONTAINER:/var/www/html/config.php

8. Fix permissions:
   docker exec $MOODLE_CONTAINER chown -R www-data:www-data /var/www/moodledata
   docker exec $MOODLE_CONTAINER chmod -R 0770 /var/www/moodledata

9. Restart:
   docker compose restart
EOF

echo "   Backup info saved to: $INFO_FILE"
echo ""

# Summary
echo "=========================================="
echo "Backup Complete!"
echo "=========================================="
echo ""
echo "Backup files created:"
echo "  - $DB_BACKUP_FILE"
echo "  - $MOODLEDATA_BACKUP_FILE"
echo "  - $CONFIG_BACKUP_FILE"
echo "  - $INFO_FILE"
echo ""

TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "Total backup size: $TOTAL_SIZE"
echo ""
echo "To restore this backup, see: $INFO_FILE"
echo ""

# Cleanup old backups (optional)
echo "Checking for old backups..."
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/moodle_db_*.sql.gz 2>/dev/null | wc -l)
echo "Total backups: $BACKUP_COUNT"

if [ "$BACKUP_COUNT" -gt 10 ]; then
    echo ""
    echo "WARNING: You have more than 10 backups."
    echo "Consider removing old backups to save disk space:"
    echo "  ls -lt $BACKUP_DIR/"
    echo "  rm $BACKUP_DIR/moodle_db_YYYYMMDD_*.sql.gz"
fi

echo ""
echo "=========================================="
