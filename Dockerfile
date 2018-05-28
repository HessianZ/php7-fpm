FROM php:7.1-fpm

RUN apt-get update && apt-get install -y \
        wget \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt pdo_mysql zip bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) mysqli \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && echo "date.timezone=PRC" > /usr/local/etc/php/conf.d/timezone.ini \
    && echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini

VOLUME /www
WORKDIR /www
