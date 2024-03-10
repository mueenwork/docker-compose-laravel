# Used Staging and Production Server
# JIT should be enabled to get performance and XDebug should not be installed at the same time
FROM php:8.2-alpine as php

ARG UID=1000
ARG GID=1000

ENV UID=${UID}
ENV GID=${GID}

ENV USER=root
ENV GROUP=root

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
COPY ./php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Copy configuration files.
# COPY ./dockerfiles/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
# COPY ./dockerfiles/nginx/default.conf /etc/nginx/nginx.conf

# Install Xdebug
# COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
# RUN install-php-extensions xdebug

RUN mkdir -p /var/www/html

# Set working directory to /var/www/html.
WORKDIR /var/www/html

# RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf;

# Copy files from current folder to container current folder (set in workdir).
# COPY --chown=laravel:laravel . .
# Switch user based on whether the current user is root or laravel & Change ownership of container current folder (set in workdir).
RUN if [ $(id -u) -ne 0 ]; then \
        export USER=laravel; \
        export GROUP=laravel; \
        delgroup dialout; \
        addgroup -g ${GID} --system laravel; \
        adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel; \
        # sed -i "s/user = www-data/user = laravel/g" /usr/local/etc/php-fpm.d/www.conf; \
        # sed -i "s/group = www-data/group = laravel/g" /usr/local/etc/php-fpm.d/www.conf; \
        chown -R "$USER:$GROUP" . . ;\
    else \
        export USER=root; \
        export GROUP=root; \
        chown -R "$USER:$GROUP" . . ; \
        # sed -i "s/user = www-data/user = root/g" /usr/local/etc/php-fpm.d/www.conf; \
        # sed -i "s/group = www-data/group = root/g" /usr/local/etc/php-fpm.d/www.conf; \
    fi

# Create laravel caching folders.
RUN mkdir -p /var/www/html/storage/framework /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/testing /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views 

RUN mkdir -p /var/www/html/storage /var/www/html/storage/logs /var/www/html/storage/framework \
    /var/www/html/storage/framework/sessions /var/www/bootstrap

# Fix files ownership.
RUN chown -R $USER /var/www/html/storage
RUN chown -R $USER /var/www/html/storage/framework
RUN chown -R $USER /var/www/html/storage/framework/sessions

# Set correct permission.
RUN chmod -R 775 /var/www/html/storage
RUN chmod -R 775 /var/www/html/storage/logs
RUN chmod -R 755 /var/www/html/storage/framework
RUN chmod -R 755 /var/www/html/storage/framework/sessions
RUN chmod -R 755 /var/www/bootstrap

# # Adjust user permission & group- UID can be useful for ensuring consistency across different systems or for assigning specific permissions based on the UID
# RUN usermod --uid 1000 laravel
# RUN groupmod --gid 1001 laravel

# Set the final user
# USER $user

# Create the target directory if it doesn't exist
RUN mkdir -p /dockerfiles/bash

# Copy the entrypoint script to the target directory
COPY ./dockerfiles/bash/entrypoint.prod.sh /dockerfiles/bash/entrypoint.prod.sh

# Set executable permissions on the entrypoint script
RUN chmod +x /dockerfiles/bash/entrypoint.prod.sh

# Copy the entrypoint script to the root directory
COPY ./dockerfiles/bash/entrypoint.prod.sh /entrypoint.prod.sh
ENTRYPOINT [ "/entrypoint.prod.sh" ]