FROM php:7.3-fpm-alpine

# 生产环境配置
ENV PHP_POOL_PM_CONTROL=dynamic \
    PHP_POOL_PM_MAX_CHILDREN=200 \
    PHP_POOL_PM_START_SERVERS=1 \
    PHP_POOL_PM_MIN_SPARE_SERVERS=1 \
    PHP_POOL_PM_MAX_SPARE_SERVERS=3 \
    PHP_CONF_LOG_DIR=/www/logs/php

# $PHPIZE_DEPS Contains in php:7.1-fpm-alpine
# Remove xfs user and group (gid:33 uid:33)
# Change Alpine default www uid/gid from 82 to 33 (CentOS default)
# Date default time zone set as PRC
# Set maximum memory limit to 512MB
RUN set -x \
 && export ALPINE_VERSION=$(sed 's/\.\d\+$//' /etc/alpine-release) \
 && echo "https://mirrors.cloud.tencent.com/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories \
 && echo "https://mirrors.cloud.tencent.com/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories \
 && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        coreutils \
        freetype-dev \
        jpeg-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        pcre-dev \
        libzip-dev \
    && apk add gnu-libiconv --update-cache --repository "https://mirrors.cloud.tencent.com/alpine/edge/testing" --allow-untrusted \
    && docker-php-ext-install -j "$(nproc)" iconv pdo_mysql zip bcmath opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j "$(nproc)" gd \
    && docker-php-ext-install -j "$(nproc)" mysqli \
    && pecl install redis && docker-php-ext-enable redis \
    && pecl install "channel://pecl.php.net/mcrypt-1.0.2" && docker-php-ext-enable mcrypt \
	&& apk del .build-deps \
    && apk add --no-cache libzip libpng libjpeg freetype libmcrypt \
    && sed -i /xfs:/d /etc/passwd \
    && sed -i /xfs:/d /etc/group \
    && sed -i s/:82:82:/:33:33:/g /etc/passwd \
    && sed -i s/:82:/:33:/g /etc/group \
    && cd /usr/local/etc \
    && echo "date.timezone=PRC" > php/conf.d/timezone.ini \
    && echo "memory_limit=512M" > php/conf.d/memory.ini \
    && sed -i "s/^pm =.*/pm = $PHP_POOL_PM_CONTROL/" php-fpm.d/www.conf \
    && sed -i "s/^pm.max_children.*/pm.max_children = $PHP_POOL_PM_MAX_CHILDREN/" php-fpm.d/www.conf \
    && sed -i "s/^pm.start_servers.*/pm.start_servers = $PHP_POOL_PM_START_SERVERS/" php-fpm.d/www.conf \
    && sed -i "s/^pm.min_spare_servers.*/pm.min_spare_servers = $PHP_POOL_PM_MIN_SPARE_SERVERS/" php-fpm.d/www.conf \
    && sed -i "s/^pm.max_spare_servers.*/pm.max_spare_servers = $PHP_POOL_PM_MAX_SPARE_SERVERS/" php-fpm.d/www.conf \
    && sed -i "s!^error_log =.*!error_log = $PHP_CONF_LOG_DIR/php.error.log!" php-fpm.d/docker.conf \
    && sed -i "s!^access.log =.*!access.log = $PHP_CONF_LOG_DIR/php.\$pool.access.log!" php-fpm.d/docker.conf \
    && echo 'access.format = "%R - %u %t \"%m %{REQUEST_URI}e\" %s %f %{mili}d %{kilo}M %C%%"' >> php-fpm.d/docker.conf

# Fix iconv compatible between alphine and php
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

VOLUME /www
WORKDIR /www
