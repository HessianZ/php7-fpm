FROM registry.cn-beijing.aliyuncs.com/hessian/php7-fpm:7.4

COPY wkhtmltox_0.12.6.1-2.bullseye_amd64.deb /tmp

RUN apt-get update \
    && apt-get install -y fontconfig libx11-6 libxcb1 libxext6 libxrender1 xfonts-encodings xfonts-utils xfonts-base xfonts-75dpi \ 
    && dpkg -i /tmp/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb \
    && rm -f /tmp/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb
