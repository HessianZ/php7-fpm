FROM php:7.4.30-fpm-bullseye

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
COPY sources-huawei.list /etc/apt/sources.list

# $PHPIZE_DEPS Contains in php base image
# Remove xfs user and group (gid:33 uid:33)
# Change Alpine default www uid/gid from 82 to 1000
# Date default time zone set as PRC
# Set maximum memory limit to 512MB
# XHProf 比较讨厌，tgz里面还有一层extension目录，会导致无法直接用docker-php-ext-install 安装
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        coreutils \
        libfreetype-dev \
        libjpeg-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libwebp-dev \
        libpcre2-dev \
        libzip-dev \
        tzdata \
        libssl-dev \
    && cp /usr/share/zoneinfo/PRC /etc/localtime \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j "$(nproc)" gd iconv pdo_mysql zip bcmath opcache mysqli sockets pcntl \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/redis-5.3.2.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/mongodb-1.8.2.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/psr-1.2.0.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/phalcon-4.1.2.tgz \
    && pecl bundle -d /usr/src/php/ext /tmp/ext/mcrypt-1.0.3.tgz \
    && docker-php-ext-install -j "$(nproc)" redis mongodb psr phalcon mcrypt \
    && pecl install /tmp/ext/xhprof-2.2.0.tgz \
    && rm -rf /tmp/*.tgz; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

RUN set -eux; \
    apt-get install -y --no-install-recommends libzip4 libpng16-16 libjpeg62-turbo libwebp6 libfreetype6 libmcrypt4 \
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
    && echo 'access.format = "%R - %u %t \"%m %{REQUEST_URI}e\" %s %f %{mili}d %{kilo}M %C%%"' >> php-fpm.d/docker.conf; \
    \
    chown ${PHP_WWW_DATA_UID}:${PHP_WWW_DATA_GID} -R /var/www

VOLUME /data
WORKDIR /data
