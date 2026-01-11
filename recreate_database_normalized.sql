-- ============================================================================
-- ПОЛНЫЙ СКРИПТ ПЕРЕСОЗДАНИЯ БАЗЫ ДАННЫХ С НОРМАЛИЗОВАННОЙ СТРУКТУРОЙ
-- ============================================================================
-- Этот скрипт полностью пересоздает базу данных с новой нормализованной структурой
-- Использование: psql -U postgres -d debate_club -f recreate_database_normalized.sql
-- ============================================================================

-- Подключение к базе данных
\c debate_club;

-- ============================================================================
-- УДАЛЕНИЕ СТАРЫХ ОБЪЕКТОВ (если есть)
-- ============================================================================

-- Отключение всех зависимостей
SET session_replication_role = 'replica';

-- Удаление старых таблиц (в порядке зависимостей)
DROP TABLE IF EXISTS participant_audit CASCADE;
DROP TABLE IF EXISTS performances CASCADE;
DROP TABLE IF EXISTS rounds CASCADE;
DROP TABLE IF EXISTS tournaments CASCADE;
DROP TABLE IF EXISTS seasons CASCADE;
DROP TABLE IF EXISTS topics CASCADE;
DROP TABLE IF EXISTS participants CASCADE;
DROP TABLE IF EXISTS judges CASCADE;
DROP TABLE IF EXISTS tournament_statuses CASCADE;
DROP TABLE IF EXISTS debate_positions CASCADE;

-- Удаление старых таблиц с кириллическими именами (если существуют)
DROP TABLE IF EXISTS выступления CASCADE;
DROP TABLE IF EXISTS раунды CASCADE;
DROP TABLE IF EXISTS турниры CASCADE;
DROP TABLE IF EXISTS сезоны CASCADE;
DROP TABLE IF EXISTS темы CASCADE;
DROP TABLE IF EXISTS участники CASCADE;
DROP TABLE IF EXISTS жюри CASCADE;
DROP TABLE IF EXISTS аудит_участников CASCADE;
DROP TABLE IF EXISTS participants_audit CASCADE;

-- Удаление функций
DROP FUNCTION IF EXISTS calculate_total_score(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS расчет_итогового_балла(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_all_tournament_statuses() CASCADE;
DROP FUNCTION IF EXISTS обновить_все_статусы_турниров() CASCADE;
DROP FUNCTION IF EXISTS update_tournament_status() CASCADE;
DROP FUNCTION IF EXISTS validate_performance_scores() CASCADE;
DROP FUNCTION IF EXISTS validate_round_number() CASCADE;
DROP FUNCTION IF EXISTS set_created_at() CASCADE;
DROP FUNCTION IF EXISTS log_participant_changes() CASCADE;

-- Включение зависимостей обратно
SET session_replication_role = 'origin';

-- ============================================================================
-- СОЗДАНИЕ НОВОЙ СТРУКТУРЫ (из schema_normalized.sql)
-- ============================================================================

\i schema_normalized.sql

-- ============================================================================
-- ЗАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ
-- ============================================================================

\i seed_normalized.sql

-- Проверка успешного создания
SELECT 'База данных успешно пересоздана!' as status;
SELECT 
    (SELECT COUNT(*) FROM participants) as participants,
    (SELECT COUNT(*) FROM judges) as judges,
    (SELECT COUNT(*) FROM topics) as topics,
    (SELECT COUNT(*) FROM seasons) as seasons,
    (SELECT COUNT(*) FROM tournaments) as tournaments,
    (SELECT COUNT(*) FROM rounds) as rounds,
    (SELECT COUNT(*) FROM performances) as performances,
    (SELECT COUNT(*) FROM tournament_statuses) as statuses,
    (SELECT COUNT(*) FROM debate_positions) as positions;

