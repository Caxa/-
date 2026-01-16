-- Проверка данных для темы с ID 1
SELECT 
    r.ид_темы,
    COUNT(DISTINCT r.id) as количество_раундов,
    COUNT(DISTINCT perf.id) as количество_выступлений
FROM раунды r
LEFT JOIN выступления perf ON r.id = perf.ид_раунда
WHERE r.ид_темы = 1
GROUP BY r.ид_темы;

-- Проверка победителей по темам
WITH round_scores AS (
    SELECT 
        r.ид_темы,
        r.id as ид_раунда,
        dp.код as position_code,
        SUM(COALESCE(perf.оценка_логики, 0) + COALESCE(perf.оценка_риторики, 0) + COALESCE(perf.оценка_эрудиции, 0)) as team_score
    FROM выступления perf
    JOIN раунды r ON perf.ид_раунда = r.id
    JOIN позиции_дебатов dp ON perf.ид_позиции = dp.id
    WHERE perf.оценка_логики IS NOT NULL 
      AND perf.оценка_риторики IS NOT NULL 
      AND perf.оценка_эрудиции IS NOT NULL
    GROUP BY r.ид_темы, r.id, dp.код
)
SELECT 
    ид_темы,
    ид_раунда,
    position_code,
    team_score
FROM round_scores
WHERE ид_темы = 1
ORDER BY ид_раунда, team_score DESC;
