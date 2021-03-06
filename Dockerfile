FROM php:5.6-fpm

ENV DEBIAN_FRONTEND noninteractive

ENV NGINX_VERSION 1.9.9-1~jessie

ENV PECL_MONGO_VERSION 1.6.11

ADD thawte_Premium_Server_CA.pem /etc/ssl/certs/thawte_Premium_Server_CA.pem

RUN update-ca-certificates --fresh

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

RUN mkdir -p /data/logs

RUN packages=" \
    libssl-dev \
    libmcrypt-dev \
    libpng12-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libxml2-dev \
    git \
    pdftk \
    ca-certificates \
    nginx=${NGINX_VERSION} \
 " \
 && set -x \
 && DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y $packages --no-install-recommends \
 && curl -SL "http://pecl.php.net/get/mongo-$PECL_MONGO_VERSION.tgz" -o mongo.tar.gz \
 && mkdir -p /usr/src/php/ext/mongo \
 && tar -xzC /usr/src/php/ext/mongo --strip-components=1 -f mongo.tar.gz \
 && rm mongo.tar.gz* \
 && DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install mongo soap iconv mcrypt bcmath mbstring pdo pdo_mysql zip tokenizer gd pcntl opcache

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ENV COMPOSER_VERSION 1.11.1
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -sL https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list

RUN apt-get update; apt-get install -yq wget newrelic-php5 && apt-get clean

WORKDIR /data/www

RUN chgrp -R www-data /data
RUN chmod -R o+w /data
RUN chmod -R 775 /data

ADD rootfs /

CMD ["/init"]