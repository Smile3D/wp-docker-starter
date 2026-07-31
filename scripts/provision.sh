#!/bin/bash
set -e

THEME_NAME="${1:-my-theme}"
WP="wp --path=/var/www/html"

echo "  → Плагины из wp.org..."
$WP plugin install safe-svg wp-mail-smtp redirection --activate

# Query Monitor только на dev-окружении
$WP plugin install query-monitor --activate

echo "  → Лицензионные плагины из /licensed-plugins..."
if [ -d /licensed-plugins ]; then
  for zip in /licensed-plugins/*.zip; do
    [ -e "$zip" ] || continue   # если zip'ов нет вообще — пропускаем
    echo "    - установка $(basename "$zip")"
    $WP plugin install "$zip" --activate --force
  done
else
  echo "    (папка /licensed-plugins не смонтирована, пропускаем)"
fi

# Если ACF PRO не установлен (папка пустая) — ставим бесплатный ACF как fallback
if ! $WP plugin is-installed advanced-custom-fields-pro 2>/dev/null; then
  echo "  → ACF PRO не найден, ставлю бесплатный ACF..."
  $WP plugin install advanced-custom-fields --activate
fi

echo "  → Удаление дефолтных тем WordPress..."
$WP theme delete twentytwentyfive twentytwentyfour twentytwentythree twentytwentytwo --force || true

echo "  → Удаление дефолтного мусора..."
$WP post delete 1 --force || true   # Hello World
$WP post delete 2 --force || true   # Sample Page
$WP comment delete 1 --force || true
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

echo "  → Создание статической главной страницы..."
if ! $WP post list --post_type=page --title='Главная' --field=ID --path=/var/www/html | grep -q .; then
  FRONT_PAGE_ID=$($WP post create --post_type=page --post_title='Главная' --post_status=publish --porcelain)
  $WP option update show_on_front 'page'
  $WP option update page_on_front "$FRONT_PAGE_ID"
  echo "    - страница 'Главная' создана и назначена главной (ID: $FRONT_PAGE_ID)"
else
  echo "    - страница 'Главная' уже существует, пропускаем создание"
fi

echo "  → Провижининг завершён."