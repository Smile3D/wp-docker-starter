#!/bin/bash
set -e

# ==========================================================
# Заготовка деплоя. Заполни .env.deploy перед первым запуском.
# Использование: ./deploy.sh
# ==========================================================

if [ ! -f .env.deploy ]; then
  echo "✗ Не найден .env.deploy. Скопируй .env.deploy.example и заполни данными хостинга."
  exit 1
fi

set -a
source .env.deploy
source .env
set +a

# REMOTE_USER, REMOTE_HOST, REMOTE_PATH, REMOTE_URL — берутся из .env.deploy
# THEME_NAME, WORDPRESS_PORT — берутся из .env

LOCAL_URL="http://localhost:${WORDPRESS_PORT}"

echo "→ Экспорт БД из контейнера..."
docker compose exec -T wpcli wp --path=/var/www/html db export /tmp/dump.sql
docker cp "$(docker compose ps -q wpcli)":/tmp/dump.sql ./dump.sql

echo "→ Синхронизация файлов темы ($THEME_NAME)..."
rsync -avz --delete \
  --exclude='.git' --exclude='node_modules' \
  "./wp-content/themes/${THEME_NAME}/" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/wp-content/themes/${THEME_NAME}/"

# Раскомментируй, если есть кастомные плагины:
# rsync -avz --delete \
#   "./wp-content/plugins/my-custom-plugin/" \
#   "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/wp-content/plugins/my-custom-plugin/"

echo "→ Загрузка дампа на сервер..."
scp ./dump.sql "${REMOTE_USER}@${REMOTE_HOST}:/tmp/dump.sql"

echo "→ Импорт БД и замена URL на сервере..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_PATH} && \
  wp db import /tmp/dump.sql && \
  wp search-replace '${LOCAL_URL}' '${REMOTE_URL}' --skip-columns=guid && \
  wp theme activate ${THEME_NAME} && \
  wp option update blog_public 1 && \
  wp cache flush && \
  rm /tmp/dump.sql"

rm ./dump.sql
echo "✓ Деплой завершён: ${REMOTE_URL}"
