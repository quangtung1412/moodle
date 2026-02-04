# Moodle Docker - Troubleshooting Guide

## Quick Diagnostics

### 1. Run the health check script

```bash
bash docker-healthcheck.sh
```

This will check all services and report any issues.

### 2. Check container status

```bash
docker-compose ps
```

All services should show "Up" and "healthy".

### 3. View logs

```bash
# All services
docker-compose logs -f

# Just Moodle
docker-compose logs -f moodle

# Just MySQL
docker-compose logs -f mysql

# Last 100 lines
docker-compose logs --tail=100 moodle
```

## Common Issues

### Issue: "Cannot connect to database"

**Symptoms:**
- Error message: "Error connecting to database"
- Moodle installation fails
- Web page shows database error

**Causes:**
1. MySQL container not ready yet
2. Wrong database hostname
3. Wrong credentials
4. MySQL failed to start

**Solutions:**

```bash
# 1. Check MySQL is running and healthy
docker-compose ps mysql

# Should show: Up (healthy)

# 2. Check MySQL logs
docker-compose logs mysql | tail -50

# 3. Test database connection from Moodle container
docker exec -it moodle_app mysql -h mysql -u moodleuser -pmoodlepassword -e "SELECT 1"

# Should return: 1

# 4. Verify credentials in .env
cat .env | grep MYSQL

# 5. If using manual installation via web, make sure hostname is "mysql" not "localhost"

# 6. Restart services
docker-compose restart mysql
sleep 10
docker-compose restart moodle
```

### Issue: "Data directory is not writable"

**Symptoms:**
- Installation fails with permission error
- Cannot save files or cache

**Solutions:**

```bash
# Fix permissions
docker exec -it moodle_app chown -R www-data:www-data /var/www/moodledata
docker exec -it moodle_app chmod -R 0770 /var/www/moodledata

# Verify
docker exec -it moodle_app ls -la /var/www/ | grep moodledata

# Should show:
# drwxrwx--- www-data www-data ... moodledata
```

### Issue: "Installation stuck or very slow"

**Symptoms:**
- Installation taking more than 20 minutes
- Browser shows spinning/loading forever
- Container logs show no activity

**Solutions:**

```bash
# 1. Check Docker resources
# Docker Desktop -> Settings -> Resources
# Ensure: 4GB+ RAM, 2+ CPUs

# 2. Check disk space
docker system df

# 3. Restart installation from scratch
docker-compose down -v
docker-compose up -d --build

# 4. Watch logs for errors
docker-compose logs -f moodle
```

### Issue: "Port already in use"

**Symptoms:**
- Error: "bind: address already in use"
- Cannot start containers

**Solutions:**

```bash
# 1. Check what's using the port
# Windows PowerShell:
netstat -ano | findstr :9000

# 2. Option A: Stop the conflicting service

# 3. Option B: Change port in docker-compose.yml
# Edit docker-compose.yml:
services:
  moodle:
    ports:
      - "8080:80"  # Change 9000 to 8080

# Then update .env:
MOODLE_WWWROOT=http://localhost:8080
```

### Issue: "Cron not running"

**Symptoms:**
- Scheduled tasks not executing
- Email queue not being processed
- Moodle admin shows cron warnings

**Solutions:**

```bash
# 1. Check cron is running
docker exec -it moodle_app pgrep cron

# Should return a process ID

# 2. Check supervisor
docker exec -it moodle_app supervisorctl status

# Should show:
# apache2    RUNNING
# cron       RUNNING

# 3. Manually run cron to test
docker exec -it moodle_app php /var/www/html/public/admin/cli/cron.php

# 4. Check cron logs
docker exec -it moodle_app tail -100 /var/log/syslog | grep CRON

# 5. Restart container
docker-compose restart moodle
```

### Issue: "config.php not found or incorrect"

**Symptoms:**
- Moodle shows installation wizard even after installation
- Database connection errors after restart

**Solutions:**

```bash
# 1. Check if config.php exists
docker exec -it moodle_app ls -la /var/www/html/config.php

# 2. View config.php
docker exec -it moodle_app cat /var/www/html/config.php

# 3. Check database settings
docker exec -it moodle_app grep "dbhost\|dbname\|dbuser" /var/www/html/config.php

# Should show:
# $CFG->dbhost    = 'mysql';
# $CFG->dbname    = 'moodle';
# $CFG->dbuser    = 'moodleuser';

# 4. Recreate config.php
docker exec -it moodle_app rm /var/www/html/config.php
docker-compose restart moodle
# Wait for entrypoint to recreate it
```

### Issue: "Email not being sent"

**Symptoms:**
- Users not receiving emails
- Email queue building up
- No emails in MailHog

**Solutions for Development:**

```bash
# 1. Check MailHog is running
docker-compose ps mailhog

# 2. Access MailHog UI
# Open: http://localhost:9003

# 3. Check Moodle email settings
docker exec -it moodle_app grep smtp /var/www/html/config.php

# Should show:
# $CFG->smtphosts = 'mailhog:1025';

# 4. Test email from Moodle
# Login to Moodle -> Site administration -> Server -> Test outgoing mail configuration

# 5. Check Moodle logs
# Login to Moodle -> Site administration -> Reports -> Logs -> Filter by "email"
```

**Solutions for Production:**

See [DOCKER_README.md](DOCKER_README.md) section "Môi trường Production" for configuring real SMTP.

### Issue: "White screen / 500 error"

**Symptoms:**
- Blank white page
- HTTP 500 Internal Server Error
- No error message displayed

**Solutions:**

```bash
# 1. Enable debugging
docker exec -it moodle_app bash
cat >> /var/www/html/config.php <<'EOF'
@error_reporting(E_ALL | E_STRICT);
@ini_set('display_errors', '1');
$CFG->debug = (E_ALL | E_STRICT);
$CFG->debugdisplay = 1;
EOF
exit

# 2. Check Apache error logs
docker-compose logs moodle | grep -i error

# 3. Check PHP error logs
docker exec -it moodle_app tail -100 /var/log/php_errors.log

# 4. Check file permissions
docker exec -it moodle_app ls -la /var/www/html/config.php
# Should be readable: -rw-r--r--

# 5. Clear all caches
docker exec -it moodle_app php /var/www/html/public/admin/cli/purge_caches.php

# 6. Restart Apache
docker-compose restart moodle
```

### Issue: "Performance is very slow"

**Symptoms:**
- Pages take 10+ seconds to load
- Installation takes 30+ minutes
- High CPU/memory usage

**Solutions:**

```bash
# 1. Increase Docker resources
# Docker Desktop -> Settings -> Resources
# Recommended:
#   CPU: 4+ cores
#   Memory: 8GB
#   Swap: 2GB
#   Disk: 60GB+

# 2. Check resource usage
docker stats moodle_app

# 3. Increase PHP memory
# Edit Dockerfile:
echo 'memory_limit = 1024M';

# Rebuild:
docker-compose up -d --build

# 4. Check if using bind mount in production
# For production, don't mount source code
# Edit docker-compose.yml and comment out:
# - ./:/var/www/html:rw

# 5. Enable opcache (already enabled by default)
docker exec -it moodle_app php -i | grep opcache.enable

# Should show: opcache.enable => On => On

# 6. Check MySQL performance
docker exec -it moodle_mysql mysql -u root -prootpassword -e "SHOW PROCESSLIST;"

# 7. Increase MySQL buffer pool
# Edit docker-compose.yml:
command: >
  --innodb-buffer-pool-size=1G
```

### Issue: "Cannot access Moodle from other computers"

**Symptoms:**
- Works on localhost but not from other machines
- Network timeout from other computers

**Solutions:**

```bash
# 1. Check firewall allows port 9000
# Windows Firewall:
netsh advfirewall firewall add rule name="Moodle Docker" dir=in action=allow protocol=TCP localport=9000

# 2. Update MOODLE_WWWROOT in .env
# Replace localhost with your machine's IP
MOODLE_WWWROOT=http://192.168.1.100:9000

# 3. Restart Moodle
docker-compose restart moodle

# 4. Verify Docker port binding
docker-compose ps
# Should show: 0.0.0.0:9000->80/tcp

# 5. Test from other computer
# From other machine:
curl http://YOUR_MACHINE_IP:9000
```

## Reset Everything (Nuclear Option)

If all else fails, start completely fresh:

```bash
# WARNING: This deletes ALL data including database!

# 1. Stop and remove containers
docker-compose down -v

# 2. Remove config.php if exists
rm config.php

# 3. Clean Docker system (optional)
docker system prune -a --volumes

# 4. Start fresh
docker-compose up -d --build

# 5. Watch installation
docker-compose logs -f moodle
```

## Getting Help

If you still have issues:

1. **Check logs thoroughly:**
   ```bash
   docker-compose logs --tail=500 moodle > moodle_logs.txt
   docker-compose logs --tail=500 mysql > mysql_logs.txt
   ```

2. **Verify environment:**
   ```bash
   docker version
   docker-compose version
   cat .env
   ```

3. **Search Moodle forums:**
   - https://moodle.org/course/view.php?id=5

4. **Check Docker documentation:**
   - See [DOCKER_README.md](DOCKER_README.md)

5. **System information:**
   ```bash
   docker exec -it moodle_app php /var/www/html/public/admin/cli/check_database_schema.php
   docker exec -it moodle_app php -v
   docker exec -it moodle_app mysql --version
   ```

## Prevention / Best Practices

To avoid issues:

- ✅ Always use `.env` file for configuration
- ✅ Don't modify files inside running containers
- ✅ Use docker-compose for all operations
- ✅ Regular backups before major changes
- ✅ Keep Docker and images updated
- ✅ Monitor logs regularly
- ✅ Use health check script periodically
- ✅ Test in development before deploying to production
