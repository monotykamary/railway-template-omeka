#!/bin/bash
set -euo pipefail
: "${OMEKA_DB_HOST:?OMEKA_DB_HOST is required}" "${OMEKA_DB_PASSWORD:?OMEKA_DB_PASSWORD is required}" "${OMEKA_ADMIN_PASSWORD:?OMEKA_ADMIN_PASSWORD is required}" "${OMEKA_BASE_URL:?OMEKA_BASE_URL is required}"
if [ ! -e /var/www/html/files/.htaccess ]; then cp -a /opt/omeka-files/. /var/www/html/files/; fi
chown -R www-data:www-data /var/www/html/files
cat >/var/www/html/db.ini <<EOF
[database]
host = "${OMEKA_DB_HOST}"
port = "${OMEKA_DB_PORT:-3306}"
username = "${OMEKA_DB_USER:-omeka}"
password = "${OMEKA_DB_PASSWORD}"
dbname = "${OMEKA_DB_NAME:-omeka}"
prefix = "omeka_"
charset = "utf8mb4"
EOF
chown www-data:www-data /var/www/html/db.ini
sed -ri 's/Listen 80/Listen 8000/' /etc/apache2/ports.conf
sed -ri 's/:80>/:8000>/' /etc/apache2/sites-available/000-default.conf
rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf /etc/apache2/mods-enabled/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.conf
a2enmod mpm_prefork >/dev/null
apache2-foreground &
app=$!
trap 'kill -TERM "$app" 2>/dev/null || true; wait "$app"' TERM INT
for i in $(seq 1 120); do curl -fsS http://127.0.0.1:8000/install/ >/dev/null 2>&1 && break; sleep 2; done
if curl -fsSL http://127.0.0.1:8000/install/ | grep -q 'Configure Your Site'; then
  curl -fsS -c /tmp/omeka.cookies http://127.0.0.1:8000/install/ -o /tmp/omeka-install.html
  token=$(sed -n 's/.*name="csrf_token"[^>]*value="\([^"]*\)".*/\1/p' /tmp/omeka-install.html | head -1)
  curl -fsS -b /tmp/omeka.cookies -c /tmp/omeka.cookies -X POST http://127.0.0.1:8000/install/ \
    --data-urlencode "csrf_token=$token" --data-urlencode 'username=admin' \
    --data-urlencode "password=$OMEKA_ADMIN_PASSWORD" --data-urlencode "password_confirm=$OMEKA_ADMIN_PASSWORD" \
    --data-urlencode "super_email=${OMEKA_ADMIN_EMAIL:-admin@example.com}" --data-urlencode "site_title=${OMEKA_SITE_TITLE:-Omeka on Railway}" \
    --data-urlencode 'description=Digital collections on Railway' --data-urlencode "administrator_email=${OMEKA_ADMIN_EMAIL:-admin@example.com}" \
    --data-urlencode 'tag_delimiter=,' --data-urlencode 'fullsize_constraint=800' --data-urlencode 'thumbnail_constraint=200' \
    --data-urlencode 'square_thumbnail_constraint=200' --data-urlencode 'per_page_admin=10' --data-urlencode 'per_page_public=10' \
    --data-urlencode 'install_submit=Install' -o /tmp/omeka-result.html
  grep -q 'Omeka is installed' /tmp/omeka-result.html || { cat /tmp/omeka-result.html >&2; exit 1; }
fi
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
proxy=$!
wait -n "$app" "$proxy"
status=$?
kill -TERM "$app" "$proxy" 2>/dev/null || true
wait || true
exit "$status"
