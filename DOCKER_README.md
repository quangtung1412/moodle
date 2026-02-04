# Hướng dẫn cài đặt Moodle với Docker

## Tổng quan

Docker setup cho Moodle được xây dựng theo **Installation Quick Guide** chính thức từ Moodle.org, đáp ứng đầy đủ các yêu cầu:

- ✅ **PHP 8.2** với tất cả extensions bắt buộc
- ✅ **MySQL 8.4** với charset utf8mb4_unicode_ci
- ✅ **Apache** với DocumentRoot trỏ đến `/public` (Moodle 5.1+)
- ✅ **Cron job** chạy tự động mỗi phút
- ✅ **MailHog** cho email testing (development)
- ✅ **Tự động cài đặt** qua CLI installer
- ✅ **Security best practices** (code không writable bởi web server)

## Kiến trúc hệ thống

Hệ thống bao gồm 4 services:
- **Moodle**: http://localhost:9000 (Web application)
- **MySQL**: localhost:9001 (Database server)
- **phpMyAdmin**: http://localhost:9002 (Database management)
- **MailHog**: http://localhost:9003 (Email testing)

## Yêu cầu hệ thống

- Docker Desktop hoặc Docker Engine v20.10+
- Docker Compose v2.0+
- Ít nhất 4GB RAM available
- 10GB disk space trống

## Cài đặt nhanh (Automatic Installation)

### Bước 1: Clone repository (nếu chưa có)

```bash
git clone -b MOODLE_501_STABLE git://git.moodle.org/moodle.git
cd moodle
```

### Bước 2: Cấu hình biến môi trường (tùy chọn)

File `.env` chứa cấu hình mặc định. Bạn có thể chỉnh sửa nếu cần:

```env
# MySQL Database
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=moodle
MYSQL_USER=moodleuser
MYSQL_PASSWORD=moodlepassword

# Moodle Site
MOODLE_WWWROOT=http://localhost:9000
MOODLE_SITE_FULLNAME=Moodle Site
MOODLE_SITE_SHORTNAME=Moodle

# Admin Account (ĐỔI MẬT KHẨU TRONG PRODUCTION!)
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASSWORD=Admin@123
MOODLE_ADMIN_EMAIL=admin@example.com
```

**⚠️ QUAN TRỌNG**: Đổi mật khẩu TRƯỚC khi deploy production!

### Bước 3: Khởi động hệ thống

```bash
docker-compose up -d --build
```

**Lần đầu tiên sẽ mất 10-15 phút để:**
1. Build Docker image với tất cả dependencies
2. Cài đặt PHP extensions
3. Cài đặt Node.js và npm packages
4. Khởi động MySQL và chờ healthy
5. Tự động tạo config.php
6. Chạy Moodle CLI installer
7. Cài đặt database schema

### Bước 4: Theo dõi quá trình cài đặt

```bash
docker-compose logs -f moodle
```

Bạn sẽ thấy:
```
==========================================
Moodle Docker Entrypoint Script
==========================================
Waiting for database to be ready...
Database is ready!
Creating config.php...
Running Moodle CLI installation...
Moodle installation completed!
==========================================
Admin credentials:
  Username: admin
  Password: Admin@123
  Email: admin@example.com
==========================================
Starting Moodle services...
```

### Bước 5: Truy cập Moodle

Mở trình duyệt và truy cập: **http://localhost:9000**

Đăng nhập với:
- Username: `admin`
- Password: `Admin@123` (hoặc giá trị trong .env)

🎉 **Hoàn thành!** Moodle đã sẵn sàng sử dụng!

## Cài đặt thủ công (Manual Installation via Web GUI)

Nếu bạn muốn cài đặt thủ công qua giao diện web (không dùng auto-install):

### Bước 1: Disable auto-install

Xóa hoặc comment các biến môi trường admin trong `.env`:
```env
# MOODLE_ADMIN_USER=admin
# MOODLE_ADMIN_PASSWORD=Admin@123
# MOODLE_ADMIN_EMAIL=admin@example.com
```

### Bước 2: Khởi động containers

```bash
docker-compose up -d --build
```

### Bước 3: Truy cập Web GUI

Truy cập http://localhost:9000 và làm theo wizard:

1. **Chọn ngôn ngữ** → Next
2. **Xác nhận paths** (đã tự động điền) → Next
3. **Cấu hình database**:
   - Database type: `Improved MySQL (native/mysqli)`
   - Database host: `mysql` (**KHÔNG** dùng localhost)
   - Database name: `moodle`
   - Database user: `moodleuser`
   - Database password: `moodlepassword`
   - Tables prefix: `mdl_`
   - Database port: `3306`
4. **Đồng ý GPL license** → Continue
5. **Kiểm tra environment** → Continue
6. **Chờ installation** (5-10 phút)
7. **Tạo admin account**
8. **Cấu hình site** → Save changes

## Services và Ports

## Services và Ports

| Service | URL | Port | Mô tả |
|---------|-----|------|-------|
| Moodle | http://localhost:9000 | 9000 | Web application |
| MySQL | localhost:9001 | 9001 | Database (external access) |
| phpMyAdmin | http://localhost:9002 | 9002 | Database management UI |
| MailHog | http://localhost:9003 | 9003 | Email testing UI |

### Truy cập phpMyAdmin
### Truy cập phpMyAdmin

URL: http://localhost:9002

**Đăng nhập với root:**
- Server: `mysql`
- Username: `root`
- Password: `rootpassword` (hoặc giá trị trong .env)

Hoặc đăng nhập với user thường:
- Username: `moodleuser`
- Password: `moodlepassword`

Hoặc đăng nhập với user thường:
- Username: `moodleuser`
- Password: `moodlepassword`

### MailHog (Email Testing)

URL: http://localhost:9003

Tất cả email từ Moodle sẽ được gửi đến MailHog thay vì email thật. Rất hữu ích cho development và testing.

**Cấu hình email trong Moodle:**
- SMTP hosts: `mailhog:1025` (đã tự động cấu hình)
- No authentication required

## Tính năng tự động

## Tính năng tự động

### 1. Tự động tạo config.php

Script `docker-entrypoint.sh` tự động tạo file `config.php` theo chuẩn Moodle 5.1+ với:
- Database configuration từ environment variables
- WWW root và data directory paths
- SMTP configuration (MailHog)
- Security settings
- Performance optimization

### 2. Tự động cài đặt qua CLI

Nếu có đủ thông tin admin trong `.env`, hệ thống sẽ:
1. Chờ database sẵn sàng
2. Tạo config.php
3. Chạy `admin/cli/install.php` với `--non-interactive`
4. Tạo admin account
5. Cài đặt database schema
6. Đánh dấu installation complete

### 3. Cron Job tự động
### 3. Cron Job tự động

Container tự động chạy Moodle cron **mỗi phút** theo đúng yêu cầu chính thức:

```bash
* * * * * /usr/local/bin/php /var/www/html/public/admin/cli/cron.php
```

Không cần cấu hình thêm. Kiểm tra cron logs:
```bash
docker exec moodle_app grep cron /var/log/syslog
```

### 4. Process Management với Supervisor
### 4. Process Management với Supervisor

Supervisor quản lý 2 processes trong container:
- **Apache** (web server)
- **Cron** (scheduled tasks)

Cả hai tự động restart nếu crash. Kiểm tra status:
```bash
docker exec moodle_app supervisorctl status
```

### 5. Auto Upgrade

Khi container restart với version mới, entrypoint script tự động:
```bash
php /var/www/html/public/admin/cli/upgrade.php --non-interactive
```

## Kiến trúc và Permissions (Security Best Practices)

Theo **Installation Quick Guide**, Docker setup tuân thủ security:

### File Permissions

**Moodle Code** (không writable bởi web server):
```bash
Owner: root:www-data
Files: 0644 (rw-r--r--)
Dirs:  0755 (rwxr-xr-x)
```

**Moodledata** (writable bởi web server):
```bash
Owner: www-data:www-data
Permissions: 0770 (rwxrwx---)
```

Kiểm tra:
```bash
docker exec moodle_app ls -la /var/www/html
docker exec moodle_app ls -la /var/www/moodledata
```

### Directory Structure (Moodle 5.1+)

```
/var/www/html/               # Moodle base directory
├── config.php               # Main config (base directory)
├── composer.json
├── lib/
│   └── setup.php
├── admin/
│   └── cli/
│       ├── cron.php        # Cron script
│       ├── install.php     # CLI installer
│       └── upgrade.php     # CLI upgrader
└── public/                 # Web root (DocumentRoot)
    ├── index.php           # Entry point
    ├── config.php          # Symbolic link to ../config.php
    ├── admin/
    ├── lib/
    └── ...

/var/www/moodledata/        # Data directory (outside web root)
├── cache/
├── lang/
├── localcache/
├── sessions/
├── temp/
└── trashdir/
```

**Apache DocumentRoot**: `/var/www/html/public` (Moodle 5.1+ requirement)

## Các lệnh quản lý

### Xem logs
```bash
# Tất cả services
docker-compose logs -f

# Chỉ Moodle
docker-compose logs -f moodle

# Chỉ MySQL
docker-compose logs -f mysql
```

### Dừng containers
```bash
docker-compose stop
```

### Khởi động lại
```bash
docker-compose restart
```

### Dừng và xóa containers (GIỮ dữ liệu)
```bash
docker-compose down
```

### Dừng và XÓA TẤT CẢ (bao gồm database)
```bash
docker-compose down -v
```

### Rebuild từ đầu
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Truy cập shell trong container
```bash
# Moodle container
docker exec -it moodle_app bash

# MySQL container
docker exec -it moodle_mysql bash
```

## Cấu trúc thư mục và Volumes

```
moodle/
├── Dockerfile                  # Moodle container definition
├── docker-compose.yml          # Services orchestration
├── docker-entrypoint.sh        # Auto-install script
├── .env                        # Environment variables
├── .dockerignore              # Files excluded from build
├── config.php                 # Moodle config (auto-created)
├── public/                    # Web root
│   ├── index.php
│   ├── admin/
│   │   └── cli/
│   │       ├── cron.php
│   │       ├── install.php
│   │       └── upgrade.php
│   └── lib/
└── Docker volumes:
    ├── mysql_data/            # MySQL persistent data
    └── moodle_data/           # Moodle files (uploads, cache, etc.)
```

**Persistent Volumes:**
- `mysql_data`: Database storage (survives container restart/rebuild)
- `moodle_data`: Uploaded files, cache, sessions (survives container restart)

## Xử lý sự cố (Troubleshooting)

### Container không start

```bash
# Kiểm tra logs
docker-compose logs moodle
docker-compose logs mysql

# Kiểm tra status
docker-compose ps

# Rebuild từ đầu
docker-compose down
docker-compose up -d --build
```

### Database connection failed

**Triệu chứng:** "Error: Database connection failed"

**Nguyên nhân thường gặp:**
1. MySQL chưa sẵn sàng → Chờ thêm vài giây
2. Sai database host → Phải dùng `mysql` không phải `localhost`
3. Sai credentials → Kiểm tra `.env`

**Giải pháp:**
```bash
# Kiểm tra MySQL health
docker-compose ps mysql

# Test connection từ Moodle container
docker exec -it moodle_app mysql -h mysql -u moodleuser -pmoodlepassword -e "SELECT 1"

# Xem MySQL logs
docker-compose logs mysql | tail -50
```

### Data directory not writable

**Triệu chứng:** "Data directory is not writable"

**Giải pháp:**
```bash
# Fix permissions
docker exec -it moodle_app chown -R www-data:www-data /var/www/moodledata
docker exec -it moodle_app chmod -R 0770 /var/www/moodledata

# Verify
docker exec -it moodle_app ls -la /var/www/ | grep moodledata
```

### Installation failed / stuck

**Giải pháp:**
```bash
# Stop containers
docker-compose down

# Remove volumes (XÓA TẤT CẢ DỮ LIỆU!)
docker-compose down -v

# Start fresh
docker-compose up -d --build
```

### Cron không chạy

**Kiểm tra:**
```bash
# Xem cron logs
docker exec -it moodle_app cat /var/log/syslog | grep CRON

# Xem Moodle cron logs
docker exec -it moodle_app tail -50 /var/www/moodledata/cron.log

# Check supervisor
docker exec -it moodle_app supervisorctl status
```

### Performance chậm

**Giải pháp:**

1. **Tăng PHP memory:**
```dockerfile
# Trong Dockerfile
echo 'memory_limit = 1024M';
```

2. **Tăng MySQL memory:**
```yaml
# Trong docker-compose.yml
command: >
  --innodb-buffer-pool-size=1G
```

3. **Tăng Docker resources:**
   - Docker Desktop → Settings → Resources
   - CPU: 4+ cores
   - Memory: 8GB+

4. **Disable live code mounting (production):**
```yaml
# Comment out trong docker-compose.yml
# - ./:/var/www/html:rw
```

### Port conflicts

**Triệu chứng:** "Port 9000 is already in use"

**Giải pháp:** Đổi port trong `docker-compose.yml`:
```yaml
services:
  moodle:
    ports:
      - "8080:80"  # Đổi 9000 → 8080
  mysql:
    ports:
      - "3307:3306"  # Đổi 9001 → 3307
```

### Email không gửi được

**Kiểm tra MailHog:**
```bash
# Truy cập http://localhost:9003
# Email sẽ hiện trong MailHog UI

# Check SMTP config trong Moodle
docker exec -it moodle_app grep smtp /var/www/html/config.php
```

## Backup và Restore

### Backup
```bash
# Backup database
docker exec moodle_mysql mysqldump -u root -prootpassword moodle > backup_$(date +%Y%m%d).sql

# Backup moodledata
docker cp moodle_app:/var/www/moodledata ./backup_moodledata
```

### Restore
```bash
# Restore database
docker exec -i moodle_mysql mysql -u root -prootpassword moodle < backup_20260129.sql

# Restore moodledata
docker cp ./backup_moodledata moodle_app:/var/www/
```

## Cấu hình nâng cao

### Thay đổi PHP settings
Edit Dockerfile và rebuild:
```dockerfile
echo 'memory_limit = 1024M'; \
```

### Thay đổi MySQL settings
Edit docker-compose.yml command section.

### Thay đổi MySQL settings
Edit docker-compose.yml command section.

### Môi trường Production

**Bước 1:** Tạo `.env.production`:
```env
# Strong passwords!
MYSQL_ROOT_PASSWORD=your_very_strong_password_here
MYSQL_PASSWORD=another_strong_password

# Real domain
MOODLE_WWWROOT=https://yourdomain.com

# Admin credentials
MOODLE_ADMIN_PASSWORD=VeryStrongPassword123!@#
MOODLE_ADMIN_EMAIL=admin@yourdomain.com
```

**Bước 2:** Cấu hình SSL/HTTPS:
```yaml
# docker-compose.yml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./certs:/etc/nginx/certs
      
  moodle:
    environment:
      VIRTUAL_HOST: yourdomain.com
      LETSENCRYPT_HOST: yourdomain.com
```

**Bước 3:** Tối ưu hóa:
```yaml
# docker-compose.yml - Production settings
moodle:
  environment:
    PHP_MEMORY_LIMIT: 1024M
    PHP_MAX_EXECUTION_TIME: 600
  # KHÔNG mount source code
  volumes:
    - moodle_data:/var/www/moodledata:rw
    # Bỏ: - ./:/var/www/html:rw
```

**Bước 4:** Disable development tools:
```yaml
# Bỏ hoặc comment:
# phpmyadmin: ...
# mailhog: ...
```

**Bước 5:** Cấu hình real SMTP:
```php
// Trong config.php hoặc qua Moodle admin
$CFG->smtphosts = 'smtp.gmail.com:587';
$CFG->smtpsecure = 'tls';
$CFG->smtpauthtype = 'LOGIN';
$CFG->smtpuser = 'your-email@gmail.com';
$CFG->smtppass = 'your-app-password';
$CFG->noreplyaddress = 'noreply@yourdomain.com';
```

### SSL/HTTPS với Let's Encrypt

Sử dụng nginx-proxy và letsencrypt-companion:

```yaml
# docker-compose.production.yml
version: '3.8'

services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - nginx-certs:/etc/nginx/certs
      - nginx-vhost:/etc/nginx/vhost.d
      - nginx-html:/usr/share/nginx/html
    networks:
      - moodle_network

  letsencrypt:
    image: nginxproxy/acme-companion
    container_name: letsencrypt
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - nginx-certs:/etc/nginx/certs
      - nginx-vhost:/etc/nginx/vhost.d
      - nginx-html:/usr/share/nginx/html
    environment:
      DEFAULT_EMAIL: admin@yourdomain.com
    depends_on:
      - nginx-proxy
    networks:
      - moodle_network

  moodle:
    # ... existing config ...
    environment:
      VIRTUAL_HOST: moodle.yourdomain.com
      LETSENCRYPT_HOST: moodle.yourdomain.com
      LETSENCRYPT_EMAIL: admin@yourdomain.com
      MOODLE_WWWROOT: https://moodle.yourdomain.com

volumes:
  nginx-certs:
  nginx-vhost:
  nginx-html:
```

Deploy:
```bash
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

## Requirements đã được đáp ứng (theo Installation Quick Guide)

✅ **Web Server:** Apache 2.4 với mod_rewrite, mod_ssl, mod_headers  
✅ **Database:** MySQL 8.4 với utf8mb4_unicode_ci collation  
✅ **PHP:** 8.2 với tất cả extensions bắt buộc  
✅ **PHP Extensions:**
  - iconv, mbstring, curl, openssl, ctype, zip, zlib
  - gd (với freetype, jpeg), simplexml, spl, pcre, dom, xml
  - xmlreader, intl, json, hash, fileinfo, sodium
  - pdo_mysql, mysqli, exif, soap, opcache, xmlrpc, ldap

✅ **DocumentRoot:** `/var/www/html/public` (Moodle 5.1+ requirement)  
✅ **Data Directory:** `/var/www/moodledata` (outside web root, writable)  
✅ **Cron:** Chạy mỗi phút via crontab  
✅ **Permissions:** Code không writable, data writable (security best practice)  
✅ **Mail:** MailHog SMTP server cho development  
✅ **Database User:** Có đủ permissions theo guide (SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER)  
✅ **Auto Installation:** CLI installer với --non-interactive  
✅ **Auto Upgrade:** Tự động upgrade khi restart với version mới  

## PHP Extensions chi tiết

**Required (composer.json):**
```json
"php": ">=8.3.0",
"ext-iconv": "*",
"ext-mbstring": "*",
"ext-curl": "*",
"ext-openssl": "*",
"ext-ctype": "*",
"ext-zip": "*",
"ext-zlib": "*",
"ext-gd": "*",
"ext-simplexml": "*",
"ext-spl": "*",
"ext-pcre": "*",
"ext-dom": "*",
"ext-xml": "*",
"ext-xmlreader": "*",
"ext-intl": "*",
"ext-json": "*",
"ext-hash": "*",
"ext-fileinfo": "*",
"ext-sodium": "*"
```

**Suggested (cho MySQL):**
- mysqli
- pdo_mysql

**Recommended (cho features):**
- exif (image rotation)
- soap (web services)
- xmlrpc (web services)
- ldap (LDAP authentication)
- opcache (performance)

Tất cả đã được cài đặt trong Dockerfile.

## MySQL Configuration (theo Installation Quick Guide)

Database được tạo với đúng charset và collation:
```sql
CREATE DATABASE moodle 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
```

User được tạo với đủ permissions:
```sql
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER 
ON moodle.* 
TO 'moodleuser'@'%' 
IDENTIFIED BY 'moodlepassword';
```

MySQL được cấu hình optimize cho Moodle:
```
--character-set-server=utf8mb4
--collation-server=utf8mb4_unicode_ci
--innodb-file-per-table=1
--max-allowed-packet=512M
--innodb-buffer-pool-size=512M
--sql-mode=NO_ENGINE_SUBSTITUTION
--default-storage-engine=InnoDB
```

## CLI Commands Reference

### Moodle CLI Tools

```bash
# Install Moodle
docker exec -it moodle_app php /var/www/html/public/admin/cli/install.php --help

# Upgrade Moodle
docker exec -it moodle_app php /var/www/html/public/admin/cli/upgrade.php --non-interactive

# Run cron manually
docker exec -it moodle_app php /var/www/html/public/admin/cli/cron.php

# Purge caches
docker exec -it moodle_app php /var/www/html/public/admin/cli/purge_caches.php

# Backup
docker exec -it moodle_app php /var/www/html/public/admin/cli/backup.php --help

# Restore
docker exec -it moodle_app php /var/www/html/public/admin/cli/restore_backup.php --help

# Maintenance mode ON
docker exec -it moodle_app php /var/www/html/public/admin/cli/maintenance.php --enable

# Maintenance mode OFF
docker exec -it moodle_app php /var/www/html/public/admin/cli/maintenance.php --disable

# Create user
docker exec -it moodle_app php /var/www/html/public/admin/cli/user.php --help

# Reset password
docker exec -it moodle_app php /var/www/html/public/admin/cli/reset_password.php
```

### Docker Commands

```bash
# View logs (real-time)
docker-compose logs -f moodle

# View logs (last 100 lines)
docker-compose logs --tail=100 moodle

# Shell into container
docker exec -it moodle_app bash

# Check container status
docker-compose ps

# Restart services
docker-compose restart

# Stop services
docker-compose stop

# Start services
docker-compose start

# Remove containers (keep data)
docker-compose down

# Remove everything including volumes (DATA LOSS!)
docker-compose down -v

# Rebuild and restart
docker-compose up -d --build --force-recreate

# View resource usage
docker stats moodle_app

# View container info
docker inspect moodle_app
```

## Environment Variables Reference

### Database Variables
| Variable | Default | Description |
|----------|---------|-------------|
| MYSQL_ROOT_PASSWORD | rootpassword | MySQL root password |
| MYSQL_DATABASE | moodle | Database name |
| MYSQL_USER | moodleuser | Database user |
| MYSQL_PASSWORD | moodlepassword | Database password |
| MOODLE_DATABASE_TYPE | mysqli | Database driver |
| MOODLE_DATABASE_HOST | mysql | Database host |
| MOODLE_DATABASE_PORT | 3306 | Database port |
| MOODLE_DATABASE_PREFIX | mdl_ | Table prefix |

### Site Variables
| Variable | Default | Description |
|----------|---------|-------------|
| MOODLE_WWWROOT | http://localhost:9000 | Site URL |
| MOODLE_SITE_FULLNAME | Moodle Site | Full site name |
| MOODLE_SITE_SHORTNAME | Moodle | Short site name |
| MOODLE_SITE_SUMMARY | Moodle LMS | Site summary |

### Admin Variables
| Variable | Default | Description |
|----------|---------|-------------|
| MOODLE_ADMIN_USER | admin | Admin username |
| MOODLE_ADMIN_PASSWORD | Admin@123 | Admin password |
| MOODLE_ADMIN_EMAIL | admin@example.com | Admin email |

### PHP Variables
| Variable | Default | Description |
|----------|---------|-------------|
| PHP_MEMORY_LIMIT | 512M | PHP memory limit |
| PHP_MAX_EXECUTION_TIME | 300 | Max execution time |

## Best Practices

### Development
- ✅ Use bind mount để live code editing
- ✅ Use MailHog cho email testing
- ✅ Enable phpMyAdmin
- ✅ Keep default ports (9000, 9001, 9002, 9003)
- ✅ Use `.env` với default passwords

### Production
- ✅ **KHÔNG** mount source code (use volumes only)
- ✅ Use strong passwords trong `.env.production`
- ✅ Enable HTTPS với Let's Encrypt
- ✅ Disable phpMyAdmin và MailHog
- ✅ Configure real SMTP server
- ✅ Set proper `MOODLE_WWWROOT` với domain thật
- ✅ Enable opcache và performance tuning
- ✅ Regular backups (database + moodledata)
- ✅ Monitor logs: `docker-compose logs -f`
- ✅ Set resource limits trong docker-compose.yml
- ✅ Use Docker secrets cho sensitive data

### Security
- ✅ Code permissions: root:www-data, not writable
- ✅ Data permissions: www-data:www-data, writable
- ✅ Use latest stable Moodle version
- ✅ Keep Docker images updated
- ✅ Don't expose MySQL port (9001) in production
- ✅ Use firewalls và security groups
- ✅ Regular security updates: `docker-compose pull && docker-compose up -d`

## Tham khảo

- [Moodle Documentation](https://docs.moodle.org/)
- [Moodle Installation Guide](https://docs.moodle.org/en/Installing_Moodle)
- [PHP Requirements](https://docs.moodle.org/en/PHP)
- [MySQL Configuration](https://docs.moodle.org/en/MySQL)
