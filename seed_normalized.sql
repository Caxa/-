-- ============================================================================
-- ТЕСТОВЫЕ ДАННЫЕ ДЛЯ НОРМАЛИЗОВАННОЙ БАЗЫ ДАННЫХ
-- ============================================================================

-- Вставка участников (25 участников)
INSERT INTO participants (first_name, last_name, email) VALUES
    ('Иван', 'Иванов', 'ivan.ivanov@example.com'),
    ('Мария', 'Петрова', 'maria.petrova@example.com'),
    ('Алексей', 'Сидоров', 'alexey.sidorov@example.com'),
    ('Елена', 'Козлова', 'elena.kozlova@example.com'),
    ('Дмитрий', 'Новиков', 'dmitry.novikov@example.com'),
    ('Анна', 'Морозова', 'anna.morozova@example.com'),
    ('Сергей', 'Волков', 'sergey.volkov@example.com'),
    ('Ольга', 'Соколова', 'olga.sokolova@example.com'),
    ('Николай', 'Лебедев', 'nikolay.lebedev@example.com'),
    ('Татьяна', 'Семенова', 'tatiana.semenova@example.com'),
    ('Андрей', 'Егоров', 'andrey.egorov@example.com'),
    ('Наталья', 'Павлова', 'natalya.pavlova@example.com'),
    ('Владимир', 'Козлов', 'vladimir.kozlov@example.com'),
    ('Екатерина', 'Степанова', 'ekaterina.stepanova@example.com'),
    ('Михаил', 'Николаев', 'mikhail.nikolaev@example.com'),
    ('Ирина', 'Орлова', 'irina.orlova@example.com'),
    ('Александр', 'Андреев', 'alexander.andreev@example.com'),
    ('Светлана', 'Макарова', 'svetlana.makarova@example.com'),
    ('Павел', 'Никитин', 'pavel.nikitin@example.com'),
    ('Юлия', 'Захарова', 'yulia.zakharova@example.com'),
    ('Артем', 'Смирнов', 'artem.smirnov@example.com'),
    ('Дарья', 'Борисова', 'darya.borisova@example.com'),
    ('Игорь', 'Яковлев', 'igor.yakovlev@example.com'),
    ('Валентина', 'Григорьева', 'valentina.grigorieva@example.com'),
    ('Роман', 'Романов', 'roman.romanov@example.com');

-- Вставка жюри (10 членов жюри)
INSERT INTO judges (first_name, last_name, email) VALUES
    ('Александр', 'Экспертов', 'alexander.expertov@example.com'),
    ('Марина', 'Судейская', 'marina.sudeykaya@example.com'),
    ('Виталий', 'Оценщиков', 'vitaly.ocenschikov@example.com'),
    ('Галина', 'Арбитражная', 'galina.arbitrazhnaya@example.com'),
    ('Олег', 'Рецензентов', 'oleg.recenzentov@example.com'),
    ('Людмила', 'Аналитиков', 'lyudmila.analitikov@example.com'),
    ('Станислав', 'Критиков', 'stanislav.kritikov@example.com'),
    ('Раиса', 'Оценщиков', 'raisa.ocenschikov@example.com'),
    ('Василий', 'Экспертов', 'vasily.expertov@example.com'),
    ('Лариса', 'Жюринова', 'larisa.zhurinova@example.com');

-- Вставка тем дебатов (15 тем)
INSERT INTO topics (title, description) VALUES
    ('Искусственный интеллект заменит человеческий труд', 'Обсуждение влияния ИИ на рынок труда'),
    ('Социальные сети негативно влияют на молодежь', 'Анализ влияния социальных сетей на психику'),
    ('Дистанционное обучение эффективнее очного', 'Сравнение эффективности форм обучения'),
    ('Климатические изменения требуют срочных мер', 'Обсуждение экологических проблем'),
    ('Всеобщий базовый доход улучшит общество', 'Анализ влияния базового дохода на экономику'),
    ('Цензура в интернете необходима', 'Обсуждение свободы слова и цензуры'),
    ('Генетическая модификация должна быть доступна всем', 'Этические вопросы генной инженерии'),
    ('Частные тюрьмы недопустимы', 'Обсуждение системы правосудия'),
    ('Животные имеют права', 'Философские вопросы прав животных'),
    ('Оружие должно быть запрещено', 'Обсуждение права на самооборону'),
    ('Иммиграция укрепляет экономику', 'Влияние миграции на развитие стран'),
    ('Ядерная энергия безопасна', 'Обсуждение альтернативных источников энергии'),
    ('Олимпийские игры устарели', 'Анализ актуальности Олимпиад'),
    ('Универсальный язык улучшит мир', 'Обсуждение глобальной коммуникации'),
    ('Видеоигры - это искусство', 'Вопросы признания видеоигр искусством');

-- Вставка сезонов (3 сезона)
INSERT INTO seasons (name, start_date, end_date) VALUES
    ('Осенний сезон 2024', '2024-09-01', '2024-11-30'),
    ('Зимний сезон 2024-2025', '2024-12-01', '2025-02-28'),
    ('Весенний сезон 2025', '2025-03-01', '2025-05-31');

-- Вставка турниров (используем подзапросы для получения ID статусов)
INSERT INTO tournaments (season_id, name, start_date, end_date, status_id) VALUES
    ((SELECT id FROM seasons WHERE name = 'Осенний сезон 2024'), 'Осенний турнир #1', '2024-09-15', '2024-09-22', (SELECT id FROM tournament_statuses WHERE code = 'completed')),
    ((SELECT id FROM seasons WHERE name = 'Осенний сезон 2024'), 'Осенний турнир #2', '2024-10-10', '2024-10-17', (SELECT id FROM tournament_statuses WHERE code = 'completed')),
    ((SELECT id FROM seasons WHERE name = 'Осенний сезон 2024'), 'Осенний турнир #3', '2024-11-05', '2024-11-12', (SELECT id FROM tournament_statuses WHERE code = 'active')),
    ((SELECT id FROM seasons WHERE name = 'Зимний сезон 2024-2025'), 'Зимний турнир #1', '2024-12-15', '2024-12-22', (SELECT id FROM tournament_statuses WHERE code = 'upcoming')),
    ((SELECT id FROM seasons WHERE name = 'Зимний сезон 2024-2025'), 'Зимний турнир #2', '2025-01-10', '2025-01-17', (SELECT id FROM tournament_statuses WHERE code = 'upcoming')),
    ((SELECT id FROM seasons WHERE name = 'Зимний сезон 2024-2025'), 'Зимний турнир #3', '2025-02-05', '2025-02-12', (SELECT id FROM tournament_statuses WHERE code = 'upcoming')),
    ((SELECT id FROM seasons WHERE name = 'Весенний сезон 2025'), 'Весенний турнир #1', '2025-03-15', '2025-03-22', (SELECT id FROM tournament_statuses WHERE code = 'upcoming')),
    ((SELECT id FROM seasons WHERE name = 'Весенний сезон 2025'), 'Весенний турнир #2', '2025-04-10', '2025-04-17', (SELECT id FROM tournament_statuses WHERE code = 'upcoming')),
    ((SELECT id FROM seasons WHERE name = 'Весенний сезон 2025'), 'Весенний турнир #3', '2025-05-05', '2025-05-12', (SELECT id FROM tournament_statuses WHERE code = 'upcoming'));

-- Вставка раундов (по 3 раунда на каждый турнир, всего 27 раундов)
INSERT INTO rounds (tournament_id, topic_id, round_number, round_date)
SELECT 
    t.id as tournament_id,
    (SELECT id FROM topics ORDER BY (t.id * 100 + round_num) % 15 + 1 LIMIT 1) as topic_id,
    round_num,
    t.start_date + (round_num - 1) * INTERVAL '2 days' as round_date
FROM tournaments t
CROSS JOIN generate_series(1, 3) as round_num
ORDER BY t.id, round_num;

-- Вставка выступлений (по 10 участников на раунд: 5 "За" и 5 "Против")
-- Используем функцию для генерации выступлений
DO $$
DECLARE
    round_rec RECORD;
    participant_rec RECORD;
    judge_rec RECORD;
    position_for_id INTEGER;
    position_against_id INTEGER;
    participant_counter INTEGER;
BEGIN
    -- Получаем ID позиций
    SELECT id INTO position_for_id FROM debate_positions WHERE code = 'for';
    SELECT id INTO position_against_id FROM debate_positions WHERE code = 'against';
    
    -- Для каждого раунда создаем 10 выступлений
    FOR round_rec IN SELECT id FROM rounds ORDER BY id
    LOOP
        participant_counter := 0;
        
        -- Первые 5 участников с позицией "За"
        FOR participant_rec IN SELECT id FROM participants ORDER BY id LIMIT 5
        LOOP
            SELECT id INTO judge_rec FROM judges ORDER BY RANDOM() LIMIT 1;
            
            INSERT INTO performances (
                round_id, participant_id, position_id,
                logic_score, rhetoric_score, erudition_score, judge_id
            ) VALUES (
                round_rec.id,
                participant_rec.id,
                position_for_id,
                7 + (participant_counter % 3), -- 7-9
                6 + (participant_counter % 4), -- 6-9
                8 + (participant_counter % 2), -- 8-9
                judge_rec.id
            );
            
            participant_counter := participant_counter + 1;
        END LOOP;
        
        -- Следующие 5 участников с позицией "Против"
        FOR participant_rec IN SELECT id FROM participants ORDER BY id OFFSET 5 LIMIT 5
        LOOP
            SELECT id INTO judge_rec FROM judges ORDER BY RANDOM() LIMIT 1;
            
            INSERT INTO performances (
                round_id, participant_id, position_id,
                logic_score, rhetoric_score, erudition_score, judge_id
            ) VALUES (
                round_rec.id,
                participant_rec.id,
                position_against_id,
                5 + (participant_counter % 4), -- 5-8 (ниже для баланса)
                6 + (participant_counter % 3), -- 6-8
                7 + (participant_counter % 3), -- 7-9
                judge_rec.id
            );
            
            participant_counter := participant_counter + 1;
        END LOOP;
    END LOOP;
END $$;

-- Обновляем статусы всех турниров на основе текущей даты
SELECT update_all_tournament_statuses();

-- Проверка данных
SELECT 
    (SELECT COUNT(*) FROM participants) as participants_count,
    (SELECT COUNT(*) FROM judges) as judges_count,
    (SELECT COUNT(*) FROM topics) as topics_count,
    (SELECT COUNT(*) FROM seasons) as seasons_count,
    (SELECT COUNT(*) FROM tournaments) as tournaments_count,
    (SELECT COUNT(*) FROM rounds) as rounds_count,
    (SELECT COUNT(*) FROM performances) as performances_count;
