-- ============================================================================
-- НОРМАЛИЗОВАННАЯ СХЕМА БАЗЫ ДАННЫХ ДЛЯ СИСТЕМЫ УПРАВЛЕНИЯ ДИСКУССИОННЫМ КЛУБОМ
-- ============================================================================
-- Все таблицы и поля с английскими именами
-- Нормализация до BCNF (Boyce-Codd Normal Form)
-- ============================================================================

-- Удаление существующих таблиц (в порядке зависимостей)
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

-- Удаление функций и последовательностей
DROP FUNCTION IF EXISTS calculate_total_score(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_all_tournament_statuses() CASCADE;
DROP SEQUENCE IF EXISTS participants_id_seq CASCADE;
DROP SEQUENCE IF EXISTS judges_id_seq CASCADE;
DROP SEQUENCE IF EXISTS topics_id_seq CASCADE;
DROP SEQUENCE IF EXISTS seasons_id_seq CASCADE;
DROP SEQUENCE IF EXISTS tournaments_id_seq CASCADE;
DROP SEQUENCE IF EXISTS rounds_id_seq CASCADE;
DROP SEQUENCE IF EXISTS performances_id_seq CASCADE;
DROP SEQUENCE IF EXISTS participant_audit_id_seq CASCADE;

-- ============================================================================
-- СПРАВОЧНЫЕ ТАБЛИЦЫ (Reference Tables)
-- ============================================================================

-- Таблица статусов турниров (нормализация - отдельная таблица для статусов)
CREATE TABLE tournament_statuses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE, -- 'upcoming', 'active', 'completed'
    name VARCHAR(100) NOT NULL UNIQUE, -- 'Предстоящий', 'Активный', 'Завершен'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Таблица позиций в дебатах (нормализация - отдельная таблица для позиций)
CREATE TABLE debate_positions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE, -- 'for', 'against'
    name VARCHAR(50) NOT NULL UNIQUE, -- 'За', 'Против'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- ОСНОВНЫЕ ТАБЛИЦЫ (Main Tables)
-- ============================================================================

-- Таблица участников
CREATE TABLE participants (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT participants_email_unique UNIQUE (email)
);

-- Таблица жюри
CREATE TABLE judges (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT judges_email_unique UNIQUE (email)
);

-- Таблица тем дебатов
CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Таблица сезонов
CREATE TABLE seasons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT seasons_dates_valid CHECK (end_date >= start_date)
);

-- Таблица турниров (с внешним ключом на tournament_statuses)
CREATE TABLE tournaments (
    id SERIAL PRIMARY KEY,
    season_id INTEGER NOT NULL REFERENCES seasons(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status_id INTEGER NOT NULL REFERENCES tournament_statuses(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tournaments_dates_valid CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT tournaments_season_fk FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE RESTRICT
);

-- Таблица раундов
CREATE TABLE rounds (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    topic_id INTEGER NOT NULL REFERENCES topics(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    round_number INTEGER NOT NULL,
    round_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT rounds_unique_tournament_number UNIQUE (tournament_id, round_number),
    CONSTRAINT rounds_number_positive CHECK (round_number > 0)
);

-- Таблица выступлений
CREATE TABLE performances (
    id SERIAL PRIMARY KEY,
    round_id INTEGER NOT NULL REFERENCES rounds(id) ON DELETE CASCADE ON UPDATE CASCADE,
    participant_id INTEGER NOT NULL REFERENCES participants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    position_id INTEGER NOT NULL REFERENCES debate_positions(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    logic_score INTEGER CHECK (logic_score IS NULL OR (logic_score >= 1 AND logic_score <= 10)),
    rhetoric_score INTEGER CHECK (rhetoric_score IS NULL OR (rhetoric_score >= 1 AND rhetoric_score <= 10)),
    erudition_score INTEGER CHECK (erudition_score IS NULL OR (erudition_score >= 1 AND erudition_score <= 10)),
    judge_id INTEGER NOT NULL REFERENCES judges(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT performances_unique_round_participant UNIQUE (round_id, participant_id)
);

-- Таблица аудита участников
CREATE TABLE participant_audit (
    id SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL REFERENCES participants(id) ON DELETE CASCADE ON UPDATE CASCADE,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    old_data JSONB,
    new_data JSONB
);

-- ============================================================================
-- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ ЗАПРОСОВ
-- ============================================================================

CREATE INDEX idx_participants_email ON participants(email);
CREATE INDEX idx_judges_email ON judges(email);
CREATE INDEX idx_topics_title ON topics(title);
CREATE INDEX idx_seasons_dates ON seasons(start_date, end_date);
CREATE INDEX idx_tournaments_season ON tournaments(season_id);
CREATE INDEX idx_tournaments_status ON tournaments(status_id);
CREATE INDEX idx_tournaments_dates ON tournaments(start_date, end_date);
CREATE INDEX idx_rounds_tournament ON rounds(tournament_id);
CREATE INDEX idx_rounds_topic ON rounds(topic_id);
CREATE INDEX idx_rounds_tournament_number ON rounds(tournament_id, round_number);
CREATE INDEX idx_performances_round ON performances(round_id);
CREATE INDEX idx_performances_participant ON performances(participant_id);
CREATE INDEX idx_performances_position ON performances(position_id);
CREATE INDEX idx_performances_judge ON performances(judge_id);
CREATE INDEX idx_performances_scores ON performances(logic_score, rhetoric_score, erudition_score);
CREATE INDEX idx_participant_audit_participant ON participant_audit(participant_id);
CREATE INDEX idx_participant_audit_date ON participant_audit(change_date);

-- ============================================================================
-- ФУНКЦИИ
-- ============================================================================

-- Функция для расчета итогового балла выступления
CREATE OR REPLACE FUNCTION calculate_total_score(
    logic_score INTEGER,
    rhetoric_score INTEGER,
    erudition_score INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(logic_score, 0) + COALESCE(rhetoric_score, 0) + COALESCE(erudition_score, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Функция для автоматического обновления статусов всех турниров
CREATE OR REPLACE FUNCTION update_all_tournament_statuses() RETURNS VOID AS $$
DECLARE
    upcoming_status_id INTEGER;
    active_status_id INTEGER;
    completed_status_id INTEGER;
BEGIN
    -- Получаем ID статусов
    SELECT id INTO upcoming_status_id FROM tournament_statuses WHERE code = 'upcoming';
    SELECT id INTO active_status_id FROM tournament_statuses WHERE code = 'active';
    SELECT id INTO completed_status_id FROM tournament_statuses WHERE code = 'completed';
    
    -- Обновляем статусы на основе текущей даты
    UPDATE tournaments
    SET status_id = CASE
        WHEN end_date IS NOT NULL AND end_date < CURRENT_DATE THEN completed_status_id
        WHEN start_date <= CURRENT_DATE AND (end_date IS NULL OR end_date >= CURRENT_DATE) THEN active_status_id
        ELSE upcoming_status_id
    END;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ТРИГГЕРЫ
-- ============================================================================

-- Триггер для автоматического обновления статуса турнира при изменении дат
CREATE OR REPLACE FUNCTION update_tournament_status() RETURNS TRIGGER AS $$
DECLARE
    upcoming_status_id INTEGER;
    active_status_id INTEGER;
    completed_status_id INTEGER;
    new_status_id INTEGER;
BEGIN
    -- Получаем ID статусов
    SELECT id INTO upcoming_status_id FROM tournament_statuses WHERE code = 'upcoming';
    SELECT id INTO active_status_id FROM tournament_statuses WHERE code = 'active';
    SELECT id INTO completed_status_id FROM tournament_statuses WHERE code = 'completed';
    
    -- Определяем новый статус
    new_status_id := CASE
        WHEN NEW.end_date IS NOT NULL AND NEW.end_date < CURRENT_DATE THEN completed_status_id
        WHEN NEW.start_date <= CURRENT_DATE AND (NEW.end_date IS NULL OR NEW.end_date >= CURRENT_DATE) THEN active_status_id
        ELSE upcoming_status_id
    END;
    
    -- Обновляем статус, если он изменился
    IF NEW.status_id != new_status_id THEN
        NEW.status_id := new_status_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tournament_status
    BEFORE INSERT OR UPDATE OF start_date, end_date ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION update_tournament_status();

-- Триггер для валидации оценок выступления
CREATE OR REPLACE FUNCTION validate_performance_scores() RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, что оценки находятся в диапазоне 1-10, если они не NULL
    IF NEW.logic_score IS NOT NULL AND (NEW.logic_score < 1 OR NEW.logic_score > 10) THEN
        RAISE EXCEPTION 'logic_score must be between 1 and 10';
    END IF;
    
    IF NEW.rhetoric_score IS NOT NULL AND (NEW.rhetoric_score < 1 OR NEW.rhetoric_score > 10) THEN
        RAISE EXCEPTION 'rhetoric_score must be between 1 and 10';
    END IF;
    
    IF NEW.erudition_score IS NOT NULL AND (NEW.erudition_score < 1 OR NEW.erudition_score > 10) THEN
        RAISE EXCEPTION 'erudition_score must be between 1 and 10';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_performance_scores
    BEFORE INSERT OR UPDATE OF logic_score, rhetoric_score, erudition_score ON performances
    FOR EACH ROW
    EXECUTE FUNCTION validate_performance_scores();

-- Триггер для обеспечения уникальности номера раунда в турнире
CREATE OR REPLACE FUNCTION validate_round_number() RETURNS TRIGGER AS $$
BEGIN
    -- Проверка уникальности выполняется через UNIQUE constraint
    -- Этот триггер можно использовать для дополнительной валидации
    IF NEW.round_number <= 0 THEN
        RAISE EXCEPTION 'round_number must be positive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_round_number
    BEFORE INSERT OR UPDATE OF round_number ON rounds
    FOR EACH ROW
    EXECUTE FUNCTION validate_round_number();

-- Триггер для автоматической установки даты создания
CREATE OR REPLACE FUNCTION set_created_at() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_created_at_participants
    BEFORE INSERT ON participants
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

CREATE TRIGGER trigger_set_created_at_judges
    BEFORE INSERT ON judges
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

CREATE TRIGGER trigger_set_created_at_topics
    BEFORE INSERT ON topics
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

CREATE TRIGGER trigger_set_created_at_seasons
    BEFORE INSERT ON seasons
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

CREATE TRIGGER trigger_set_created_at_tournaments
    BEFORE INSERT ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

CREATE TRIGGER trigger_set_created_at_rounds
    BEFORE INSERT ON rounds
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

CREATE TRIGGER trigger_set_created_at_performances
    BEFORE INSERT ON performances
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();

-- Триггер для логирования изменений участников
CREATE OR REPLACE FUNCTION log_participant_changes() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO participant_audit (participant_id, action, new_data)
        VALUES (NEW.id, 'INSERT', row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO participant_audit (participant_id, action, old_data, new_data)
        VALUES (NEW.id, 'UPDATE', row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO participant_audit (participant_id, action, old_data)
        VALUES (OLD.id, 'DELETE', row_to_json(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_participant_changes
    AFTER INSERT OR UPDATE OR DELETE ON participants
    FOR EACH ROW
    EXECUTE FUNCTION log_participant_changes();

-- ============================================================================
-- ВСТАВКА ИСХОДНЫХ ДАННЫХ (Reference Data)
-- ============================================================================

-- Вставка статусов турниров
INSERT INTO tournament_statuses (code, name, description) VALUES
    ('upcoming', 'Предстоящий', 'Турнир еще не начался'),
    ('active', 'Активный', 'Турнир проходит в данный момент'),
    ('completed', 'Завершен', 'Турнир завершен');

-- Вставка позиций в дебатах
INSERT INTO debate_positions (code, name, description) VALUES
    ('for', 'За', 'Позиция "За" в дебатах'),
    ('against', 'Против', 'Позиция "Против" в дебатах');

-- ============================================================================
-- КОММЕНТАРИИ К ТАБЛИЦАМ
-- ============================================================================

COMMENT ON TABLE tournament_statuses IS 'Справочная таблица статусов турниров (нормализация)';
COMMENT ON TABLE debate_positions IS 'Справочная таблица позиций в дебатах (нормализация)';
COMMENT ON TABLE participants IS 'Участники дискуссионного клуба';
COMMENT ON TABLE judges IS 'Члены жюри, оценивающие выступления';
COMMENT ON TABLE topics IS 'Темы для обсуждения в дебатах';
COMMENT ON TABLE seasons IS 'Временные периоды проведения турниров';
COMMENT ON TABLE tournaments IS 'Турниры в рамках сезонов';
COMMENT ON TABLE rounds IS 'Отдельные раунды дебатов в турнирах';
COMMENT ON TABLE performances IS 'Выступления участников с оценками';
COMMENT ON TABLE participant_audit IS 'Аудит изменений данных участников';

COMMENT ON FUNCTION calculate_total_score IS 'Вычисляет сумму трех оценок выступления';
COMMENT ON FUNCTION update_all_tournament_statuses IS 'Обновляет статусы всех турниров на основе текущей даты';

