FROM nginx:stable-alpine

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

ENV USER=root
ENV GROUP=root

RUN if [ $(id -u) -ne 0 ]; then \
        export USER=laravel; \
        export GROUP=laravel; \
        delgroup dialout; \
        addgroup -g ${GID} --system laravel; \
        adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel; \
    else \
        export USER=root; \
        export GROUP=root; \
    fi

RUN sed -i "s/user  nginx/user laravel/g" /etc/nginx/nginx.conf

ADD ./nginx/default.conf /etc/nginx/conf.d/

RUN mkdir -p /var/www/html