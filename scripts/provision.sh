#!/bin/bash
set -e

THEME_NAME="${1:-my-theme}"
WP="wp --path=/var/www/html"

echo "  → Плагины..."
$WP plugin install advanced-custom-fields safe-svg wp-mail-smtp redirection --activate

# Query Monitor только на dev-окружении
$WP plugin install query-monitor --activate

echo "  → Удаление дефолтного мусора..."
$WP post delete 1 --force || true   # Hello World
$WP post delete 2 --force || true   # Sample Page
$WP comment delete 1 --force || true

$WP theme delete twentytwentythree twentytwentytwo --force || true
$WP plugin delete akismet hello --force || true

echo "  → Активация темы: $THEME_NAME"
$WP theme activate "$THEME_NAME"

echo "  → Постоянные ссылки..."
$WP rewrite structure '/%postname%/'
$WP rewrite flush

echo "  → Локаль и время..."
$WP option update timezone_string 'Europe/Kyiv'
$WP option update date_format 'd.m.Y'
$WP option update time_format 'H:i'

echo "  → Медиа..."
$WP option update thumbnail_size_w 0
$WP option update thumbnail_size_h 0
$WP option update medium_size_w 768
$WP option update large_size_w 1200

echo "  → Комментарии выключены по умолчанию..."
$WP option update default_comment_status closed
$WP option update default_ping_status closed

echo "  → Запрет индексации (dev/staging)..."
$WP option update blog_public 0

echo "  → Генерация уникальных SALT-ключей..."
$WP config shuffle-salts

echo "  → Провижининг завершён."
