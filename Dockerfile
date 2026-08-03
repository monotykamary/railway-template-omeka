FROM docker.io/library/php:8.3.33-apache-bookworm@sha256:8d61f31653ce5550d10d012dce005ecfc24cbdbe7108d19f35242fb0ecb2ff22 AS build
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libicu-dev libjpeg62-turbo-dev libpng-dev libfreetype6-dev libzip-dev && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j2 mysqli intl gd zip exif
RUN curl -fsSL https://github.com/omeka/Omeka/releases/download/v3.2.1/omeka-3.2.1.zip -o /tmp/omeka.zip \
 && echo '2cb4d65511321cc5c009cb61516d9ed97378a800fc4a26eb46450c3c4ca230c2  /tmp/omeka.zip' | sha256sum -c - \
 && unzip -q /tmp/omeka.zip -d /tmp \
 && rm -rf /var/www/html/* && cp -a /tmp/omeka-3.2.1/. /var/www/html/ \
 && cp -a /var/www/html/files /opt/omeka-files \
 && chown -R www-data:www-data /var/www/html
RUN a2enmod rewrite
FROM build
COPY --from=docker.io/library/caddy:2.10.2-alpine@sha256:d8c17a862962def15cde69863a3a463f25a2664942eafd7bdbf050e9c3116b83 /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /usr/local/bin/omeka-railway-entrypoint
RUN chmod +x /usr/local/bin/omeka-railway-entrypoint
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/omeka-railway-entrypoint"]
