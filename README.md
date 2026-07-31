# WordPress Docker Starter Kit

Стартер-кит для быстрого старта новых WP-проектов. Одна команда — и готово
рабочее окружение с настроенным WordPress, нужными плагинами и чистой темой.

## Структура

```
wp-docker-starter/
├── docker-compose.yml       # WordPress + MariaDB + phpMyAdmin + WP-CLI
├── .env.example              # шаблон переменных окружения (порты, БД, тема)
├── .env.deploy.example       # шаблон данных хостинга для деплоя
├── init.sh                   # старт нового проекта одной командой
├── deploy.sh                 # выгрузка на хостинг с WP-CLI
├── scripts/
│   └── provision.sh          # плагины, чистка, настройки WP через WP-CLI
└── wp-content/
    └── themes/
        └── _starter-theme/   # шаблон темы, копируется под новым именем
```

## Быстрый старт нового проекта

```bash
git clone <этот репозиторий> my-new-project
cd my-new-project
./init.sh my-theme-name
```

Скрипт сам:
1. создаст `.env` из `.env.example`
2. скопирует `_starter-theme` в `wp-content/themes/my-theme-name`
3. поднимет Docker (`WordPress`, `MariaDB`, `phpMyAdmin`, `WP-CLI`)
4. установит WordPress
5. поставит плагины и применит настройки (`scripts/provision.sh`)

После этого:

- Сайт: `http://localhost:8080`
- Админка: `http://localhost:8080/wp-admin`
- phpMyAdmin: `http://localhost:8081`

Порты и логин/пароль админа берутся из `.env` — поменяй их там при
необходимости (например, если несколько проектов крутятся локально
одновременно).

## Что уже настроено из коробки

**Плагины:** Advanced Custom Fields, Safe SVG, WP Mail SMTP, Redirection,
Query Monitor (только dev).

**Настройки:** ЧПУ (`/%postname%/`), часовой пояс, форматы даты, отключены
комментарии по умолчанию, запрет индексации поисковиками, уникальные SALT-
ключи, `DISALLOW_FILE_EDIT`, удалены дефолтные посты/темы/плагины WP.

Список плагинов и настроек редактируется в `scripts/provision.sh` — это
единственное место, где нужно что-то менять, если стартер нужно доработать.

## Деплой на хостинг

Требования: SSH-доступ и WP-CLI на хостинге.

```bash
cp .env.deploy.example .env.deploy
# заполни REMOTE_USER / REMOTE_HOST / REMOTE_PATH / REMOTE_URL
./deploy.sh
```

Скрипт экспортирует БД из контейнера, синхронизирует файлы темы через
`rsync`, заливает дамп и на сервере делает `wp db import` +
`wp search-replace` (замена локального URL на боевой) + активацию темы.

**Важно:**
- `wp-config.php` на хостинге не трогается деплоем — он остаётся со своими
  данными подключения к БД.
- Первый деплой на новый хостинг требует ручного шага: создать БД и
  настроить `wp-config.php` (или через панель хостинга).
- `.env.deploy` не должен попадать в git (уже в `.gitignore`).

## Полезные команды

```bash
docker compose up -d              # поднять стек
docker compose down                # остановить (данные БД сохраняются)
docker compose down -v             # остановить и стереть БД (чистый старт)
docker compose exec wpcli wp ...   # любая WP-CLI команда внутри контейнера
docker compose logs -f wordpress   # логи WordPress
```
