FROM registry.cn-beijing.aliyuncs.com/hessian/php7-fpm:7.3-doxue

COPY ext/scws-1.2.3.tar.bz2 /tmp/ext

RUN set -x \
 && apk add --no-cache --virtual /tmp/.build-deps $PHPIZE_DEPS tidyhtml-dev \
    && cd /tmp/ext && tar xjvf scws-1.2.3.tar.bz2 \
    && cd scws-1.2.3 && ./configure && make install \
    && cd phpext && phpize && ./configure --with-scws=/usr/local --with-php-config=$(which php-config) && make && make install \
    && echo "scws.default.charset = utf-8" > /usr/local/etc/php/conf.d/scws.ini \
    && echo "scws.default.fpath = /usr/local/etc/" >> /usr/local/etc/php/conf.d/scws.ini \
    && docker-php-ext-enable scws \
    && apk add tidyhtml-libs && docker-php-ext-install tidy \
	&& apk del /tmp/.build-deps \
    && rm -rf /tmp/*

VOLUME /data/www
WORKDIR /data/www
