FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libsodium-dev \
    zip \
    unzip \
    cron \
    supervisor \
    gnupg \
    ca-certificates \
    msmtp \
    msmtp-mta \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x (required by package.json: >=22.11.0 <23)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && node --version \
    && npm --version

# Install additional system dependencies for LDAP
RUN apt-get update && apt-get install -y \
    libldap2-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by composer.json
# Required: iconv, mbstring, curl, openssl, ctype, zip, zlib, gd, 
# simplexml, spl, pcre, dom, xml, xmlreader, intl, json, hash, fileinfo, sodium
# Suggested: mysqli (MySQL), exif, soap
# Recommended: ldap (LDAP auth)
# Note: xmlrpc removed from PHP 8.0+, moved to PECL
RUN docker-php-ext-configure intl && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure ldap && \
    docker-php-ext-install -j$(nproc) \
        mbstring \
        zip \
        gd \
        dom \
        intl \
        sodium \
        pdo_mysql \
        mysqli \
        exif \
        soap \
        opcache \
        ldap

# Note: Built-in extensions (already enabled): 
# iconv, curl, openssl, ctype, zlib, simplexml, spl, pcre, 
# xml, xmlreader, json, hash, fileinfo

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Enable Apache modules
RUN a2enmod rewrite && \
    a2enmod ssl && \
    a2enmod headers && \
    a2enmod deflate && \
    a2enmod expires

# Set recommended PHP.ini settings for Moodle
# Based on: https://docs.moodle.org/en/PHP
RUN { \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'memory_limit = 512M'; \
    echo 'post_max_size = 512M'; \
    echo 'upload_max_filesize = 512M'; \
    echo 'max_input_vars = 5000'; \
    echo 'max_input_nesting_level = 256'; \
    echo 'session.save_handler = files'; \
    echo 'session.save_path = "/tmp"'; \
    echo 'session.auto_start = 0'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.max_accelerated_files = 10000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'opcache.save_comments = 1'; \
    echo 'opcache.use_cwd = 1'; \
    echo 'opcache.validate_timestamps = 1'; \
    echo 'date.timezone = "Asia/Ho_Chi_Minh"'; \
    echo 'zend.exception_ignore_args = On'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /var/log/php_errors.log'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# Configure msmtp for mail sending
RUN { \
    echo 'account default'; \
    echo 'host mailhog'; \
    echo 'port 1025'; \
    echo 'from moodle@localhost'; \
    echo 'auth off'; \
    echo 'tls off'; \
    echo 'logfile /var/log/msmtp.log'; \
} > /etc/msmtprc && \
    chmod 644 /etc/msmtprc && \
    touch /var/log/msmtp.log && \
    chown www-data:www-data /var/log/msmtp.log

# Set working directory
WORKDIR /var/www/html

# Copy Moodle files
COPY --chown=www-data:www-data . /var/www/html/

# Install Composer dependencies
RUN cd /var/www/html && \
    composer install --no-dev --classmap-authoritative --no-interaction && \
    chown -R www-data:www-data vendor

# Create moodledata directory outside web root
RUN mkdir -p /var/www/moodledata && \
    chown -R www-data:www-data /var/www/moodledata && \
    chmod -R 0770 /var/www/moodledata

# Set proper permissions for Moodle code
# Code should NOT be writable by web server (security best practice)
RUN find /var/www/html -type f -exec chmod 0644 {} \; && \
    find /var/www/html -type d -exec chmod 0755 {} \; && \
    chown -R root:www-data /var/www/html

# Configure Apache DocumentRoot to point to /public directory
# This is required because composer.json has "haspublicdir": true
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/default-ssl.conf

# Add Apache configuration for Moodle
RUN { \
    echo '<Directory /var/www/html/public>'; \
    echo '    Options -Indexes +FollowSymLinks'; \
    echo '    AllowOverride All'; \
    echo '    Require all granted'; \
    echo '</Directory>'; \
} >> /etc/apache2/sites-available/000-default.conf

# Setup cron for Moodle (runs every minute as per Moodle requirements)
# Correct path: /var/www/html/public/admin/cli/cron.php
RUN echo "* * * * * www-data /usr/local/bin/php /var/www/html/public/admin/cli/cron.php >/dev/null 2>&1" >> /etc/crontab

# Create supervisor configuration for Apache and Cron
RUN { \
    echo '[supervisord]'; \
    echo 'nodaemon=true'; \
    echo 'logfile=/var/log/supervisor/supervisord.log'; \
    echo 'pidfile=/var/run/supervisord.pid'; \
    echo 'user=root'; \
    echo ''; \
    echo '[program:apache2]'; \
    echo 'command=/usr/sbin/apache2ctl -D FOREGROUND'; \
    echo 'autostart=true'; \
    echo 'autorestart=true'; \
    echo 'stdout_logfile=/dev/stdout'; \
    echo 'stdout_logfile_maxbytes=0'; \
    echo 'stderr_logfile=/dev/stderr'; \
    echo 'stderr_logfile_maxbytes=0'; \
    echo 'user=root'; \
    echo ''; \
    echo '[program:cron]'; \
    echo 'command=/usr/sbin/cron -f'; \
    echo 'autostart=true'; \
    echo 'autorestart=true'; \
    echo 'stdout_logfile=/dev/stdout'; \
    echo 'stdout_logfile_maxbytes=0'; \
    echo 'stderr_logfile=/dev/stderr'; \
    echo 'stderr_logfile_maxbytes=0'; \
    echo 'user=root'; \
} > /etc/supervisor/conf.d/supervisord.conf

# Create log directory for supervisor
RUN mkdir -p /var/log/supervisor

# Install MySQL client for healthcheck and entrypoint
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port 80
EXPOSE 80

# Use entrypoint to handle initialization
ENTRYPOINT ["docker-entrypoint.sh"]

# Start supervisor to manage Apache and Cron
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
