FROM docker.io/library/php:8.5.12-apache-bookworm@sha256:5e4418695f9b13b75edefaff547125bf6be267e865931731bdd5946461505736 AS build
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libicu-dev libjpeg62-turbo-dev libpng-dev libfreetype6-dev libzip-dev && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j2 mysqli intl gd zip exif
RUN curl -fsSL https://github.com/omeka/Omeka/releases/download/v3.2.2/omeka-3.2.2.zip -o /tmp/omeka.zip \
 && echo '9e273649b99fb81ec3b9855d3e168f1b39881760789f409beb9d34f533c3d9c3  /tmp/omeka.zip' | sha256sum -c - \
 && unzip -q /tmp/omeka.zip -d /tmp \
 && rm -rf /var/www/html/* && cp -a /tmp/omeka-3.2.2/. /var/www/html/ \
 && cp -a /var/www/html/files /opt/omeka-files \
 && chown -R www-data:www-data /var/www/html
RUN a2enmod rewrite
FROM build
COPY --from=docker.io/library/caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648 /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /usr/local/bin/omeka-railway-entrypoint
RUN chmod +x /usr/local/bin/omeka-railway-entrypoint
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/omeka-railway-entrypoint"]
