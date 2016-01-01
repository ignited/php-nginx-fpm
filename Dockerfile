FROM php:5.6-fpm

ENV NGINX_VERSION 1.9.9-1~jessie

ENV PECL_MONGO_VERSION 1.6.11

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

RUN mkdir -p /data/logs

RUN buildDeps=" \
     libssl-dev \
 " \
 otherDeps=" \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    git \
    pdftk \
    ca-certificates \
    nginx=${NGINX_VERSION} \
 " \
 && set -x \
 && DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $otherDeps  --no-install-recommends \
 && curl -SL "http://pecl.php.net/get/mongo-$PECL_MONGO_VERSION.tgz" -o mongo.tar.gz \
 && mkdir -p /usr/src/php/ext/mongo \
 && tar -xzC /usr/src/php/ext/mongo --strip-components=1 -f mongo.tar.gz \
 && rm mongo.tar.gz* \
 && docker-php-ext-install mongo iconv mcrypt gd \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ADD rootfs /

EXPOSE 80

ENTRYPOINT ["/init"]