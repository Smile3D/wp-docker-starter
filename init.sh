#!/bin/bash
set -e

# Использование: ./init.sh my-new-theme
THEME_NAME_ARG="${1:-my-theme}"

echo "→ Стартуем проект с темой: $THEME_NAME_ARG"

# --- 1. Подготовка .env ---
if [ ! -f .env ]; then
  cp .env.example .env
  echo "→ Создан .env из .env.example"
fi

sed -i.bak "s/^THEME_NAME=.*/THEME_NAME=$THEME_NAME_ARG/" .env && rm -f .env.bak

set -a
source .env
set +a

# --- 2. Копируем шаблон темы под новым именем (из theme-template, не из wp-content!) ---
THEME_PATH="wp-content/themes/$THEME_NAME_ARG"
if [ ! -d "$THEME_PATH" ]; then
  cp -r theme-template "$THEME_PATH"
  # Переименовываем Theme Name внутри style.css, чтобы в админке было видно свежее имя
  sed -i.bak "s/Theme Name: Starter Theme/Theme Name: ${THEME_NAME_ARG}/" "$THEME_PATH/style.css" && rm -f "$THEME_PATH/style.css.bak"
  echo "→ Тема скопирована в $THEME_PATH"
else
  echo "→ Папка темы $THEME_PATH уже существует, пропускаем копирование"
fi

# --- 3. Поднимаем контейнеры ---
echo "→ Запуск Docker..."
docker compose up -d

# --- 4. Ждём готовности БД ---
echo "→ Ожидание готовности БД..."
until docker compose exec -T db mysqladmin ping -h "localhost" --silent; do
  sleep 2
done

# --- 5. Ждём, пока контейнер wordpress распакует ядро в volume wp_core ---
echo "→ Ожидание готовности ядра WordPress..."
until docker compose exec -T wpcli test -f /var/www/html/wp-load.php 2>/dev/null; do
  sleep 2
done

# --- 6. Устанавливаем WordPress, затем докачиваем и переключаем русскую локаль ---
if ! docker compose exec -T wpcli wp core is-installed --path=/var/www/html 2>/dev/null; then
  echo "→ Установка WordPress..."
  docker compose exec -T wpcli wp core install \
    --path=/var/www/html \
    --url="http://localhost:${WORDPRESS_PORT}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email

  echo "→ Установка локали (${WP_LOCALE})..."
  docker compose exec -T wpcli wp core language install "${WP_LOCALE}" --path=/var/www/html
  docker compose exec -T wpcli wp site switch-language "${WP_LOCALE}" --path=/var/www/html
else
  echo "→ WordPress уже установлен, пропускаем core install"
fi

# --- 7. Провижининг: плагины, настройки, чистка ---
echo "→ Провижининг..."
docker compose exec -T wpcli bash /scripts/provision.sh "$THEME_NAME_ARG"

# --- 8. Установка npm-зависимостей темы (Gulp/SCSS) ---
if [ -f "$THEME_PATH/package.json" ]; then
  if command -v npm >/dev/null 2>&1; then
    echo "→ Установка npm-зависимостей темы..."
    (cd "$THEME_PATH" && npm install)
  else
    echo "⚠ npm не найден в системе — пропускаю установку зависимостей темы."
    echo "  Поставь Node.js (https://nodejs.org) и выполни вручную:"
    echo "  cd $THEME_PATH && npm install"
  fi
fi

echo ""
echo "✓ Готово!"
echo "  Сайт:       http://localhost:${WORDPRESS_PORT}"
echo "  Админка:    http://localhost:${WORDPRESS_PORT}/wp-admin  (${WP_ADMIN_USER} / ${WP_ADMIN_PASSWORD})"
echo "  phpMyAdmin: http://localhost:${PHPMYADMIN_PORT}"
echo ""
echo "  Для сборки стилей темы:"
echo "  cd $THEME_PATH && npm run dev"