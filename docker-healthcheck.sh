#!/bin/bash
# Moodle Docker Health Check Script
# This script checks if all services are running correctly

set -e

echo "=========================================="
echo "Moodle Docker Health Check"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if docker-compose is running
echo "1. Checking Docker Compose services..."
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓${NC} Docker Compose services are running"
else
    echo -e "${RED}✗${NC} Docker Compose services are not running"
    echo "   Run: docker-compose up -d"
    exit 1
fi
echo ""

# Check MySQL
echo "2. Checking MySQL database..."
if docker exec moodle_mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-rootpassword} --silent 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MySQL is running and responsive"
else
    echo -e "${RED}✗${NC} MySQL is not responding"
    echo "   Check logs: docker-compose logs mysql"
    exit 1
fi
echo ""

# Check Moodle container
echo "3. Checking Moodle container..."
if docker ps | grep -q moodle_app; then
    echo -e "${GREEN}✓${NC} Moodle container is running"
    
    # Check Apache
    if docker exec moodle_app pgrep apache2 >/dev/null; then
        echo -e "${GREEN}✓${NC} Apache web server is running"
    else
        echo -e "${RED}✗${NC} Apache is not running"
    fi
    
    # Check Cron
    if docker exec moodle_app pgrep cron >/dev/null; then
        echo -e "${GREEN}✓${NC} Cron daemon is running"
    else
        echo -e "${RED}✗${NC} Cron is not running"
    fi
else
    echo -e "${RED}✗${NC} Moodle container is not running"
    echo "   Run: docker-compose up -d"
    exit 1
fi
echo ""

# Check if Moodle is installed
echo "4. Checking Moodle installation..."
if docker exec moodle_app test -f /var/www/moodledata/.moodle_installed; then
    echo -e "${GREEN}✓${NC} Moodle is installed"
else
    echo -e "${YELLOW}⚠${NC} Moodle installation not complete"
    echo "   This is normal if you just started the containers"
    echo "   Check installation logs: docker-compose logs -f moodle"
fi
echo ""

# Check config.php
echo "5. Checking Moodle configuration..."
if docker exec moodle_app test -f /var/www/html/config.php; then
    echo -e "${GREEN}✓${NC} config.php exists"
else
    echo -e "${RED}✗${NC} config.php not found"
    echo "   The entrypoint should create it automatically"
fi
echo ""

# Check permissions
echo "6. Checking directory permissions..."
MOODLEDATA_PERMS=$(docker exec moodle_app stat -c "%a" /var/www/moodledata 2>/dev/null || echo "000")
if [ "$MOODLEDATA_PERMS" = "770" ] || [ "$MOODLEDATA_PERMS" = "777" ]; then
    echo -e "${GREEN}✓${NC} moodledata permissions are correct ($MOODLEDATA_PERMS)"
else
    echo -e "${YELLOW}⚠${NC} moodledata permissions might be wrong ($MOODLEDATA_PERMS)"
    echo "   Expected: 770 or 777"
    echo "   Run: docker exec moodle_app chown -R www-data:www-data /var/www/moodledata"
fi
echo ""

# Check web accessibility
echo "7. Checking web accessibility..."
if curl -f -s -o /dev/null http://localhost:9000/; then
    echo -e "${GREEN}✓${NC} Moodle is accessible at http://localhost:9000"
else
    echo -e "${RED}✗${NC} Cannot access Moodle at http://localhost:9000"
    echo "   Wait a few minutes and try again"
    echo "   Check logs: docker-compose logs moodle"
fi
echo ""

# Check phpMyAdmin
echo "8. Checking phpMyAdmin..."
if docker ps | grep -q moodle_phpmyadmin; then
    if curl -f -s -o /dev/null http://localhost:9002/; then
        echo -e "${GREEN}✓${NC} phpMyAdmin is accessible at http://localhost:9002"
    else
        echo -e "${YELLOW}⚠${NC} phpMyAdmin container running but not accessible"
    fi
else
    echo -e "${YELLOW}⚠${NC} phpMyAdmin is not running (optional service)"
fi
echo ""

# Check MailHog
echo "9. Checking MailHog..."
if docker ps | grep -q moodle_mailhog; then
    if curl -f -s -o /dev/null http://localhost:9003/; then
        echo -e "${GREEN}✓${NC} MailHog is accessible at http://localhost:9003"
    else
        echo -e "${YELLOW}⚠${NC} MailHog container running but not accessible"
    fi
else
    echo -e "${YELLOW}⚠${NC} MailHog is not running (optional service)"
fi
echo ""

# Summary
echo "=========================================="
echo "Health Check Summary"
echo "=========================================="
echo ""
echo "Services:"
echo "  Moodle:      http://localhost:9000"
echo "  phpMyAdmin:  http://localhost:9002"
echo "  MailHog:     http://localhost:9003"
echo ""
echo "Useful commands:"
echo "  View logs:        docker-compose logs -f moodle"
echo "  Shell access:     docker exec -it moodle_app bash"
echo "  Restart:          docker-compose restart"
echo "  Stop:             docker-compose down"
echo ""
echo "For more help, see DOCKER_README.md"
echo "=========================================="
