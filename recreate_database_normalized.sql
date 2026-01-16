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
DROP TABLE IF EXISTS регистрации_на_турнир CASCADE;
DROP TABLE IF EXISTS раунды CASCADE;
DROP TABLE IF EXISTS турниры CASCADE;
DROP TABLE IF EXISTS сезоны CASCADE;
DROP TABLE IF EXISTS темы CASCADE;
DROP TABLE IF EXISTS участники CASCADE;
DROP TABLE IF EXISTS жюри CASCADE;
DROP TABLE IF EXISTS аудит_участников CASCADE;
DROP TABLE IF EXISTS participants_audit CASCADE;
DROP TABLE IF EXISTS статусы_турниров CASCADE;
DROP TABLE IF EXISTS позиции_дебатов CASCADE;

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
-- Удаление новых функций для регистрации и перераспределения
DROP FUNCTION IF EXISTS перераспределить_участников_турнира(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS проверить_и_перенести_турнир(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS обработать_турниры_в_день_начала() CASCADE;
DROP FUNCTION IF EXISTS триггер_проверить_турнир_при_изменении_даты() CASCADE;
DROP FUNCTION IF EXISTS триггер_проверить_турнир_при_регистрации() CASCADE;
DROP FUNCTION IF EXISTS обновить_статус_турнира() CASCADE;
DROP FUNCTION IF EXISTS валидировать_оценки_выступления() CASCADE;
DROP FUNCTION IF EXISTS валидировать_номер_раунда() CASCADE;

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
SELECT 'База данных успешно пересоздана!' as статус;
SELECT 
    (SELECT COUNT(*) FROM участники) as участники,
    (SELECT COUNT(*) FROM жюри) as жюри,
    (SELECT COUNT(*) FROM темы) as темы,
    (SELECT COUNT(*) FROM сезоны) as сезоны,
    (SELECT COUNT(*) FROM турниры) as турниры,
    (SELECT COUNT(*) FROM раунды) as раунды,
    (SELECT COUNT(*) FROM выступления) as выступления,
    (SELECT COUNT(*) FROM статусы_турниров) as статусы,
    (SELECT COUNT(*) FROM позиции_дебатов) as позиции,
    (SELECT COUNT(*) FROM регистрации_на_турнир) as регистрации;

