#!/bin/bash

# Скрипт для пересоздания базы данных
# Использование: ./recreate_db.sh

echo "=========================================="
echo "Пересоздание базы данных debate_club"
echo "=========================================="
echo ""

# Параметры подключения (измените при необходимости)
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-debate_club}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

echo "Параметры подключения:"
echo "  Пользователь: $DB_USER"
echo "  База данных: $DB_NAME"
echo "  Хост: $DB_HOST"
echo "  Порт: $DB_PORT"
echo ""

# Проверка существования базы данных
echo "Проверка существования базы данных..."
if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "✓ База данных $DB_NAME существует"
else
    echo "Создание базы данных $DB_NAME..."
    createdb -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME"
    if [ $? -eq 0 ]; then
        echo "✓ База данных создана"
    else
        echo "✗ Ошибка создания базы данных"
        exit 1
    fi
fi

echo ""
echo "Выполнение скрипта пересоздания..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -f recreate_database_normalized.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ База данных успешно пересоздана!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "✗ Ошибка при пересоздании базы данных"
    echo "=========================================="
    exit 1
fi
