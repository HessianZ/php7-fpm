FROM php:7.2-fpm-alpine

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        coreutils \
        freetype-dev \
        jpeg-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        pcre-dev \
    && docker-php-ext-install -j "$(nproc)" iconv pdo_mysql zip bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j "$(nproc)" gd \
    && docker-php-ext-install -j "$(nproc)" mysqli \
    && pecl install channel://pecl.php.net/mcrypt-1.0.1 && docker-php-ext-enable mcrypt \
    && pecl install redis && docker-php-ext-enable redis \
	&& apk del .build-deps \
    && apk add --no-cache libpng libjpeg freetype \
    && echo "date.timezone=PRC" > /usr/local/etc/php/conf.d/timezone.ini \
    && echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini \
    && sed -i s/:82:82:/:33:33:/g /etc/passwd \
    && sed -i s/:82:/:33:/g /etc/group

VOLUME /www
WORKDIR /www