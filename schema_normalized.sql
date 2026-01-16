-- ============================================================================
-- НОРМАЛИЗОВАННАЯ СХЕМА БАЗЫ ДАННЫХ ДЛЯ СИСТЕМЫ УПРАВЛЕНИЯ ДИСКУССИОННЫМ КЛУБОМ
-- ============================================================================
-- Таблицы и поля на русском языке, только id на английском
-- Нормализация до BCNF (Boyce-Codd Normal Form)
-- ============================================================================

-- Удаление существующих таблиц (в порядке зависимостей)
DROP TABLE IF EXISTS аудит_участников CASCADE;
DROP TABLE IF EXISTS выступления CASCADE;
DROP TABLE IF EXISTS регистрации_на_турнир CASCADE;
DROP TABLE IF EXISTS раунды CASCADE;
DROP TABLE IF EXISTS турниры CASCADE;
DROP TABLE IF EXISTS сезоны CASCADE;
DROP TABLE IF EXISTS темы CASCADE;
DROP TABLE IF EXISTS участники CASCADE;
DROP TABLE IF EXISTS жюри CASCADE;
DROP TABLE IF EXISTS статусы_турниров CASCADE;
DROP TABLE IF EXISTS позиции_дебатов CASCADE;

-- Удаление старых таблиц с английскими именами (если существуют)
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
DROP FUNCTION IF EXISTS расчет_итогового_балла(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS calculate_total_score(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS обновить_все_статусы_турниров() CASCADE;
DROP FUNCTION IF EXISTS update_all_tournament_statuses() CASCADE;
DROP SEQUENCE IF EXISTS участники_id_seq CASCADE;
DROP SEQUENCE IF EXISTS жюри_id_seq CASCADE;
DROP SEQUENCE IF EXISTS темы_id_seq CASCADE;
DROP SEQUENCE IF EXISTS сезоны_id_seq CASCADE;
DROP SEQUENCE IF EXISTS турниры_id_seq CASCADE;
DROP SEQUENCE IF EXISTS раунды_id_seq CASCADE;
DROP SEQUENCE IF EXISTS выступления_id_seq CASCADE;
DROP SEQUENCE IF EXISTS регистрации_на_турнир_id_seq CASCADE;
DROP SEQUENCE IF EXISTS аудит_участников_id_seq CASCADE;

-- ============================================================================
-- СПРАВОЧНЫЕ ТАБЛИЦЫ (Reference Tables)
-- ============================================================================

-- Таблица статусов турниров (нормализация - отдельная таблица для статусов)
CREATE TABLE статусы_турниров (
    id SERIAL PRIMARY KEY,
    код VARCHAR(20) NOT NULL UNIQUE, -- 'upcoming', 'active', 'completed'
    название VARCHAR(100) NOT NULL UNIQUE, -- 'Предстоящий', 'Активный', 'Завершен'
    описание TEXT,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Таблица позиций в дебатах (нормализация - отдельная таблица для позиций)
CREATE TABLE позиции_дебатов (
    id SERIAL PRIMARY KEY,
    код VARCHAR(10) NOT NULL UNIQUE, -- 'for', 'against'
    название VARCHAR(50) NOT NULL UNIQUE, -- 'За', 'Против'
    описание TEXT,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- ОСНОВНЫЕ ТАБЛИЦЫ (Main Tables)
-- ============================================================================

-- Таблица участников
CREATE TABLE участники (
    id SERIAL PRIMARY KEY,
    имя VARCHAR(100) NOT NULL,
    фамилия VARCHAR(100) NOT NULL,
    электронная_почта VARCHAR(255) NOT NULL UNIQUE,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT участники_электронная_почта_уникальна UNIQUE (электронная_почта)
);

-- Таблица жюри
CREATE TABLE жюри (
    id SERIAL PRIMARY KEY,
    имя VARCHAR(100) NOT NULL,
    фамилия VARCHAR(100) NOT NULL,
    электронная_почта VARCHAR(255) NOT NULL UNIQUE,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT жюри_электронная_почта_уникальна UNIQUE (электронная_почта)
);

-- Таблица тем дебатов
CREATE TABLE темы (
    id SERIAL PRIMARY KEY,
    заголовок VARCHAR(500) NOT NULL,
    описание TEXT,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Таблица сезонов
CREATE TABLE сезоны (
    id SERIAL PRIMARY KEY,
    название VARCHAR(255) NOT NULL,
    дата_начала DATE NOT NULL,
    дата_окончания DATE NOT NULL,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT сезоны_даты_валидны CHECK (дата_окончания >= дата_начала)
);

-- Таблица турниров (с внешним ключом на статусы_турниров)
CREATE TABLE турниры (
    id SERIAL PRIMARY KEY,
    ид_сезона INTEGER NOT NULL REFERENCES сезоны(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    название VARCHAR(200) NOT NULL,
    дата_начала DATE NOT NULL,
    дата_окончания DATE,
    ид_статуса INTEGER NOT NULL REFERENCES статусы_турниров(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT турниры_даты_валидны CHECK (дата_окончания IS NULL OR дата_окончания >= дата_начала),
    CONSTRAINT турниры_сезон_fk FOREIGN KEY (ид_сезона) REFERENCES сезоны(id) ON DELETE RESTRICT
);

-- Таблица раундов
CREATE TABLE раунды (
    id SERIAL PRIMARY KEY,
    ид_турнира INTEGER NOT NULL REFERENCES турниры(id) ON DELETE CASCADE ON UPDATE CASCADE,
    ид_темы INTEGER NOT NULL REFERENCES темы(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    номер_раунда INTEGER NOT NULL,
    дата_раунда DATE NOT NULL,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT раунды_уникальный_турнир_номер UNIQUE (ид_турнира, номер_раунда),
    CONSTRAINT раунды_номер_положительный CHECK (номер_раунда > 0)
);

-- Таблица регистрации участников на турнир (до начала турнира)
CREATE TABLE регистрации_на_турнир (
    id SERIAL PRIMARY KEY,
    ид_турнира INTEGER NOT NULL REFERENCES турниры(id) ON DELETE CASCADE ON UPDATE CASCADE,
    ид_участника INTEGER NOT NULL REFERENCES участники(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ид_позиции INTEGER NOT NULL REFERENCES позиции_дебатов(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    дата_регистрации TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT регистрации_уникальный_турнир_участник UNIQUE (ид_турнира, ид_участника)
);

-- Таблица выступлений
CREATE TABLE выступления (
    id SERIAL PRIMARY KEY,
    ид_раунда INTEGER NOT NULL REFERENCES раунды(id) ON DELETE CASCADE ON UPDATE CASCADE,
    ид_участника INTEGER NOT NULL REFERENCES участники(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ид_позиции INTEGER NOT NULL REFERENCES позиции_дебатов(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    оценка_логики INTEGER CHECK (оценка_логики IS NULL OR (оценка_логики >= 1 AND оценка_логики <= 10)),
    оценка_риторики INTEGER CHECK (оценка_риторики IS NULL OR (оценка_риторики >= 1 AND оценка_риторики <= 10)),
    оценка_эрудиции INTEGER CHECK (оценка_эрудиции IS NULL OR (оценка_эрудиции >= 1 AND оценка_эрудиции <= 10)),
    ид_судьи INTEGER NOT NULL REFERENCES жюри(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    дата_создания TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT выступления_уникальный_раунд_участник UNIQUE (ид_раунда, ид_участника)
);

-- Таблица аудита участников
CREATE TABLE аудит_участников (
    id SERIAL PRIMARY KEY,
    ид_участника INTEGER NOT NULL REFERENCES участники(id) ON DELETE CASCADE ON UPDATE CASCADE,
    действие VARCHAR(10) NOT NULL CHECK (действие IN ('INSERT', 'UPDATE', 'DELETE')),
    дата_изменения TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    старые_данные JSONB,
    новые_данные JSONB
);

-- ============================================================================
-- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ ЗАПРОСОВ
-- ============================================================================

CREATE INDEX idx_участники_электронная_почта ON участники(электронная_почта);
CREATE INDEX idx_жюри_электронная_почта ON жюри(электронная_почта);
CREATE INDEX idx_темы_заголовок ON темы(заголовок);
CREATE INDEX idx_сезоны_даты ON сезоны(дата_начала, дата_окончания);
CREATE INDEX idx_турниры_сезон ON турниры(ид_сезона);
CREATE INDEX idx_турниры_статус ON турниры(ид_статуса);
CREATE INDEX idx_турниры_даты ON турниры(дата_начала, дата_окончания);
CREATE INDEX idx_раунды_турнир ON раунды(ид_турнира);
CREATE INDEX idx_раунды_тема ON раунды(ид_темы);
CREATE INDEX idx_раунды_турнир_номер ON раунды(ид_турнира, номер_раунда);
CREATE INDEX idx_выступления_раунд ON выступления(ид_раунда);
CREATE INDEX idx_выступления_участник ON выступления(ид_участника);
CREATE INDEX idx_выступления_позиция ON выступления(ид_позиции);
CREATE INDEX idx_выступления_судья ON выступления(ид_судьи);
CREATE INDEX idx_выступления_оценки ON выступления(оценка_логики, оценка_риторики, оценка_эрудиции);
CREATE INDEX idx_аудит_участников_участник ON аудит_участников(ид_участника);
CREATE INDEX idx_аудит_участников_дата ON аудит_участников(дата_изменения);

-- ============================================================================
-- ФУНКЦИИ
-- ============================================================================

-- Функция для расчета итогового балла выступления
CREATE OR REPLACE FUNCTION расчет_итогового_балла(
    оценка_логики INTEGER,
    оценка_риторики INTEGER,
    оценка_эрудиции INTEGER
) RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(оценка_логики, 0) + COALESCE(оценка_риторики, 0) + COALESCE(оценка_эрудиции, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Функция для автоматического обновления статусов всех турниров
CREATE OR REPLACE FUNCTION обновить_все_статусы_турниров() RETURNS VOID AS $$
DECLARE
    ид_предстоящего INTEGER;
    ид_активного INTEGER;
    ид_завершенного INTEGER;
BEGIN
    -- Получаем ID статусов
    SELECT id INTO ид_предстоящего FROM статусы_турниров WHERE код = 'upcoming';
    SELECT id INTO ид_активного FROM статусы_турниров WHERE код = 'active';
    SELECT id INTO ид_завершенного FROM статусы_турниров WHERE код = 'completed';
    
    -- Обновляем статусы на основе текущей даты
    UPDATE турниры
    SET ид_статуса = CASE
        WHEN дата_окончания IS NOT NULL AND дата_окончания < CURRENT_DATE THEN ид_завершенного
        WHEN дата_начала <= CURRENT_DATE AND (дата_окончания IS NULL OR дата_окончания >= CURRENT_DATE) THEN ид_активного
        ELSE ид_предстоящего
    END;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ТРИГГЕРЫ
-- ============================================================================

-- Триггер для автоматического обновления статуса турнира при изменении дат
CREATE OR REPLACE FUNCTION обновить_статус_турнира() RETURNS TRIGGER AS $$
DECLARE
    ид_предстоящего INTEGER;
    ид_активного INTEGER;
    ид_завершенного INTEGER;
    новый_ид_статуса INTEGER;
BEGIN
    -- Получаем ID статусов
    SELECT id INTO ид_предстоящего FROM статусы_турниров WHERE код = 'upcoming';
    SELECT id INTO ид_активного FROM статусы_турниров WHERE код = 'active';
    SELECT id INTO ид_завершенного FROM статусы_турниров WHERE код = 'completed';
    
    -- Определяем новый статус
    новый_ид_статуса := CASE
        WHEN NEW.дата_окончания IS NOT NULL AND NEW.дата_окончания < CURRENT_DATE THEN ид_завершенного
        WHEN NEW.дата_начала <= CURRENT_DATE AND (NEW.дата_окончания IS NULL OR NEW.дата_окончания >= CURRENT_DATE) THEN ид_активного
        ELSE ид_предстоящего
    END;
    
    -- Обновляем статус, если он изменился
    IF NEW.ид_статуса != новый_ид_статуса THEN
        NEW.ид_статуса := новый_ид_статуса;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_обновить_статус_турнира
    BEFORE INSERT OR UPDATE OF дата_начала, дата_окончания ON турниры
    FOR EACH ROW
    EXECUTE FUNCTION обновить_статус_турнира();

-- Триггер для валидации оценок выступления
CREATE OR REPLACE FUNCTION валидировать_оценки_выступления() RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, что оценки находятся в диапазоне 1-10, если они не NULL
    IF NEW.оценка_логики IS NOT NULL AND (NEW.оценка_логики < 1 OR NEW.оценка_логики > 10) THEN
        RAISE EXCEPTION 'оценка_логики должна быть от 1 до 10';
    END IF;
    
    IF NEW.оценка_риторики IS NOT NULL AND (NEW.оценка_риторики < 1 OR NEW.оценка_риторики > 10) THEN
        RAISE EXCEPTION 'оценка_риторики должна быть от 1 до 10';
    END IF;
    
    IF NEW.оценка_эрудиции IS NOT NULL AND (NEW.оценка_эрудиции < 1 OR NEW.оценка_эрудиции > 10) THEN
        RAISE EXCEPTION 'оценка_эрудиции должна быть от 1 до 10';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_валидировать_оценки_выступления
    BEFORE INSERT OR UPDATE OF оценка_логики, оценка_риторики, оценка_эрудиции ON выступления
    FOR EACH ROW
    EXECUTE FUNCTION валидировать_оценки_выступления();

-- Триггер для обеспечения уникальности номера раунда в турнире
CREATE OR REPLACE FUNCTION валидировать_номер_раунда() RETURNS TRIGGER AS $$
BEGIN
    -- Проверка уникальности выполняется через UNIQUE constraint
    -- Этот триггер можно использовать для дополнительной валидации
    IF NEW.номер_раунда <= 0 THEN
        RAISE EXCEPTION 'номер_раунда должен быть положительным';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_валидировать_номер_раунда
    BEFORE INSERT OR UPDATE OF номер_раунда ON раунды
    FOR EACH ROW
    EXECUTE FUNCTION валидировать_номер_раунда();

-- ============================================================================
-- ФУНКЦИИ ДЛЯ РЕГИСТРАЦИИ И ПЕРЕРАСПРЕДЕЛЕНИЯ УЧАСТНИКОВ
-- ============================================================================

-- Функция для проверки и перераспределения участников между командами
-- Если в одной команде >= 6, а в другой < 2, то случайное перераспределение
CREATE OR REPLACE FUNCTION перераспределить_участников_турнира(ид_турнира INTEGER) RETURNS VOID AS $$
DECLARE
    количество_за INTEGER;
    количество_против INTEGER;
    общее_количество INTEGER;
    ид_позиции_за INTEGER;
    ид_позиции_против INTEGER;
    участник_рекорд RECORD;
    список_участников INTEGER[];
BEGIN
    -- Получаем ID позиций
    SELECT id INTO ид_позиции_за FROM позиции_дебатов WHERE код = 'for';
    SELECT id INTO ид_позиции_против FROM позиции_дебатов WHERE код = 'against';
    
    -- Подсчитываем количество участников в каждой команде
    SELECT COUNT(*) INTO количество_за 
    FROM регистрации_на_турнир 
    WHERE ид_турнира = перераспределить_участников_турнира.ид_турнира 
      AND ид_позиции = ид_позиции_за;
    
    SELECT COUNT(*) INTO количество_против 
    FROM регистрации_на_турнир 
    WHERE ид_турнира = перераспределить_участников_турнира.ид_турнира 
      AND ид_позиции = ид_позиции_против;
    
    общее_количество := количество_за + количество_против;
    
    -- Проверяем условие: если в одной команде >= 6, а в другой < 2
    IF (количество_за >= 6 AND количество_против < 2) OR (количество_против >= 6 AND количество_за < 2) THEN
        -- Сохраняем список участников перед удалением
        SELECT ARRAY_AGG(ид_участника) INTO список_участников
        FROM регистрации_на_турнир 
        WHERE ид_турнира = перераспределить_участников_турнира.ид_турнира;
        
        -- Удаляем все регистрации
        DELETE FROM регистрации_на_турнир WHERE ид_турнира = перераспределить_участников_турнира.ид_турнира;
        
        -- Перераспределяем случайным образом
        IF список_участников IS NOT NULL THEN
            FOREACH участник_рекорд.ид_участника IN ARRAY список_участников
            LOOP
                -- Случайно выбираем позицию (50/50)
                IF random() < 0.5 THEN
                    INSERT INTO регистрации_на_турнир (ид_турнира, ид_участника, ид_позиции)
                    VALUES (перераспределить_участников_турнира.ид_турнира, участник_рекорд.ид_участника, ид_позиции_за);
                ELSE
                    INSERT INTO регистрации_на_турнир (ид_турнира, ид_участника, ид_позиции)
                    VALUES (перераспределить_участников_турнира.ид_турнира, участник_рекорд.ид_участника, ид_позиции_против);
                END IF;
            END LOOP;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Функция для проверки количества участников и переноса турнира
-- Если общее количество участников < 4, турнир переносится на 7 дней вперед
-- Проверяет турниры, которые начинаются сегодня или завтра (чтобы успеть предупредить)
CREATE OR REPLACE FUNCTION проверить_и_перенести_турнир(ид_турнира INTEGER) RETURNS BOOLEAN AS $$
DECLARE
    общее_количество INTEGER;
    новая_дата DATE;
    турнир_рекорд RECORD;
BEGIN
    -- Получаем информацию о турнире
    SELECT * INTO турнир_рекорд FROM турниры WHERE id = ид_турнира;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Проверяем, что турнир еще не начался (начинается сегодня или завтра)
    -- Это позволяет проверить заранее и перенести, если нужно
    IF турнир_рекорд.дата_начала >= CURRENT_DATE AND турнир_рекорд.дата_начала <= CURRENT_DATE + INTERVAL '1 day' THEN
        -- Подсчитываем общее количество зарегистрированных участников
        SELECT COUNT(DISTINCT ид_участника) INTO общее_количество
        FROM регистрации_на_турнир
        WHERE ид_турнира = проверить_и_перенести_турнир.ид_турнира;
        
        -- Если участников меньше 4, переносим турнир на 7 дней вперед
        IF общее_количество < 4 THEN
            новая_дата := турнир_рекорд.дата_начала + INTERVAL '7 days';
            
            -- Обновляем дату начала турнира
            UPDATE турниры 
            SET дата_начала = новая_дата
            WHERE id = ид_турнира;
            
            -- Если есть дата окончания, тоже переносим
            IF турнир_рекорд.дата_окончания IS NOT NULL THEN
                UPDATE турниры 
                SET дата_окончания = турнир_рекорд.дата_окончания + INTERVAL '7 days'
                WHERE id = ид_турнира;
            END IF;
            
            RETURN TRUE; -- Турнир перенесен
        END IF;
    END IF;
    
    RETURN FALSE; -- Турнир не перенесен
END;
$$ LANGUAGE plpgsql;

-- Функция для автоматической проверки и обработки турниров в день их начала
-- Проверяет турниры, которые начинаются сегодня или завтра
CREATE OR REPLACE FUNCTION обработать_турниры_в_день_начала() RETURNS VOID AS $$
DECLARE
    турнир_рекорд RECORD;
    перенесен BOOLEAN;
BEGIN
    -- Находим все турниры, которые начинаются сегодня или завтра и имеют статус "предстоящий"
    FOR турнир_рекорд IN 
        SELECT t.id, t.название, t.дата_начала
        FROM турниры t
        JOIN статусы_турниров ts ON t.ид_статуса = ts.id
        WHERE t.дата_начала >= CURRENT_DATE 
          AND t.дата_начала <= CURRENT_DATE + INTERVAL '1 day'
          AND ts.код = 'upcoming'
    LOOP
        -- Сначала проверяем количество участников и переносим, если нужно
        перенесен := проверить_и_перенести_турнир(турнир_рекорд.id);
        
        -- Если турнир не был перенесен, проверяем перераспределение
        IF NOT перенесен THEN
            PERFORM перераспределить_участников_турнира(турнир_рекорд.id);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматической проверки при изменении даты начала турнира
CREATE OR REPLACE FUNCTION триггер_проверить_турнир_при_изменении_даты() RETURNS TRIGGER AS $$
BEGIN
    -- Если дата начала изменилась на сегодня, проверяем турнир
    IF NEW.дата_начала = CURRENT_DATE THEN
        PERFORM обработать_турниры_в_день_начала();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_проверить_турнир_при_изменении_даты
    AFTER UPDATE OF дата_начала ON турниры
    FOR EACH ROW
    WHEN (NEW.дата_начала = CURRENT_DATE)
    EXECUTE FUNCTION триггер_проверить_турнир_при_изменении_даты();

-- Триггер для автоматической проверки при регистрации участника
CREATE OR REPLACE FUNCTION триггер_проверить_турнир_при_регистрации() RETURNS TRIGGER AS $$
DECLARE
    дата_начала_турнира DATE;
BEGIN
    -- Получаем дату начала турнира
    SELECT дата_начала INTO дата_начала_турнира
    FROM турниры
    WHERE id = NEW.ид_турнира;
    
    -- Если турнир начинается сегодня или завтра, проверяем его
    IF дата_начала_турнира >= CURRENT_DATE AND дата_начала_турнира <= CURRENT_DATE + INTERVAL '1 day' THEN
        -- Проверяем конкретный турнир
        PERFORM проверить_и_перенести_турнир(NEW.ид_турнира);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_проверить_турнир_при_регистрации
    AFTER INSERT OR UPDATE ON регистрации_на_турнир
    FOR EACH ROW
    EXECUTE FUNCTION триггер_проверить_турнир_при_регистрации();

-- Триггер для автоматической установки даты создания
CREATE OR REPLACE FUNCTION установить_дату_создания() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.дата_создания IS NULL THEN
        NEW.дата_создания := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_установить_дату_создания_участники
    BEFORE INSERT ON участники
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

CREATE TRIGGER триггер_установить_дату_создания_жюри
    BEFORE INSERT ON жюри
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

CREATE TRIGGER триггер_установить_дату_создания_темы
    BEFORE INSERT ON темы
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

CREATE TRIGGER триггер_установить_дату_создания_сезоны
    BEFORE INSERT ON сезоны
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

CREATE TRIGGER триггер_установить_дату_создания_турниры
    BEFORE INSERT ON турниры
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

CREATE TRIGGER триггер_установить_дату_создания_раунды
    BEFORE INSERT ON раунды
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

CREATE TRIGGER триггер_установить_дату_создания_выступления
    BEFORE INSERT ON выступления
    FOR EACH ROW
    EXECUTE FUNCTION установить_дату_создания();

-- Триггер для логирования изменений участников
CREATE OR REPLACE FUNCTION логировать_изменения_участников() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO аудит_участников (ид_участника, действие, новые_данные)
        VALUES (NEW.id, 'INSERT', row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO аудит_участников (ид_участника, действие, старые_данные, новые_данные)
        VALUES (NEW.id, 'UPDATE', row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO аудит_участников (ид_участника, действие, старые_данные)
        VALUES (OLD.id, 'DELETE', row_to_json(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER триггер_логировать_изменения_участников
    AFTER INSERT OR UPDATE OR DELETE ON участники
    FOR EACH ROW
    EXECUTE FUNCTION логировать_изменения_участников();

-- ============================================================================
-- ВСТАВКА ИСХОДНЫХ ДАННЫХ (Reference Data)
-- ============================================================================

-- Вставка статусов турниров
INSERT INTO статусы_турниров (код, название, описание) VALUES
    ('upcoming', 'Предстоящий', 'Турнир еще не начался'),
    ('active', 'Активный', 'Турнир проходит в данный момент'),
    ('completed', 'Завершен', 'Турнир завершен');

-- Вставка позиций в дебатах
INSERT INTO позиции_дебатов (код, название, описание) VALUES
    ('for', 'За', 'Позиция "За" в дебатах'),
    ('against', 'Против', 'Позиция "Против" в дебатах');

-- ============================================================================
-- КОММЕНТАРИИ К ТАБЛИЦАМ
-- ============================================================================

COMMENT ON TABLE статусы_турниров IS 'Справочная таблица статусов турниров (нормализация)';
COMMENT ON TABLE позиции_дебатов IS 'Справочная таблица позиций в дебатах (нормализация)';
COMMENT ON TABLE участники IS 'Участники дискуссионного клуба';
COMMENT ON TABLE жюри IS 'Члены жюри, оценивающие выступления';
COMMENT ON TABLE темы IS 'Темы для обсуждения в дебатах';
COMMENT ON TABLE сезоны IS 'Временные периоды проведения турниров';
COMMENT ON TABLE турниры IS 'Турниры в рамках сезонов';
COMMENT ON TABLE раунды IS 'Отдельные раунды дебатов в турнирах';
COMMENT ON TABLE выступления IS 'Выступления участников с оценками';
COMMENT ON TABLE аудит_участников IS 'Аудит изменений данных участников';

COMMENT ON FUNCTION расчет_итогового_балла IS 'Вычисляет сумму трех оценок выступления';
COMMENT ON FUNCTION обновить_все_статусы_турниров IS 'Обновляет статусы всех турниров на основе текущей даты';
