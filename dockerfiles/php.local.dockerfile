# Used for DEV & Local.
# JIT cannot be enabled if XDebug is installed/enabled. So this env we install xdebug
FROM php:8.2-alpine as php

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

# Set environment variables
# ENV PHP_OPCACHE_ENABLE=1
# ENV PHP_OPCACHE_ENABLE_CLI=0
# ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
# ENV PHP_OPCACHE_REVALIDATE_FREQ=0

# Install dependencies.
# RUN apk update && apk install -y unzip libpq-dev libcurl4-gnutls-dev libonig-dev

# Install PHP extensions.
RUN docker-php-ext-install mysqli pdo_mysql bcmath opcache

# Clean up
# RUN rm -rf /var/cache/apk/*

# Copy composer executable.
COPY --from=composer:2.7.1 /usr/bin/composer /usr/bin/composer

# Copy custom OPcache configuration file, If OPcache with » Xdebug, then load OPcache before Xdebug.
# COPY ./dockerfiles/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Copy configuration files.
# COPY ./dockerfiles/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
# COPY ./dockerfiles/nginx/default.conf /etc/nginx/nginx.conf

# Install Xdebug
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions xdebug

RUN mkdir -p /var/www/html

# Set working directory to /var/www/html.
WORKDIR /var/www/html

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
RUN delgroup dialout

RUN addgroup -g ${GID} --system laravel
RUN adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel

RUN sed -i "s/user = www-data/user = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Copy files from current folder to container current folder (set in workdir).
COPY --chown=laravel:laravel . .

# Create laravel caching folders.
RUN mkdir -p /var/www/html/storage/framework /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/testing /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views

RUN mkdir -p /var/www/html/storage /var/www/html/storage/logs /var/www/html/storage/framework \
    /var/www/html/storage/framework/sessions /var/www/bootstrap

# Fix files ownership.
RUN chown -R laravel /var/www/html/storage
RUN chown -R laravel /var/www/html/storage/framework
RUN chown -R laravel /var/www/html/storage/framework/sessions

# Set correct permission.
RUN chmod -R 775 /var/www/html/storage
RUN chmod -R 775 /var/www/html/storage/logs
RUN chmod -R 755 /var/www/html/storage/framework
RUN chmod -R 755 /var/www/html/storage/framework/sessions
RUN chmod -R 755 /var/www/bootstrap

# # Adjust user permission & group
# RUN usermod --uid 1000 laravel
# RUN groupmod --gid 1001 laravel

USER laravel

# Run the entrypoint file.
ENTRYPOINT [ "./bash/entrypoint.local.sh" ]
