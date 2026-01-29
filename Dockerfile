FROM php:8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
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
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Moodle (based on composer.json)
RUN docker-php-ext-configure intl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
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
    opcache

# Note: The following extensions are built-in and enabled by default:
# iconv, curl, openssl, ctype, zlib, simplexml, spl, pcre, xml, xmlreader, json, hash, fileinfo

# Enable Apache modules
RUN a2enmod rewrite
RUN a2enmod ssl

# Set recommended PHP.ini settings for Moodle
RUN { \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'memory_limit = 512M'; \
    echo 'post_max_size = 512M'; \
    echo 'upload_max_filesize = 512M'; \
    echo 'max_input_vars = 5000'; \
    echo 'session.save_handler = files'; \
    echo 'session.save_path = "/tmp"'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.max_accelerated_files = 10000'; \
    echo 'opcache.revalidate_freq = 60'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# Set working directory
WORKDIR /var/www/html

# Copy Moodle files
COPY . /var/www/html/

# Create moodledata directory and set permissions
RUN mkdir -p /var/www/moodledata && \
    chown -R www-data:www-data /var/www && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /var/www/moodledata && \
    chmod -R 777 /var/www/moodledata && \
    chmod -R 755 /var/www/html

# Configure Apache DocumentRoot
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
