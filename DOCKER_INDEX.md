# Moodle Docker Setup - File Index

## 📚 Documentation Files

### Quick Start
- **[QUICKSTART.md](QUICKSTART.md)** - Get Moodle running in 5 minutes
  - For users who want to start immediately
  - Basic setup only
  - Default configuration

### Complete Guide
- **[DOCKER_README.md](DOCKER_README.md)** - Comprehensive documentation
  - Architecture overview
  - Automatic installation details
  - Manual installation via web GUI
  - Production deployment
  - Advanced configuration
  - Performance tuning
  - Security best practices
  - CLI commands reference

### Troubleshooting
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
  - Database connection problems
  - Permission errors
  - Performance issues
  - Email configuration
  - Port conflicts
  - Reset procedures

## 🔧 Configuration Files

### Docker Configuration
- **[Dockerfile](Dockerfile)** - Moodle container image definition
  - Based on PHP 8.2 Apache
  - All required PHP extensions
  - Cron and Supervisor setup
  - Apache configuration for /public directory
  
- **[docker-compose.yml](docker-compose.yml)** - Multi-container orchestration
  - Moodle application
  - MySQL 8.4 database
  - phpMyAdmin
  - MailHog (email testing)

- **[docker-entrypoint.sh](docker-entrypoint.sh)** - Automatic setup script
  - Waits for database readiness
  - Creates config.php automatically
  - Runs CLI installer
  - Sets up permissions
  - Handles upgrades

### Environment Configuration
- **[.env](.env)** - Default environment variables (development)
  - Database credentials
  - Moodle site settings
  - Admin account (default: admin/Admin@123)

- **[.env.production.example](.env.production.example)** - Production template
  - Strong password examples
  - HTTPS configuration
  - Security checklist
  - Deployment notes

### Ignore Files
- **[.dockerignore](.dockerignore)** - Files excluded from Docker build
  - Git files
  - Documentation
  - node_modules
  - IDE configurations

## 🛠️ Utility Scripts

### Health Check
- **[docker-healthcheck.sh](docker-healthcheck.sh)** - System diagnostics
  - Checks all services
  - Verifies database connectivity
  - Tests web accessibility
  - Validates permissions
  - Reports status of all components

### Backup & Restore
- **[docker-backup.sh](docker-backup.sh)** - Backup script
  - Backs up MySQL database
  - Backs up moodledata directory
  - Backs up config.php
  - Creates backup info file
  - Warns about old backups

- **[docker-restore.sh](docker-restore.sh)** - Restore script
  - Lists available backups
  - Restores database
  - Restores moodledata
  - Restores config.php
  - Fixes permissions
  - Verifies restoration

## 📖 Usage Guide

### First Time Setup

1. **Quick start (automatic):**
   ```bash
   docker compose up -d --build
   docker compose logs -f moodle
   # Wait 10-15 minutes
   # Access: http://localhost:9000
   # Login: admin / Admin@123
   ```

2. **Detailed setup:**
   - Read [QUICKSTART.md](QUICKSTART.md)
   - Customize `.env` if needed
   - Follow [DOCKER_README.md](DOCKER_README.md)

### Regular Operations

**View status:**
```bash
bash docker-healthcheck.sh
```

**View logs:**
```bash
docker compose logs -f moodle
```

**Backup:**
```bash
bash docker-backup.sh
```

**Restore:**
```bash
bash docker-restore.sh 20260204_143000
```

### Troubleshooting

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Run health check: `bash docker-healthcheck.sh`
3. Check logs: `docker compose logs -f`
4. See specific service logs: `docker compose logs mysql`

### Production Deployment

1. Copy `.env.production.example` to `.env.production`
2. Edit with strong passwords and real domain
3. Read "Production" section in [DOCKER_README.md](DOCKER_README.md)
4. Configure SSL/HTTPS
5. Disable development services (phpMyAdmin, MailHog)
6. Set up real SMTP server
7. Configure backups
8. Monitor logs

## 🎯 Quick Reference

### Services & Ports
| Service | URL | Port | Usage |
|---------|-----|------|-------|
| Moodle | http://localhost:9000 | 9000 | Main application |
| MySQL | localhost:9001 | 9001 | Database (external) |
| phpMyAdmin | http://localhost:9002 | 9002 | DB management |
| MailHog | http://localhost:9003 | 9003 | Email testing |

### Default Credentials

**Moodle Admin:**
- Username: `admin`
- Password: `Admin@123`
- Email: `admin@example.com`

**MySQL Root:**
- Username: `root`
- Password: `rootpassword`

**MySQL User:**
- Username: `moodleuser`
- Password: `moodlepassword`
- Database: `moodle`

**⚠️ Change these in production!**

### Common Commands

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Restart
docker compose restart

# Logs (all)
docker compose logs -f

# Logs (Moodle only)
docker compose logs -f moodle

# Shell access
docker exec -it moodle_app bash

# Health check
bash docker-healthcheck.sh

# Backup
bash docker-backup.sh

# Restore
bash docker-restore.sh TIMESTAMP

# Rebuild
docker compose up -d --build --force-recreate

# Nuclear option (deletes everything!)
docker compose down -v
docker compose up -d --build
```

### Moodle CLI Commands

```bash
# Run cron
docker exec moodle_app php /var/www/html/public/admin/cli/cron.php

# Purge caches
docker exec moodle_app php /var/www/html/public/admin/cli/purge_caches.php

# Upgrade
docker exec moodle_app php /var/www/html/public/admin/cli/upgrade.php --non-interactive

# Maintenance mode ON
docker exec moodle_app php /var/www/html/public/admin/cli/maintenance.php --enable

# Maintenance mode OFF
docker exec moodle_app php /var/www/html/public/admin/cli/maintenance.php --disable
```

## 🔒 Security Notes

**Development (default):**
- ✅ Default passwords are fine
- ✅ All services exposed (phpMyAdmin, MailHog)
- ✅ HTTP only
- ✅ Debug mode available

**Production (must configure):**
- ⚠️ Change ALL passwords
- ⚠️ Disable phpMyAdmin and MailHog
- ⚠️ Enable HTTPS with valid certificate
- ⚠️ Configure real SMTP server
- ⚠️ Don't mount source code
- ⚠️ Set up firewall rules
- ⚠️ Regular backups
- ⚠️ Monitor logs
- ⚠️ Keep updated

## 📋 Requirements Met

According to [Moodle Installation Quick Guide](https://docs.moodle.org/en/Installation_quick_guide):

✅ Web server (Apache 2.4)  
✅ Database (MySQL 8.4 with utf8mb4_unicode_ci)  
✅ PHP (8.2 with all required extensions)  
✅ Data directory (writable, outside web root)  
✅ Cron (runs every minute)  
✅ Proper permissions (code not writable by web server)  
✅ DocumentRoot = /public (Moodle 5.1+)  
✅ Mail configuration (MailHog for dev, configurable for prod)  

## 🆘 Getting Help

1. **Documentation:**
   - [DOCKER_README.md](DOCKER_README.md) - Complete guide
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
   - [Moodle Docs](https://docs.moodle.org/) - Official documentation

2. **Diagnostics:**
   - Run: `bash docker-healthcheck.sh`
   - Check logs: `docker-compose logs -f`

3. **Community:**
   - [Moodle Forums](https://moodle.org/course/view.php?id=5)
   - [Moodle Developer Docs](https://moodledev.io)

## 📝 Version Information

- **Moodle:** 5.1+ (MOODLE_501_STABLE)
- **PHP:** 8.2
- **MySQL:** 8.4
- **Apache:** 2.4
- **Docker Compose:** 3.8

## 🔄 Update History

**2026-02-04:**
- Initial Docker setup created
- Automatic installation via CLI
- Comprehensive documentation
- Health check and backup scripts
- Production deployment guide
- Troubleshooting guide

---

**For the fastest start:** See [QUICKSTART.md](QUICKSTART.md)  
**For complete information:** See [DOCKER_README.md](DOCKER_README.md)  
**Having issues?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
