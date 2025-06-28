# Use the official PHP 8.4 image as a base
FROM php:8.4-apache

# Install necessary extensions, Apache mod_rewrite, Composer, PostgreSQL extension, OPcache, and cron
RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip git curl libzip-dev libjpeg-dev libpng-dev \
    libfreetype6-dev libicu-dev libxml2-dev libpq-dev cron && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install mysqli zip gd intl soap exif pgsql pdo_pgsql opcache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    git clone git://git.moodle.org/moodle.git && cd moodle && \
    git branch --track MOODLE_500_STABLE origin/MOODLE_500_STABLE && \
    git checkout MOODLE_500_STABLE && \
    cp -rf ./* /var/www/html/

# Set PHP settings for Moodle: max_input_vars and OPcache
RUN echo "max_input_vars=5000" >> /usr/local/etc/php/conf.d/docker-php-moodle.ini && \
    echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/docker-php-opcache.ini

# Create moodledata directory
RUN mkdir -p /var/www/moodledata

# Set up cron job for Moodle
RUN echo "* * * * * www-data /usr/local/bin/php /var/www/html/admin/cli/cron.php > /dev/null" > /etc/cron.d/moodle-cron && \
    chmod 0644 /etc/cron.d/moodle-cron

# Set working directory
WORKDIR /var/www/html

# Set the correct permissions
RUN chown -R www-data:www-data /var/www/ && chmod -R 755 /var/www

# Copy entrypoint script to start both Apache and cron
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 80
EXPOSE 80

# Use entrypoint to start cron and Apache
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]