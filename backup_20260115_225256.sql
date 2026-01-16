--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: валидировать_номер_раунда(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."валидировать_номер_раунда"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Проверка уникальности выполняется через UNIQUE constraint
    -- Этот триггер можно использовать для дополнительной валидации
    IF NEW.номер_раунда <= 0 THEN
        RAISE EXCEPTION 'номер_раунда должен быть положительным';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."валидировать_номер_раунда"() OWNER TO postgres;

--
-- Name: валидировать_оценки_выступления(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."валидировать_оценки_выступления"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public."валидировать_оценки_выступления"() OWNER TO postgres;

--
-- Name: логирование_изменений_участников(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."логирование_изменений_участников"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO аудит_участников (ид_участника, действие, новые_данные)
        VALUES (NEW.ид, 'INSERT', row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO аудит_участников (ид_участника, действие, старые_данные, новые_данные)
        VALUES (NEW.ид, 'UPDATE', row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO аудит_участников (ид_участника, действие, старые_данные)
        VALUES (OLD.ид, 'DELETE', row_to_json(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public."логирование_изменений_участников"() OWNER TO postgres;

--
-- Name: логировать_изменения_участников(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."логировать_изменения_участников"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public."логировать_изменения_участников"() OWNER TO postgres;

--
-- Name: обновить_все_статусы_турниров(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."обновить_все_статусы_турниров"() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public."обновить_все_статусы_турниров"() OWNER TO postgres;

--
-- Name: FUNCTION "обновить_все_статусы_турниров"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."обновить_все_статусы_турниров"() IS 'Обновляет статусы всех турниров на основе текущей даты';


--
-- Name: обновить_статус_турнира(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."обновить_статус_турнира"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public."обновить_статус_турнира"() OWNER TO postgres;

--
-- Name: обновление_статуса_турнира(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."обновление_статуса_турнира"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.дата_окончания IS NOT NULL AND NEW.дата_окончания < CURRENT_DATE THEN
        NEW.статус := 'завершен';
    ELSIF NEW.дата_начала <= CURRENT_DATE AND (NEW.дата_окончания IS NULL OR NEW.дата_окончания >= CURRENT_DATE) THEN
        NEW.статус := 'активный';
    ELSE
        NEW.статус := 'предстоящий';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."обновление_статуса_турнира"() OWNER TO postgres;

--
-- Name: перераспределение_участников(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."перераспределение_участников"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    переменная_ид_турнира INTEGER;
    переменная_дата_начала_турнира DATE;
    переменная_общее_количество_участников INTEGER;
    переменная_количество_за INTEGER;
    переменная_количество_против INTEGER;
    переменная_новая_дата DATE;
BEGIN
    -- Получаем ид_турнира из ид_раунда
    SELECT r.ид_турнира INTO переменная_ид_турнира
    FROM раунды r
    WHERE r.ид = NEW.ид_раунда;
    
    -- Получаем дату начала турнира
    SELECT дата_начала INTO переменная_дата_начала_турнира
    FROM турниры
    WHERE ид = переменная_ид_турнира;
    
    -- Проверяем только в день начала турнира
    IF переменная_дата_начала_турнира = CURRENT_DATE THEN
        -- Подсчитываем участников по командам для всех раундов турнира
        SELECT 
            COUNT(DISTINCT CASE WHEN позиция = 'За' THEN ид_участника END),
            COUNT(DISTINCT CASE WHEN позиция = 'Против' THEN ид_участника END),
            COUNT(DISTINCT ид_участника)
        INTO переменная_количество_за, переменная_количество_против, переменная_общее_количество_участников
        FROM выступления
        WHERE ид_раунда IN (SELECT ид FROM раунды WHERE ид_турнира = переменная_ид_турнира);
        
        -- Если общее количество участников меньше четырёх, переносим турнир
        IF переменная_общее_количество_участников < 4 THEN
            переменная_новая_дата := переменная_дата_начала_турнира + INTERVAL '7 days';
            UPDATE турниры 
            SET дата_начала = переменная_новая_дата,
                дата_окончания = COALESCE(дата_окончания, дата_начала) + INTERVAL '7 days'
            WHERE ид = переменная_ид_турнира;
            
            RAISE NOTICE 'Турнир % перенесен на % из-за недостаточного количества участников (меньше 4)', 
                (SELECT название FROM турниры WHERE ид = переменная_ид_турнира), переменная_новая_дата;
        -- Если в одной команде >= 6, а в другой < 2, перераспределяем
        ELSIF (переменная_количество_за >= 6 AND переменная_количество_против < 2) OR (переменная_количество_против >= 6 AND переменная_количество_за < 2) THEN
            -- Перераспределяем участников случайным образом
            UPDATE выступления
            SET позиция = CASE 
                WHEN random() < 0.5 THEN 'За' 
                ELSE 'Против' 
            END
            WHERE ид_раунда IN (SELECT ид FROM раунды WHERE ид_турнира = переменная_ид_турнира);
            
            RAISE NOTICE 'Участники турнира % перераспределены между командами для обеспечения равенства', 
                (SELECT название FROM турниры WHERE ид = переменная_ид_турнира);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."перераспределение_участников"() OWNER TO postgres;

--
-- Name: проверка_дат_сезона(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."проверка_дат_сезона"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.дата_окончания < NEW.дата_начала THEN
        RAISE EXCEPTION 'Дата окончания сезона не может быть раньше даты начала';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."проверка_дат_сезона"() OWNER TO postgres;

--
-- Name: проверка_дат_турнира(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."проверка_дат_турнира"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.дата_окончания IS NOT NULL AND NEW.дата_окончания < NEW.дата_начала THEN
        RAISE EXCEPTION 'Дата окончания турнира не может быть раньше даты начала';
    END IF;
    IF EXISTS (
        SELECT 1 FROM сезоны 
        WHERE ид = NEW.ид_сезона 
        AND (NEW.дата_начала < дата_начала OR NEW.дата_начала > дата_окончания)
    ) THEN
        RAISE EXCEPTION 'Дата начала турнира должна быть в пределах сезона';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."проверка_дат_турнира"() OWNER TO postgres;

--
-- Name: проверка_номера_раунда(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."проверка_номера_раунда"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM раунды 
        WHERE ид_турнира = NEW.ид_турнира 
        AND номер_раунда = NEW.номер_раунда 
        AND ид != COALESCE(NEW.ид, 0)
    ) THEN
        RAISE EXCEPTION 'Раунд с номером % уже существует в этом турнире', NEW.номер_раунда;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."проверка_номера_раунда"() OWNER TO postgres;

--
-- Name: проверка_оценок_выступления(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."проверка_оценок_выступления"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.оценка_логики IS NOT NULL AND (NEW.оценка_логики < 0 OR NEW.оценка_логики > 10) THEN
        RAISE EXCEPTION 'Оценка логики должна быть в диапазоне от 0 до 10';
    END IF;
    IF NEW.оценка_риторики IS NOT NULL AND (NEW.оценка_риторики < 0 OR NEW.оценка_риторики > 10) THEN
        RAISE EXCEPTION 'Оценка риторики должна быть в диапазоне от 0 до 10';
    END IF;
    IF NEW.оценка_эрудиции IS NOT NULL AND (NEW.оценка_эрудиции < 0 OR NEW.оценка_эрудиции > 10) THEN
        RAISE EXCEPTION 'Оценка эрудиции должна быть в диапазоне от 0 до 10';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."проверка_оценок_выступления"() OWNER TO postgres;

--
-- Name: расчет_итогового_балла(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."расчет_итогового_балла"("оценка_логики" integer, "оценка_риторики" integer, "оценка_эрудиции" integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    RETURN COALESCE(оценка_логики, 0) + COALESCE(оценка_риторики, 0) + COALESCE(оценка_эрудиции, 0);
END;
$$;


ALTER FUNCTION public."расчет_итогового_балла"("оценка_логики" integer, "оценка_риторики" integer, "оценка_эрудиции" integer) OWNER TO postgres;

--
-- Name: FUNCTION "расчет_итогового_балла"("оценка_логики" integer, "оценка_риторики" integer, "оценка_эрудиции" integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."расчет_итогового_балла"("оценка_логики" integer, "оценка_риторики" integer, "оценка_эрудиции" integer) IS 'Вычисляет сумму трех оценок выступления';


--
-- Name: установить_дату_создания(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."установить_дату_создания"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.дата_создания IS NULL THEN
        NEW.дата_создания := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."установить_дату_создания"() OWNER TO postgres;

--
-- Name: установка_даты_создания(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."установка_даты_создания"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.дата_создания IS NULL THEN
        NEW.дата_создания := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public."установка_даты_создания"() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: аудит_участников; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."аудит_участников" (
    id integer NOT NULL,
    "ид_участника" integer NOT NULL,
    "действие" character varying(10) NOT NULL,
    "дата_изменения" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "старые_данные" jsonb,
    "новые_данные" jsonb,
    CONSTRAINT "аудит_участников_действие_check" CHECK ((("действие")::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
);


ALTER TABLE public."аудит_участников" OWNER TO postgres;

--
-- Name: TABLE "аудит_участников"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."аудит_участников" IS 'Аудит изменений данных участников';


--
-- Name: аудит_участников_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."аудит_участников_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."аудит_участников_id_seq" OWNER TO postgres;

--
-- Name: аудит_участников_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."аудит_участников_id_seq" OWNED BY public."аудит_участников".id;


--
-- Name: выступления; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."выступления" (
    id integer NOT NULL,
    "ид_раунда" integer NOT NULL,
    "ид_участника" integer NOT NULL,
    "ид_позиции" integer NOT NULL,
    "оценка_логики" integer,
    "оценка_риторики" integer,
    "оценка_эрудиции" integer,
    "ид_судьи" integer NOT NULL,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "выступления_оценка_логики_check" CHECK ((("оценка_логики" IS NULL) OR (("оценка_логики" >= 1) AND ("оценка_логики" <= 10)))),
    CONSTRAINT "выступления_оценка_риторики_check" CHECK ((("оценка_риторики" IS NULL) OR (("оценка_риторики" >= 1) AND ("оценка_риторики" <= 10)))),
    CONSTRAINT "выступления_оценка_эрудиции_check" CHECK ((("оценка_эрудиции" IS NULL) OR (("оценка_эрудиции" >= 1) AND ("оценка_эрудиции" <= 10))))
);


ALTER TABLE public."выступления" OWNER TO postgres;

--
-- Name: TABLE "выступления"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."выступления" IS 'Выступления участников с оценками';


--
-- Name: выступления_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."выступления_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."выступления_id_seq" OWNER TO postgres;

--
-- Name: выступления_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."выступления_id_seq" OWNED BY public."выступления".id;


--
-- Name: выступления_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."выступления_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."выступления_ид_посл" OWNER TO postgres;

--
-- Name: жюри; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."жюри" (
    id integer NOT NULL,
    "имя" character varying(100) NOT NULL,
    "фамилия" character varying(100) NOT NULL,
    "электронная_почта" character varying(255) NOT NULL,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."жюри" OWNER TO postgres;

--
-- Name: TABLE "жюри"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."жюри" IS 'Члены жюри, оценивающие выступления';


--
-- Name: жюри_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."жюри_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."жюри_id_seq" OWNER TO postgres;

--
-- Name: жюри_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."жюри_id_seq" OWNED BY public."жюри".id;


--
-- Name: жюри_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."жюри_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."жюри_ид_посл" OWNER TO postgres;

--
-- Name: позиции_дебатов; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."позиции_дебатов" (
    id integer NOT NULL,
    "код" character varying(10) NOT NULL,
    "название" character varying(50) NOT NULL,
    "описание" text,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."позиции_дебатов" OWNER TO postgres;

--
-- Name: TABLE "позиции_дебатов"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."позиции_дебатов" IS 'Справочная таблица позиций в дебатах (нормализация)';


--
-- Name: позиции_дебатов_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."позиции_дебатов_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."позиции_дебатов_id_seq" OWNER TO postgres;

--
-- Name: позиции_дебатов_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."позиции_дебатов_id_seq" OWNED BY public."позиции_дебатов".id;


--
-- Name: раунды; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."раунды" (
    id integer NOT NULL,
    "ид_турнира" integer NOT NULL,
    "ид_темы" integer NOT NULL,
    "номер_раунда" integer NOT NULL,
    "дата_раунда" date NOT NULL,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "раунды_номер_положительный" CHECK (("номер_раунда" > 0))
);


ALTER TABLE public."раунды" OWNER TO postgres;

--
-- Name: TABLE "раунды"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."раунды" IS 'Отдельные раунды дебатов в турнирах';


--
-- Name: раунды_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."раунды_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."раунды_id_seq" OWNER TO postgres;

--
-- Name: раунды_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."раунды_id_seq" OWNED BY public."раунды".id;


--
-- Name: раунды_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."раунды_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."раунды_ид_посл" OWNER TO postgres;

--
-- Name: сезоны; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."сезоны" (
    id integer NOT NULL,
    "название" character varying(255) NOT NULL,
    "дата_начала" date NOT NULL,
    "дата_окончания" date NOT NULL,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "сезоны_даты_валидны" CHECK (("дата_окончания" >= "дата_начала"))
);


ALTER TABLE public."сезоны" OWNER TO postgres;

--
-- Name: TABLE "сезоны"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."сезоны" IS 'Временные периоды проведения турниров';


--
-- Name: сезоны_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."сезоны_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."сезоны_id_seq" OWNER TO postgres;

--
-- Name: сезоны_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."сезоны_id_seq" OWNED BY public."сезоны".id;


--
-- Name: сезоны_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."сезоны_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."сезоны_ид_посл" OWNER TO postgres;

--
-- Name: статусы_турниров; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."статусы_турниров" (
    id integer NOT NULL,
    "код" character varying(20) NOT NULL,
    "название" character varying(100) NOT NULL,
    "описание" text,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."статусы_турниров" OWNER TO postgres;

--
-- Name: TABLE "статусы_турниров"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."статусы_турниров" IS 'Справочная таблица статусов турниров (нормализация)';


--
-- Name: статусы_турниров_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."статусы_турниров_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."статусы_турниров_id_seq" OWNER TO postgres;

--
-- Name: статусы_турниров_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."статусы_турниров_id_seq" OWNED BY public."статусы_турниров".id;


--
-- Name: темы; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."темы" (
    id integer NOT NULL,
    "заголовок" character varying(500) NOT NULL,
    "описание" text,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."темы" OWNER TO postgres;

--
-- Name: TABLE "темы"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."темы" IS 'Темы для обсуждения в дебатах';


--
-- Name: темы_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."темы_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."темы_id_seq" OWNER TO postgres;

--
-- Name: темы_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."темы_id_seq" OWNED BY public."темы".id;


--
-- Name: темы_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."темы_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."темы_ид_посл" OWNER TO postgres;

--
-- Name: турниры; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."турниры" (
    id integer NOT NULL,
    "ид_сезона" integer NOT NULL,
    "название" character varying(200) NOT NULL,
    "дата_начала" date NOT NULL,
    "дата_окончания" date,
    "ид_статуса" integer NOT NULL,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "турниры_даты_валидны" CHECK ((("дата_окончания" IS NULL) OR ("дата_окончания" >= "дата_начала")))
);


ALTER TABLE public."турниры" OWNER TO postgres;

--
-- Name: TABLE "турниры"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."турниры" IS 'Турниры в рамках сезонов';


--
-- Name: турниры_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."турниры_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."турниры_id_seq" OWNER TO postgres;

--
-- Name: турниры_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."турниры_id_seq" OWNED BY public."турниры".id;


--
-- Name: турниры_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."турниры_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."турниры_ид_посл" OWNER TO postgres;

--
-- Name: участники; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."участники" (
    id integer NOT NULL,
    "имя" character varying(100) NOT NULL,
    "фамилия" character varying(100) NOT NULL,
    "электронная_почта" character varying(255) NOT NULL,
    "дата_создания" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."участники" OWNER TO postgres;

--
-- Name: TABLE "участники"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."участники" IS 'Участники дискуссионного клуба';


--
-- Name: участники_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."участники_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."участники_id_seq" OWNER TO postgres;

--
-- Name: участники_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."участники_id_seq" OWNED BY public."участники".id;


--
-- Name: участники_ид_посл; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."участники_ид_посл"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."участники_ид_посл" OWNER TO postgres;

--
-- Name: аудит_участников id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."аудит_участников" ALTER COLUMN id SET DEFAULT nextval('public."аудит_участников_id_seq"'::regclass);


--
-- Name: выступления id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления" ALTER COLUMN id SET DEFAULT nextval('public."выступления_id_seq"'::regclass);


--
-- Name: жюри id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."жюри" ALTER COLUMN id SET DEFAULT nextval('public."жюри_id_seq"'::regclass);


--
-- Name: позиции_дебатов id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."позиции_дебатов" ALTER COLUMN id SET DEFAULT nextval('public."позиции_дебатов_id_seq"'::regclass);


--
-- Name: раунды id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."раунды" ALTER COLUMN id SET DEFAULT nextval('public."раунды_id_seq"'::regclass);


--
-- Name: сезоны id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сезоны" ALTER COLUMN id SET DEFAULT nextval('public."сезоны_id_seq"'::regclass);


--
-- Name: статусы_турниров id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."статусы_турниров" ALTER COLUMN id SET DEFAULT nextval('public."статусы_турниров_id_seq"'::regclass);


--
-- Name: темы id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."темы" ALTER COLUMN id SET DEFAULT nextval('public."темы_id_seq"'::regclass);


--
-- Name: турниры id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."турниры" ALTER COLUMN id SET DEFAULT nextval('public."турниры_id_seq"'::regclass);


--
-- Name: участники id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."участники" ALTER COLUMN id SET DEFAULT nextval('public."участники_id_seq"'::regclass);


--
-- Data for Name: аудит_участников; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."аудит_участников" (id, "ид_участника", "действие", "дата_изменения", "старые_данные", "новые_данные") FROM stdin;
1	1	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 1, "имя": "Иван", "фамилия": "Иванов", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "ivan.ivanov@example.com"}
2	2	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 2, "имя": "Мария", "фамилия": "Петрова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "maria.petrova@example.com"}
3	3	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 3, "имя": "Алексей", "фамилия": "Сидоров", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "alexey.sidorov@example.com"}
4	4	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 4, "имя": "Елена", "фамилия": "Козлова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "elena.kozlova@example.com"}
5	5	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 5, "имя": "Дмитрий", "фамилия": "Новиков", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "dmitry.novikov@example.com"}
6	6	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 6, "имя": "Анна", "фамилия": "Морозова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "anna.morozova@example.com"}
7	7	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 7, "имя": "Сергей", "фамилия": "Волков", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "sergey.volkov@example.com"}
8	8	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 8, "имя": "Ольга", "фамилия": "Соколова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "olga.sokolova@example.com"}
9	9	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 9, "имя": "Николай", "фамилия": "Лебедев", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "nikolay.lebedev@example.com"}
10	10	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 10, "имя": "Татьяна", "фамилия": "Семенова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "tatiana.semenova@example.com"}
11	11	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 11, "имя": "Андрей", "фамилия": "Егоров", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "andrey.egorov@example.com"}
12	12	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 12, "имя": "Наталья", "фамилия": "Павлова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "natalya.pavlova@example.com"}
13	13	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 13, "имя": "Владимир", "фамилия": "Козлов", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "vladimir.kozlov@example.com"}
14	14	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 14, "имя": "Екатерина", "фамилия": "Степанова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "ekaterina.stepanova@example.com"}
15	15	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 15, "имя": "Михаил", "фамилия": "Николаев", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "mikhail.nikolaev@example.com"}
16	16	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 16, "имя": "Ирина", "фамилия": "Орлова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "irina.orlova@example.com"}
17	17	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 17, "имя": "Александр", "фамилия": "Андреев", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "alexander.andreev@example.com"}
18	18	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 18, "имя": "Светлана", "фамилия": "Макарова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "svetlana.makarova@example.com"}
19	19	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 19, "имя": "Павел", "фамилия": "Никитин", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "pavel.nikitin@example.com"}
20	20	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 20, "имя": "Юлия", "фамилия": "Захарова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "yulia.zakharova@example.com"}
21	21	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 21, "имя": "Артем", "фамилия": "Смирнов", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "artem.smirnov@example.com"}
22	22	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 22, "имя": "Дарья", "фамилия": "Борисова", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "darya.borisova@example.com"}
23	23	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 23, "имя": "Игорь", "фамилия": "Яковлев", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "igor.yakovlev@example.com"}
24	24	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 24, "имя": "Валентина", "фамилия": "Григорьева", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "valentina.grigorieva@example.com"}
25	25	INSERT	2026-01-11 20:44:21.063874	\N	{"id": 25, "имя": "Роман", "фамилия": "Романов", "дата_создания": "2026-01-11T20:44:21.063874", "электронная_почта": "roman.romanov@example.com"}
26	26	INSERT	2026-01-13 19:30:49.575099	\N	{"id": 26, "имя": "Айрат", "фамилия": "Шарушев", "дата_создания": "2026-01-13T19:30:49.575099", "электронная_почта": "airat.sharushev@gmail.com"}
\.


--
-- Data for Name: выступления; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."выступления" (id, "ид_раунда", "ид_участника", "ид_позиции", "оценка_логики", "оценка_риторики", "оценка_эрудиции", "ид_судьи", "дата_создания") FROM stdin;
1	1	1	1	7	6	8	6	2026-01-11 20:44:21.07953
2	1	2	1	8	7	9	1	2026-01-11 20:44:21.07953
3	1	3	1	9	8	8	10	2026-01-11 20:44:21.07953
4	1	4	1	7	9	9	4	2026-01-11 20:44:21.07953
5	1	5	1	8	6	8	2	2026-01-11 20:44:21.07953
6	1	6	2	6	8	9	4	2026-01-11 20:44:21.07953
7	1	7	2	7	6	7	8	2026-01-11 20:44:21.07953
8	1	8	2	8	7	8	7	2026-01-11 20:44:21.07953
9	1	9	2	5	8	9	10	2026-01-11 20:44:21.07953
10	1	10	2	6	6	7	6	2026-01-11 20:44:21.07953
11	2	1	1	7	6	8	3	2026-01-11 20:44:21.07953
12	2	2	1	8	7	9	8	2026-01-11 20:44:21.07953
13	2	3	1	9	8	8	4	2026-01-11 20:44:21.07953
14	2	4	1	7	9	9	10	2026-01-11 20:44:21.07953
15	2	5	1	8	6	8	10	2026-01-11 20:44:21.07953
16	2	6	2	6	8	9	4	2026-01-11 20:44:21.07953
17	2	7	2	7	6	7	1	2026-01-11 20:44:21.07953
18	2	8	2	8	7	8	9	2026-01-11 20:44:21.07953
19	2	9	2	5	8	9	8	2026-01-11 20:44:21.07953
20	2	10	2	6	6	7	1	2026-01-11 20:44:21.07953
21	3	1	1	7	6	8	4	2026-01-11 20:44:21.07953
22	3	2	1	8	7	9	1	2026-01-11 20:44:21.07953
23	3	3	1	9	8	8	3	2026-01-11 20:44:21.07953
24	3	4	1	7	9	9	6	2026-01-11 20:44:21.07953
25	3	5	1	8	6	8	5	2026-01-11 20:44:21.07953
26	3	6	2	6	8	9	10	2026-01-11 20:44:21.07953
27	3	7	2	7	6	7	8	2026-01-11 20:44:21.07953
28	3	8	2	8	7	8	10	2026-01-11 20:44:21.07953
29	3	9	2	5	8	9	4	2026-01-11 20:44:21.07953
30	3	10	2	6	6	7	8	2026-01-11 20:44:21.07953
31	4	1	1	7	6	8	7	2026-01-11 20:44:21.07953
32	4	2	1	8	7	9	10	2026-01-11 20:44:21.07953
33	4	3	1	9	8	8	2	2026-01-11 20:44:21.07953
34	4	4	1	7	9	9	8	2026-01-11 20:44:21.07953
35	4	5	1	8	6	8	10	2026-01-11 20:44:21.07953
36	4	6	2	6	8	9	10	2026-01-11 20:44:21.07953
37	4	7	2	7	6	7	8	2026-01-11 20:44:21.07953
38	4	8	2	8	7	8	5	2026-01-11 20:44:21.07953
39	4	9	2	5	8	9	1	2026-01-11 20:44:21.07953
40	4	10	2	6	6	7	2	2026-01-11 20:44:21.07953
41	5	1	1	7	6	8	9	2026-01-11 20:44:21.07953
42	5	2	1	8	7	9	4	2026-01-11 20:44:21.07953
43	5	3	1	9	8	8	6	2026-01-11 20:44:21.07953
44	5	4	1	7	9	9	2	2026-01-11 20:44:21.07953
45	5	5	1	8	6	8	3	2026-01-11 20:44:21.07953
46	5	6	2	6	8	9	5	2026-01-11 20:44:21.07953
47	5	7	2	7	6	7	1	2026-01-11 20:44:21.07953
48	5	8	2	8	7	8	5	2026-01-11 20:44:21.07953
49	5	9	2	5	8	9	1	2026-01-11 20:44:21.07953
50	5	10	2	6	6	7	5	2026-01-11 20:44:21.07953
51	6	1	1	7	6	8	4	2026-01-11 20:44:21.07953
52	6	2	1	8	7	9	4	2026-01-11 20:44:21.07953
53	6	3	1	9	8	8	4	2026-01-11 20:44:21.07953
54	6	4	1	7	9	9	10	2026-01-11 20:44:21.07953
55	6	5	1	8	6	8	6	2026-01-11 20:44:21.07953
56	6	6	2	6	8	9	1	2026-01-11 20:44:21.07953
57	6	7	2	7	6	7	2	2026-01-11 20:44:21.07953
58	6	8	2	8	7	8	1	2026-01-11 20:44:21.07953
59	6	9	2	5	8	9	3	2026-01-11 20:44:21.07953
60	6	10	2	6	6	7	3	2026-01-11 20:44:21.07953
61	7	1	1	7	6	8	4	2026-01-11 20:44:21.07953
62	7	2	1	8	7	9	4	2026-01-11 20:44:21.07953
63	7	3	1	9	8	8	1	2026-01-11 20:44:21.07953
64	7	4	1	7	9	9	5	2026-01-11 20:44:21.07953
65	7	5	1	8	6	8	5	2026-01-11 20:44:21.07953
66	7	6	2	6	8	9	6	2026-01-11 20:44:21.07953
67	7	7	2	7	6	7	1	2026-01-11 20:44:21.07953
68	7	8	2	8	7	8	4	2026-01-11 20:44:21.07953
69	7	9	2	5	8	9	6	2026-01-11 20:44:21.07953
70	7	10	2	6	6	7	7	2026-01-11 20:44:21.07953
71	8	1	1	7	6	8	7	2026-01-11 20:44:21.07953
72	8	2	1	8	7	9	4	2026-01-11 20:44:21.07953
73	8	3	1	9	8	8	5	2026-01-11 20:44:21.07953
74	8	4	1	7	9	9	8	2026-01-11 20:44:21.07953
75	8	5	1	8	6	8	10	2026-01-11 20:44:21.07953
76	8	6	2	6	8	9	1	2026-01-11 20:44:21.07953
77	8	7	2	7	6	7	10	2026-01-11 20:44:21.07953
78	8	8	2	8	7	8	3	2026-01-11 20:44:21.07953
79	8	9	2	5	8	9	6	2026-01-11 20:44:21.07953
80	8	10	2	6	6	7	3	2026-01-11 20:44:21.07953
81	9	1	1	7	6	8	3	2026-01-11 20:44:21.07953
82	9	2	1	8	7	9	2	2026-01-11 20:44:21.07953
83	9	3	1	9	8	8	10	2026-01-11 20:44:21.07953
84	9	4	1	7	9	9	9	2026-01-11 20:44:21.07953
85	9	5	1	8	6	8	1	2026-01-11 20:44:21.07953
86	9	6	2	6	8	9	9	2026-01-11 20:44:21.07953
87	9	7	2	7	6	7	3	2026-01-11 20:44:21.07953
88	9	8	2	8	7	8	8	2026-01-11 20:44:21.07953
89	9	9	2	5	8	9	7	2026-01-11 20:44:21.07953
90	9	10	2	6	6	7	6	2026-01-11 20:44:21.07953
91	10	1	1	7	6	8	3	2026-01-11 20:44:21.07953
92	10	2	1	8	7	9	7	2026-01-11 20:44:21.07953
93	10	3	1	9	8	8	4	2026-01-11 20:44:21.07953
94	10	4	1	7	9	9	3	2026-01-11 20:44:21.07953
95	10	5	1	8	6	8	4	2026-01-11 20:44:21.07953
96	10	6	2	6	8	9	5	2026-01-11 20:44:21.07953
97	10	7	2	7	6	7	4	2026-01-11 20:44:21.07953
98	10	8	2	8	7	8	9	2026-01-11 20:44:21.07953
99	10	9	2	5	8	9	2	2026-01-11 20:44:21.07953
100	10	10	2	6	6	7	7	2026-01-11 20:44:21.07953
101	11	1	1	7	6	8	4	2026-01-11 20:44:21.07953
102	11	2	1	8	7	9	8	2026-01-11 20:44:21.07953
103	11	3	1	9	8	8	5	2026-01-11 20:44:21.07953
104	11	4	1	7	9	9	4	2026-01-11 20:44:21.07953
105	11	5	1	8	6	8	3	2026-01-11 20:44:21.07953
106	11	6	2	6	8	9	6	2026-01-11 20:44:21.07953
107	11	7	2	7	6	7	7	2026-01-11 20:44:21.07953
108	11	8	2	8	7	8	3	2026-01-11 20:44:21.07953
109	11	9	2	5	8	9	1	2026-01-11 20:44:21.07953
110	11	10	2	6	6	7	8	2026-01-11 20:44:21.07953
111	12	1	1	7	6	8	5	2026-01-11 20:44:21.07953
112	12	2	1	8	7	9	10	2026-01-11 20:44:21.07953
113	12	3	1	9	8	8	6	2026-01-11 20:44:21.07953
114	12	4	1	7	9	9	6	2026-01-11 20:44:21.07953
115	12	5	1	8	6	8	8	2026-01-11 20:44:21.07953
116	12	6	2	6	8	9	6	2026-01-11 20:44:21.07953
117	12	7	2	7	6	7	6	2026-01-11 20:44:21.07953
118	12	8	2	8	7	8	4	2026-01-11 20:44:21.07953
119	12	9	2	5	8	9	5	2026-01-11 20:44:21.07953
120	12	10	2	6	6	7	3	2026-01-11 20:44:21.07953
121	13	1	1	7	6	8	1	2026-01-11 20:44:21.07953
122	13	2	1	8	7	9	4	2026-01-11 20:44:21.07953
123	13	3	1	9	8	8	7	2026-01-11 20:44:21.07953
124	13	4	1	7	9	9	1	2026-01-11 20:44:21.07953
125	13	5	1	8	6	8	1	2026-01-11 20:44:21.07953
126	13	6	2	6	8	9	10	2026-01-11 20:44:21.07953
127	13	7	2	7	6	7	1	2026-01-11 20:44:21.07953
128	13	8	2	8	7	8	6	2026-01-11 20:44:21.07953
129	13	9	2	5	8	9	5	2026-01-11 20:44:21.07953
130	13	10	2	6	6	7	3	2026-01-11 20:44:21.07953
131	14	1	1	7	6	8	1	2026-01-11 20:44:21.07953
132	14	2	1	8	7	9	8	2026-01-11 20:44:21.07953
133	14	3	1	9	8	8	6	2026-01-11 20:44:21.07953
134	14	4	1	7	9	9	9	2026-01-11 20:44:21.07953
135	14	5	1	8	6	8	5	2026-01-11 20:44:21.07953
136	14	6	2	6	8	9	5	2026-01-11 20:44:21.07953
137	14	7	2	7	6	7	4	2026-01-11 20:44:21.07953
138	14	8	2	8	7	8	9	2026-01-11 20:44:21.07953
139	14	9	2	5	8	9	1	2026-01-11 20:44:21.07953
140	14	10	2	6	6	7	9	2026-01-11 20:44:21.07953
141	15	1	1	7	6	8	5	2026-01-11 20:44:21.07953
142	15	2	1	8	7	9	9	2026-01-11 20:44:21.07953
143	15	3	1	9	8	8	1	2026-01-11 20:44:21.07953
144	15	4	1	7	9	9	3	2026-01-11 20:44:21.07953
145	15	5	1	8	6	8	8	2026-01-11 20:44:21.07953
146	15	6	2	6	8	9	6	2026-01-11 20:44:21.07953
147	15	7	2	7	6	7	9	2026-01-11 20:44:21.07953
148	15	8	2	8	7	8	5	2026-01-11 20:44:21.07953
149	15	9	2	5	8	9	2	2026-01-11 20:44:21.07953
150	15	10	2	6	6	7	3	2026-01-11 20:44:21.07953
151	16	1	1	7	6	8	6	2026-01-11 20:44:21.07953
152	16	2	1	8	7	9	2	2026-01-11 20:44:21.07953
153	16	3	1	9	8	8	8	2026-01-11 20:44:21.07953
154	16	4	1	7	9	9	2	2026-01-11 20:44:21.07953
155	16	5	1	8	6	8	5	2026-01-11 20:44:21.07953
156	16	6	2	6	8	9	5	2026-01-11 20:44:21.07953
157	16	7	2	7	6	7	2	2026-01-11 20:44:21.07953
158	16	8	2	8	7	8	4	2026-01-11 20:44:21.07953
159	16	9	2	5	8	9	2	2026-01-11 20:44:21.07953
160	16	10	2	6	6	7	2	2026-01-11 20:44:21.07953
161	17	1	1	7	6	8	1	2026-01-11 20:44:21.07953
162	17	2	1	8	7	9	4	2026-01-11 20:44:21.07953
163	17	3	1	9	8	8	1	2026-01-11 20:44:21.07953
164	17	4	1	7	9	9	9	2026-01-11 20:44:21.07953
165	17	5	1	8	6	8	8	2026-01-11 20:44:21.07953
166	17	6	2	6	8	9	3	2026-01-11 20:44:21.07953
167	17	7	2	7	6	7	6	2026-01-11 20:44:21.07953
168	17	8	2	8	7	8	10	2026-01-11 20:44:21.07953
169	17	9	2	5	8	9	4	2026-01-11 20:44:21.07953
170	17	10	2	6	6	7	6	2026-01-11 20:44:21.07953
171	18	1	1	7	6	8	4	2026-01-11 20:44:21.07953
172	18	2	1	8	7	9	6	2026-01-11 20:44:21.07953
173	18	3	1	9	8	8	9	2026-01-11 20:44:21.07953
174	18	4	1	7	9	9	2	2026-01-11 20:44:21.07953
175	18	5	1	8	6	8	8	2026-01-11 20:44:21.07953
176	18	6	2	6	8	9	7	2026-01-11 20:44:21.07953
177	18	7	2	7	6	7	5	2026-01-11 20:44:21.07953
178	18	8	2	8	7	8	8	2026-01-11 20:44:21.07953
179	18	9	2	5	8	9	4	2026-01-11 20:44:21.07953
180	18	10	2	6	6	7	7	2026-01-11 20:44:21.07953
181	19	1	1	7	6	8	4	2026-01-11 20:44:21.07953
182	19	2	1	8	7	9	4	2026-01-11 20:44:21.07953
183	19	3	1	9	8	8	9	2026-01-11 20:44:21.07953
184	19	4	1	7	9	9	9	2026-01-11 20:44:21.07953
185	19	5	1	8	6	8	10	2026-01-11 20:44:21.07953
186	19	6	2	6	8	9	2	2026-01-11 20:44:21.07953
187	19	7	2	7	6	7	7	2026-01-11 20:44:21.07953
188	19	8	2	8	7	8	9	2026-01-11 20:44:21.07953
189	19	9	2	5	8	9	1	2026-01-11 20:44:21.07953
190	19	10	2	6	6	7	6	2026-01-11 20:44:21.07953
191	20	1	1	7	6	8	10	2026-01-11 20:44:21.07953
192	20	2	1	8	7	9	7	2026-01-11 20:44:21.07953
193	20	3	1	9	8	8	8	2026-01-11 20:44:21.07953
194	20	4	1	7	9	9	6	2026-01-11 20:44:21.07953
195	20	5	1	8	6	8	6	2026-01-11 20:44:21.07953
196	20	6	2	6	8	9	4	2026-01-11 20:44:21.07953
197	20	7	2	7	6	7	8	2026-01-11 20:44:21.07953
198	20	8	2	8	7	8	6	2026-01-11 20:44:21.07953
199	20	9	2	5	8	9	1	2026-01-11 20:44:21.07953
200	20	10	2	6	6	7	6	2026-01-11 20:44:21.07953
201	21	1	1	7	6	8	3	2026-01-11 20:44:21.07953
202	21	2	1	8	7	9	4	2026-01-11 20:44:21.07953
203	21	3	1	9	8	8	10	2026-01-11 20:44:21.07953
204	21	4	1	7	9	9	8	2026-01-11 20:44:21.07953
205	21	5	1	8	6	8	10	2026-01-11 20:44:21.07953
206	21	6	2	6	8	9	10	2026-01-11 20:44:21.07953
207	21	7	2	7	6	7	1	2026-01-11 20:44:21.07953
208	21	8	2	8	7	8	9	2026-01-11 20:44:21.07953
209	21	9	2	5	8	9	7	2026-01-11 20:44:21.07953
210	21	10	2	6	6	7	6	2026-01-11 20:44:21.07953
211	22	1	1	7	6	8	7	2026-01-11 20:44:21.07953
212	22	2	1	8	7	9	7	2026-01-11 20:44:21.07953
213	22	3	1	9	8	8	10	2026-01-11 20:44:21.07953
214	22	4	1	7	9	9	5	2026-01-11 20:44:21.07953
215	22	5	1	8	6	8	5	2026-01-11 20:44:21.07953
216	22	6	2	6	8	9	9	2026-01-11 20:44:21.07953
217	22	7	2	7	6	7	1	2026-01-11 20:44:21.07953
218	22	8	2	8	7	8	9	2026-01-11 20:44:21.07953
219	22	9	2	5	8	9	8	2026-01-11 20:44:21.07953
220	22	10	2	6	6	7	6	2026-01-11 20:44:21.07953
221	23	1	1	7	6	8	8	2026-01-11 20:44:21.07953
222	23	2	1	8	7	9	10	2026-01-11 20:44:21.07953
223	23	3	1	9	8	8	1	2026-01-11 20:44:21.07953
224	23	4	1	7	9	9	1	2026-01-11 20:44:21.07953
225	23	5	1	8	6	8	2	2026-01-11 20:44:21.07953
226	23	6	2	6	8	9	10	2026-01-11 20:44:21.07953
227	23	7	2	7	6	7	10	2026-01-11 20:44:21.07953
228	23	8	2	8	7	8	2	2026-01-11 20:44:21.07953
229	23	9	2	5	8	9	10	2026-01-11 20:44:21.07953
230	23	10	2	6	6	7	8	2026-01-11 20:44:21.07953
231	24	1	1	7	6	8	7	2026-01-11 20:44:21.07953
232	24	2	1	8	7	9	7	2026-01-11 20:44:21.07953
233	24	3	1	9	8	8	4	2026-01-11 20:44:21.07953
234	24	4	1	7	9	9	3	2026-01-11 20:44:21.07953
235	24	5	1	8	6	8	10	2026-01-11 20:44:21.07953
236	24	6	2	6	8	9	9	2026-01-11 20:44:21.07953
237	24	7	2	7	6	7	1	2026-01-11 20:44:21.07953
238	24	8	2	8	7	8	5	2026-01-11 20:44:21.07953
239	24	9	2	5	8	9	9	2026-01-11 20:44:21.07953
240	24	10	2	6	6	7	2	2026-01-11 20:44:21.07953
241	25	1	1	7	6	8	9	2026-01-11 20:44:21.07953
242	25	2	1	8	7	9	5	2026-01-11 20:44:21.07953
243	25	3	1	9	8	8	1	2026-01-11 20:44:21.07953
244	25	4	1	7	9	9	4	2026-01-11 20:44:21.07953
245	25	5	1	8	6	8	8	2026-01-11 20:44:21.07953
246	25	6	2	6	8	9	9	2026-01-11 20:44:21.07953
247	25	7	2	7	6	7	7	2026-01-11 20:44:21.07953
248	25	8	2	8	7	8	9	2026-01-11 20:44:21.07953
249	25	9	2	5	8	9	1	2026-01-11 20:44:21.07953
250	25	10	2	6	6	7	2	2026-01-11 20:44:21.07953
251	26	1	1	7	6	8	5	2026-01-11 20:44:21.07953
252	26	2	1	8	7	9	4	2026-01-11 20:44:21.07953
253	26	3	1	9	8	8	10	2026-01-11 20:44:21.07953
254	26	4	1	7	9	9	2	2026-01-11 20:44:21.07953
255	26	5	1	8	6	8	6	2026-01-11 20:44:21.07953
256	26	6	2	6	8	9	5	2026-01-11 20:44:21.07953
257	26	7	2	7	6	7	8	2026-01-11 20:44:21.07953
258	26	8	2	8	7	8	2	2026-01-11 20:44:21.07953
259	26	9	2	5	8	9	7	2026-01-11 20:44:21.07953
260	26	10	2	6	6	7	1	2026-01-11 20:44:21.07953
261	27	1	1	7	6	8	5	2026-01-11 20:44:21.07953
262	27	2	1	8	7	9	5	2026-01-11 20:44:21.07953
263	27	3	1	9	8	8	3	2026-01-11 20:44:21.07953
264	27	4	1	7	9	9	6	2026-01-11 20:44:21.07953
265	27	5	1	8	6	8	1	2026-01-11 20:44:21.07953
266	27	6	2	6	8	9	8	2026-01-11 20:44:21.07953
267	27	7	2	7	6	7	5	2026-01-11 20:44:21.07953
268	27	8	2	8	7	8	8	2026-01-11 20:44:21.07953
269	27	9	2	5	8	9	2	2026-01-11 20:44:21.07953
270	27	10	2	6	6	7	2	2026-01-11 20:44:21.07953
\.


--
-- Data for Name: жюри; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."жюри" (id, "имя", "фамилия", "электронная_почта", "дата_создания") FROM stdin;
1	Александр	Экспертов	alexander.expertov@example.com	2026-01-11 20:44:21.068509
2	Марина	Судейская	marina.sudeykaya@example.com	2026-01-11 20:44:21.068509
3	Виталий	Оценщиков	vitaly.ocenschikov@example.com	2026-01-11 20:44:21.068509
4	Галина	Арбитражная	galina.arbitrazhnaya@example.com	2026-01-11 20:44:21.068509
5	Олег	Рецензентов	oleg.recenzentov@example.com	2026-01-11 20:44:21.068509
6	Людмила	Аналитиков	lyudmila.analitikov@example.com	2026-01-11 20:44:21.068509
7	Станислав	Критиков	stanislav.kritikov@example.com	2026-01-11 20:44:21.068509
8	Раиса	Оценщиков	raisa.ocenschikov@example.com	2026-01-11 20:44:21.068509
9	Василий	Экспертов	vasily.expertov@example.com	2026-01-11 20:44:21.068509
10	Лариса	Жюринова	larisa.zhurinova@example.com	2026-01-11 20:44:21.068509
\.


--
-- Data for Name: позиции_дебатов; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."позиции_дебатов" (id, "код", "название", "описание", "дата_создания") FROM stdin;
1	for	За	Позиция "За" в дебатах	2026-01-11 20:44:21.054745
2	against	Против	Позиция "Против" в дебатах	2026-01-11 20:44:21.054745
\.


--
-- Data for Name: раунды; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."раунды" (id, "ид_турнира", "ид_темы", "номер_раунда", "дата_раунда", "дата_создания") FROM stdin;
1	1	1	1	2024-09-15	2026-01-11 20:44:21.074597
2	1	1	2	2024-09-17	2026-01-11 20:44:21.074597
3	1	1	3	2024-09-19	2026-01-11 20:44:21.074597
4	2	1	1	2024-10-10	2026-01-11 20:44:21.074597
5	2	1	2	2024-10-12	2026-01-11 20:44:21.074597
6	2	1	3	2024-10-14	2026-01-11 20:44:21.074597
7	3	1	1	2024-11-05	2026-01-11 20:44:21.074597
8	3	1	2	2024-11-07	2026-01-11 20:44:21.074597
9	3	1	3	2024-11-09	2026-01-11 20:44:21.074597
10	4	1	1	2024-12-15	2026-01-11 20:44:21.074597
11	4	1	2	2024-12-17	2026-01-11 20:44:21.074597
12	4	1	3	2024-12-19	2026-01-11 20:44:21.074597
13	5	1	1	2025-01-10	2026-01-11 20:44:21.074597
14	5	1	2	2025-01-12	2026-01-11 20:44:21.074597
15	5	1	3	2025-01-14	2026-01-11 20:44:21.074597
16	6	1	1	2025-02-05	2026-01-11 20:44:21.074597
17	6	1	2	2025-02-07	2026-01-11 20:44:21.074597
18	6	1	3	2025-02-09	2026-01-11 20:44:21.074597
19	7	1	1	2025-03-15	2026-01-11 20:44:21.074597
20	7	1	2	2025-03-17	2026-01-11 20:44:21.074597
21	7	1	3	2025-03-19	2026-01-11 20:44:21.074597
22	8	1	1	2025-04-10	2026-01-11 20:44:21.074597
23	8	1	2	2025-04-12	2026-01-11 20:44:21.074597
24	8	1	3	2025-04-14	2026-01-11 20:44:21.074597
25	9	1	1	2025-05-05	2026-01-11 20:44:21.074597
26	9	1	2	2025-05-07	2026-01-11 20:44:21.074597
27	9	1	3	2025-05-09	2026-01-11 20:44:21.074597
\.


--
-- Data for Name: сезоны; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."сезоны" (id, "название", "дата_начала", "дата_окончания", "дата_создания") FROM stdin;
1	Осенний сезон 2024	2024-09-01	2024-11-30	2026-01-11 20:44:21.070423
2	Зимний сезон 2024-2025	2024-12-01	2025-02-28	2026-01-11 20:44:21.070423
3	Весенний сезон 2025	2025-03-01	2025-05-31	2026-01-11 20:44:21.070423
4	Весенний сезон 2026	2026-03-01	2026-06-01	2026-01-11 22:01:19.784948
\.


--
-- Data for Name: статусы_турниров; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."статусы_турниров" (id, "код", "название", "описание", "дата_создания") FROM stdin;
1	upcoming	Предстоящий	Турнир еще не начался	2026-01-11 20:44:21.052186
2	active	Активный	Турнир проходит в данный момент	2026-01-11 20:44:21.052186
3	completed	Завершен	Турнир завершен	2026-01-11 20:44:21.052186
\.


--
-- Data for Name: темы; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."темы" (id, "заголовок", "описание", "дата_создания") FROM stdin;
1	Искусственный интеллект заменит человеческий труд	Обсуждение влияния ИИ на рынок труда	2026-01-11 20:44:21.069718
2	Социальные сети негативно влияют на молодежь	Анализ влияния социальных сетей на психику	2026-01-11 20:44:21.069718
3	Дистанционное обучение эффективнее очного	Сравнение эффективности форм обучения	2026-01-11 20:44:21.069718
4	Климатические изменения требуют срочных мер	Обсуждение экологических проблем	2026-01-11 20:44:21.069718
5	Всеобщий базовый доход улучшит общество	Анализ влияния базового дохода на экономику	2026-01-11 20:44:21.069718
6	Цензура в интернете необходима	Обсуждение свободы слова и цензуры	2026-01-11 20:44:21.069718
7	Генетическая модификация должна быть доступна всем	Этические вопросы генной инженерии	2026-01-11 20:44:21.069718
8	Частные тюрьмы недопустимы	Обсуждение системы правосудия	2026-01-11 20:44:21.069718
9	Животные имеют права	Философские вопросы прав животных	2026-01-11 20:44:21.069718
10	Оружие должно быть запрещено	Обсуждение права на самооборону	2026-01-11 20:44:21.069718
11	Иммиграция укрепляет экономику	Влияние миграции на развитие стран	2026-01-11 20:44:21.069718
12	Ядерная энергия безопасна	Обсуждение альтернативных источников энергии	2026-01-11 20:44:21.069718
13	Олимпийские игры устарели	Анализ актуальности Олимпиад	2026-01-11 20:44:21.069718
14	Универсальный язык улучшит мир	Обсуждение глобальной коммуникации	2026-01-11 20:44:21.069718
15	Видеоигры - это искусство	Вопросы признания видеоигр искусством	2026-01-11 20:44:21.069718
\.


--
-- Data for Name: турниры; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."турниры" (id, "ид_сезона", "название", "дата_начала", "дата_окончания", "ид_статуса", "дата_создания") FROM stdin;
1	1	Осенний турнир #1	2024-09-15	2024-09-22	3	2026-01-11 20:44:21.071254
2	1	Осенний турнир #2	2024-10-10	2024-10-17	3	2026-01-11 20:44:21.071254
3	1	Осенний турнир #3	2024-11-05	2024-11-12	3	2026-01-11 20:44:21.071254
4	2	Зимний турнир #1	2024-12-15	2024-12-22	3	2026-01-11 20:44:21.071254
5	2	Зимний турнир #2	2025-01-10	2025-01-17	3	2026-01-11 20:44:21.071254
6	2	Зимний турнир #3	2025-02-05	2025-02-12	3	2026-01-11 20:44:21.071254
7	3	Весенний турнир #1	2025-03-15	2025-03-22	3	2026-01-11 20:44:21.071254
8	3	Весенний турнир #2	2025-04-10	2025-04-17	3	2026-01-11 20:44:21.071254
9	3	Весенний турнир #3	2025-05-05	2025-05-12	3	2026-01-11 20:44:21.071254
10	4	Весенний турнир	2026-03-01	2026-04-01	1	2026-01-11 22:02:06.723546
\.


--
-- Data for Name: участники; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."участники" (id, "имя", "фамилия", "электронная_почта", "дата_создания") FROM stdin;
1	Иван	Иванов	ivan.ivanov@example.com	2026-01-11 20:44:21.063874
2	Мария	Петрова	maria.petrova@example.com	2026-01-11 20:44:21.063874
3	Алексей	Сидоров	alexey.sidorov@example.com	2026-01-11 20:44:21.063874
4	Елена	Козлова	elena.kozlova@example.com	2026-01-11 20:44:21.063874
5	Дмитрий	Новиков	dmitry.novikov@example.com	2026-01-11 20:44:21.063874
6	Анна	Морозова	anna.morozova@example.com	2026-01-11 20:44:21.063874
7	Сергей	Волков	sergey.volkov@example.com	2026-01-11 20:44:21.063874
8	Ольга	Соколова	olga.sokolova@example.com	2026-01-11 20:44:21.063874
9	Николай	Лебедев	nikolay.lebedev@example.com	2026-01-11 20:44:21.063874
10	Татьяна	Семенова	tatiana.semenova@example.com	2026-01-11 20:44:21.063874
11	Андрей	Егоров	andrey.egorov@example.com	2026-01-11 20:44:21.063874
12	Наталья	Павлова	natalya.pavlova@example.com	2026-01-11 20:44:21.063874
13	Владимир	Козлов	vladimir.kozlov@example.com	2026-01-11 20:44:21.063874
14	Екатерина	Степанова	ekaterina.stepanova@example.com	2026-01-11 20:44:21.063874
15	Михаил	Николаев	mikhail.nikolaev@example.com	2026-01-11 20:44:21.063874
16	Ирина	Орлова	irina.orlova@example.com	2026-01-11 20:44:21.063874
17	Александр	Андреев	alexander.andreev@example.com	2026-01-11 20:44:21.063874
18	Светлана	Макарова	svetlana.makarova@example.com	2026-01-11 20:44:21.063874
19	Павел	Никитин	pavel.nikitin@example.com	2026-01-11 20:44:21.063874
20	Юлия	Захарова	yulia.zakharova@example.com	2026-01-11 20:44:21.063874
21	Артем	Смирнов	artem.smirnov@example.com	2026-01-11 20:44:21.063874
22	Дарья	Борисова	darya.borisova@example.com	2026-01-11 20:44:21.063874
23	Игорь	Яковлев	igor.yakovlev@example.com	2026-01-11 20:44:21.063874
24	Валентина	Григорьева	valentina.grigorieva@example.com	2026-01-11 20:44:21.063874
25	Роман	Романов	roman.romanov@example.com	2026-01-11 20:44:21.063874
26	Айрат	Шарушев	airat.sharushev@gmail.com	2026-01-13 19:30:49.575099
\.


--
-- Name: аудит_участников_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."аудит_участников_id_seq"', 26, true);


--
-- Name: выступления_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."выступления_id_seq"', 270, true);


--
-- Name: выступления_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."выступления_ид_посл"', 210, true);


--
-- Name: жюри_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."жюри_id_seq"', 10, true);


--
-- Name: жюри_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."жюри_ид_посл"', 5, true);


--
-- Name: позиции_дебатов_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."позиции_дебатов_id_seq"', 2, true);


--
-- Name: раунды_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."раунды_id_seq"', 27, true);


--
-- Name: раунды_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."раунды_ид_посл"', 21, true);


--
-- Name: сезоны_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."сезоны_id_seq"', 4, true);


--
-- Name: сезоны_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."сезоны_ид_посл"', 2, true);


--
-- Name: статусы_турниров_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."статусы_турниров_id_seq"', 3, true);


--
-- Name: темы_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."темы_id_seq"', 15, true);


--
-- Name: темы_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."темы_ид_посл"', 8, true);


--
-- Name: турниры_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."турниры_id_seq"', 10, true);


--
-- Name: турниры_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."турниры_ид_посл"', 7, true);


--
-- Name: участники_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."участники_id_seq"', 26, true);


--
-- Name: участники_ид_посл; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."участники_ид_посл"', 25, true);


--
-- Name: аудит_участников аудит_участников_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."аудит_участников"
    ADD CONSTRAINT "аудит_участников_pkey" PRIMARY KEY (id);


--
-- Name: выступления выступления_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления"
    ADD CONSTRAINT "выступления_pkey" PRIMARY KEY (id);


--
-- Name: выступления выступления_уникальный_раунд_учас; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления"
    ADD CONSTRAINT "выступления_уникальный_раунд_учас" UNIQUE ("ид_раунда", "ид_участника");


--
-- Name: жюри жюри_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."жюри"
    ADD CONSTRAINT "жюри_pkey" PRIMARY KEY (id);


--
-- Name: жюри жюри_электронная_почта_уникальна; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."жюри"
    ADD CONSTRAINT "жюри_электронная_почта_уникальна" UNIQUE ("электронная_почта");


--
-- Name: позиции_дебатов позиции_дебатов_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."позиции_дебатов"
    ADD CONSTRAINT "позиции_дебатов_pkey" PRIMARY KEY (id);


--
-- Name: позиции_дебатов позиции_дебатов_код_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."позиции_дебатов"
    ADD CONSTRAINT "позиции_дебатов_код_key" UNIQUE ("код");


--
-- Name: позиции_дебатов позиции_дебатов_название_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."позиции_дебатов"
    ADD CONSTRAINT "позиции_дебатов_название_key" UNIQUE ("название");


--
-- Name: раунды раунды_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."раунды"
    ADD CONSTRAINT "раунды_pkey" PRIMARY KEY (id);


--
-- Name: раунды раунды_уникальный_турнир_номер; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."раунды"
    ADD CONSTRAINT "раунды_уникальный_турнир_номер" UNIQUE ("ид_турнира", "номер_раунда");


--
-- Name: сезоны сезоны_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сезоны"
    ADD CONSTRAINT "сезоны_pkey" PRIMARY KEY (id);


--
-- Name: статусы_турниров статусы_турниров_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."статусы_турниров"
    ADD CONSTRAINT "статусы_турниров_pkey" PRIMARY KEY (id);


--
-- Name: статусы_турниров статусы_турниров_код_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."статусы_турниров"
    ADD CONSTRAINT "статусы_турниров_код_key" UNIQUE ("код");


--
-- Name: статусы_турниров статусы_турниров_название_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."статусы_турниров"
    ADD CONSTRAINT "статусы_турниров_название_key" UNIQUE ("название");


--
-- Name: темы темы_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."темы"
    ADD CONSTRAINT "темы_pkey" PRIMARY KEY (id);


--
-- Name: турниры турниры_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."турниры"
    ADD CONSTRAINT "турниры_pkey" PRIMARY KEY (id);


--
-- Name: участники участники_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."участники"
    ADD CONSTRAINT "участники_pkey" PRIMARY KEY (id);


--
-- Name: участники участники_электронная_почта_уника; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."участники"
    ADD CONSTRAINT "участники_электронная_почта_уника" UNIQUE ("электронная_почта");


--
-- Name: idx_аудит_участников_дата; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_аудит_участников_дата" ON public."аудит_участников" USING btree ("дата_изменения");


--
-- Name: idx_аудит_участников_участник; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_аудит_участников_участник" ON public."аудит_участников" USING btree ("ид_участника");


--
-- Name: idx_выступления_оценки; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_выступления_оценки" ON public."выступления" USING btree ("оценка_логики", "оценка_риторики", "оценка_эрудиции");


--
-- Name: idx_выступления_позиция; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_выступления_позиция" ON public."выступления" USING btree ("ид_позиции");


--
-- Name: idx_выступления_раунд; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_выступления_раунд" ON public."выступления" USING btree ("ид_раунда");


--
-- Name: idx_выступления_судья; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_выступления_судья" ON public."выступления" USING btree ("ид_судьи");


--
-- Name: idx_выступления_участник; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_выступления_участник" ON public."выступления" USING btree ("ид_участника");


--
-- Name: idx_жюри_электронная_почта; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_жюри_электронная_почта" ON public."жюри" USING btree ("электронная_почта");


--
-- Name: idx_раунды_тема; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_раунды_тема" ON public."раунды" USING btree ("ид_темы");


--
-- Name: idx_раунды_турнир; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_раунды_турнир" ON public."раунды" USING btree ("ид_турнира");


--
-- Name: idx_раунды_турнир_номер; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_раунды_турнир_номер" ON public."раунды" USING btree ("ид_турнира", "номер_раунда");


--
-- Name: idx_сезоны_даты; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_сезоны_даты" ON public."сезоны" USING btree ("дата_начала", "дата_окончания");


--
-- Name: idx_темы_заголовок; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_темы_заголовок" ON public."темы" USING btree ("заголовок");


--
-- Name: idx_турниры_даты; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_турниры_даты" ON public."турниры" USING btree ("дата_начала", "дата_окончания");


--
-- Name: idx_турниры_сезон; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_турниры_сезон" ON public."турниры" USING btree ("ид_сезона");


--
-- Name: idx_турниры_статус; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_турниры_статус" ON public."турниры" USING btree ("ид_статуса");


--
-- Name: idx_участники_электронная_почта; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_участники_электронная_почта" ON public."участники" USING btree ("электронная_почта");


--
-- Name: раунды триггер_валидировать_номер_раунда; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_валидировать_номер_раунда" BEFORE INSERT OR UPDATE OF "номер_раунда" ON public."раунды" FOR EACH ROW EXECUTE FUNCTION public."валидировать_номер_раунда"();


--
-- Name: выступления триггер_валидировать_оценки_высту; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_валидировать_оценки_высту" BEFORE INSERT OR UPDATE OF "оценка_логики", "оценка_риторики", "оценка_эрудиции" ON public."выступления" FOR EACH ROW EXECUTE FUNCTION public."валидировать_оценки_выступления"();


--
-- Name: участники триггер_логировать_изменения_учас; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_логировать_изменения_учас" AFTER INSERT OR DELETE OR UPDATE ON public."участники" FOR EACH ROW EXECUTE FUNCTION public."логировать_изменения_участников"();


--
-- Name: турниры триггер_обновить_статус_турнира; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_обновить_статус_турнира" BEFORE INSERT OR UPDATE OF "дата_начала", "дата_окончания" ON public."турниры" FOR EACH ROW EXECUTE FUNCTION public."обновить_статус_турнира"();


--
-- Name: выступления триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."выступления" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: жюри триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."жюри" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: раунды триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."раунды" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: сезоны триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."сезоны" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: темы триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."темы" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: турниры триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."турниры" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: участники триггер_установить_дату_создания_; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "триггер_установить_дату_создания_" BEFORE INSERT ON public."участники" FOR EACH ROW EXECUTE FUNCTION public."установить_дату_создания"();


--
-- Name: аудит_участников аудит_участников_ид_участника_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."аудит_участников"
    ADD CONSTRAINT "аудит_участников_ид_участника_fkey" FOREIGN KEY ("ид_участника") REFERENCES public."участники"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: выступления выступления_ид_позиции_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления"
    ADD CONSTRAINT "выступления_ид_позиции_fkey" FOREIGN KEY ("ид_позиции") REFERENCES public."позиции_дебатов"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: выступления выступления_ид_раунда_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления"
    ADD CONSTRAINT "выступления_ид_раунда_fkey" FOREIGN KEY ("ид_раунда") REFERENCES public."раунды"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: выступления выступления_ид_судьи_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления"
    ADD CONSTRAINT "выступления_ид_судьи_fkey" FOREIGN KEY ("ид_судьи") REFERENCES public."жюри"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: выступления выступления_ид_участника_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."выступления"
    ADD CONSTRAINT "выступления_ид_участника_fkey" FOREIGN KEY ("ид_участника") REFERENCES public."участники"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: раунды раунды_ид_темы_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."раунды"
    ADD CONSTRAINT "раунды_ид_темы_fkey" FOREIGN KEY ("ид_темы") REFERENCES public."темы"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: раунды раунды_ид_турнира_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."раунды"
    ADD CONSTRAINT "раунды_ид_турнира_fkey" FOREIGN KEY ("ид_турнира") REFERENCES public."турниры"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: турниры турниры_ид_сезона_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."турниры"
    ADD CONSTRAINT "турниры_ид_сезона_fkey" FOREIGN KEY ("ид_сезона") REFERENCES public."сезоны"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: турниры турниры_ид_статуса_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."турниры"
    ADD CONSTRAINT "турниры_ид_статуса_fkey" FOREIGN KEY ("ид_статуса") REFERENCES public."статусы_турниров"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: турниры турниры_сезон_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."турниры"
    ADD CONSTRAINT "турниры_сезон_fk" FOREIGN KEY ("ид_сезона") REFERENCES public."сезоны"(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

