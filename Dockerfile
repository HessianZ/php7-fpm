FROM php:7.3-fpm-alpine

# 生产环境配置
ENV PHP_POOL_PM_CONTROL=dynamic \
    PHP_POOL_PM_MAX_CHILDREN=250 \
    PHP_POOL_PM_START_SERVERS=100 \
    PHP_POOL_PM_MIN_SPARE_SERVERS=100 \
    PHP_POOL_PM_MAX_SPARE_SERVERS=250 \
    PHP_CONF_LOG_DIR=/data/logs/php \
    PHP_WWW_DATA_GID=1000 \
    PHP_WWW_DATA_UID=1000

COPY ext/* /tmp/ext/

# $PHPIZE_DEPS Contains in php:7.1-fpm-alpine
# Remove xfs user and group (gid:33 uid:33)
# Change Alpine default www uid/gid from 82 to 33 (CentOS default)
# Date default time zone set as PRC
# Set maximum memory limit to 512MB
# XHProf 比较讨厌，tgz里面还有一层extension目录，会导致无法直接用docker-php-ext-install 安装
RUN set -x \
 && export ALPINE_VERSION=$(sed 's/\.\d\+$//' /etc/alpine-release) \
 && echo "https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories \
 && echo "https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories \
 && apk add --no-cache --virtual /tmp/.build-deps \
        $PHPIZE_DEPS \
        coreutils \
        freetype-dev \
        jpeg-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        pcre-dev \
        libzip-dev \
        openssl-dev \
        tzdata \
    && cp /usr/share/zoneinfo/PRC /etc/localtime \
    && apk add gnu-libiconv --update-cache --repository "https://mirrors.aliyun.com/alpine/edge/testing" --allow-untrusted \
    && docker-php-ext-install -j "$(nproc)" iconv pdo_mysql zip bcmath opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j "$(nproc)" gd \
    && docker-php-ext-install -j "$(nproc)" mysqli \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/redis-5.3.2.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/mongodb-1.8.2.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/psr-1.0.1.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/phalcon-4.1.0.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/mcrypt-1.0.3.tgz \
    && docker-php-ext-install -j "$(nproc)" redis mongodb psr phalcon mcrypt \
    && pecl install /tmp/ext/xhprof-2.2.0.tgz \
    && rm -rf /tmp/*.tgz \
	&& apk del /tmp/.build-deps \
	&& apk del tzdata \
    && apk add --no-cache libzip libpng libjpeg freetype libmcrypt \
    && sed -i "s/:82:82:/:${PHP_WWW_DATA_UID}:${PHP_WWW_DATA_GID}:/g" /etc/passwd \
    && sed -i "s/:82:/:${PHP_WWW_DATA_GID}:/g" /etc/group \
    && cd /usr/local/etc \
    && cp /usr/src/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i "s/short_open_tag = Off/short_open_tag = On/g" /usr/local/etc/php/php.ini \
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

VOLUME /data/www
WORKDIR /data/www
