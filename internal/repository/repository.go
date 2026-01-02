package repository

import (
	"database/sql"
	"debate-club/internal/models"
	"time"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Участники
func (r *Repository) CreateParticipant(firstName, lastName, email string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO участники (имя, фамилия, электронная_почта) VALUES ($1, $2, $3) RETURNING ид",
		firstName, lastName, email,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetParticipants() ([]models.Participant, error) {
	rows, err := r.db.Query("SELECT ид, имя, фамилия, электронная_почта, дата_создания FROM участники ORDER BY ид")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var participants []models.Participant
	for rows.Next() {
		var p models.Participant
		if err := rows.Scan(&p.ID, &p.FirstName, &p.LastName, &p.Email, &p.CreatedAt); err != nil {
			return nil, err
		}
		participants = append(participants, p)
	}
	return participants, rows.Err()
}

func (r *Repository) UpdateParticipant(id int, firstName, lastName, email string) error {
	_, err := r.db.Exec(
		"UPDATE участники SET имя = $1, фамилия = $2, электронная_почта = $3 WHERE ид = $4",
		firstName, lastName, email, id,
	)
	return err
}

func (r *Repository) DeleteParticipant(id int) error {
	_, err := r.db.Exec("DELETE FROM участники WHERE ид = $1", id)
	return err
}

// Жюри
func (r *Repository) CreateJudge(firstName, lastName, email string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO жюри (имя, фамилия, электронная_почта) VALUES ($1, $2, $3) RETURNING ид",
		firstName, lastName, email,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetJudges() ([]models.Judge, error) {
	rows, err := r.db.Query("SELECT ид, имя, фамилия, электронная_почта, дата_создания FROM жюри ORDER BY ид")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var judges []models.Judge
	for rows.Next() {
		var j models.Judge
		if err := rows.Scan(&j.ID, &j.FirstName, &j.LastName, &j.Email, &j.CreatedAt); err != nil {
			return nil, err
		}
		judges = append(judges, j)
	}
	return judges, rows.Err()
}

func (r *Repository) UpdateJudge(id int, firstName, lastName, email string) error {
	_, err := r.db.Exec(
		"UPDATE жюри SET имя = $1, фамилия = $2, электронная_почта = $3 WHERE ид = $4",
		firstName, lastName, email, id,
	)
	return err
}

func (r *Repository) DeleteJudge(id int) error {
	_, err := r.db.Exec("DELETE FROM жюри WHERE ид = $1", id)
	return err
}

// Темы
func (r *Repository) CreateTopic(title, description string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO темы (заголовок, описание) VALUES ($1, $2) RETURNING ид",
		title, description,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetTopics() ([]models.Topic, error) {
	rows, err := r.db.Query("SELECT ид, заголовок, описание, дата_создания FROM темы ORDER BY ид")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var topics []models.Topic
	for rows.Next() {
		var t models.Topic
		if err := rows.Scan(&t.ID, &t.Title, &t.Description, &t.CreatedAt); err != nil {
			return nil, err
		}
		topics = append(topics, t)
	}
	return topics, rows.Err()
}

func (r *Repository) GetTopicByID(id int) (*models.Topic, error) {
	var t models.Topic
	err := r.db.QueryRow("SELECT ид, заголовок, описание, дата_создания FROM темы WHERE ид = $1", id).
		Scan(&t.ID, &t.Title, &t.Description, &t.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) UpdateTopic(id int, title, description string) error {
	_, err := r.db.Exec(
		"UPDATE темы SET заголовок = $1, описание = $2 WHERE ид = $3",
		title, description, id,
	)
	return err
}

func (r *Repository) DeleteTopic(id int) error {
	_, err := r.db.Exec("DELETE FROM темы WHERE ид = $1", id)
	return err
}

// Сезоны
func (r *Repository) CreateSeason(name string, startDate, endDate time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO сезоны (название, дата_начала, дата_окончания) VALUES ($1, $2, $3) RETURNING ид",
		name, startDate, endDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetSeasons() ([]models.Season, error) {
	rows, err := r.db.Query("SELECT ид, название, дата_начала, дата_окончания, дата_создания FROM сезоны ORDER BY ид")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var seasons []models.Season
	for rows.Next() {
		var s models.Season
		if err := rows.Scan(&s.ID, &s.Name, &s.StartDate, &s.EndDate, &s.CreatedAt); err != nil {
			return nil, err
		}
		seasons = append(seasons, s)
	}
	return seasons, rows.Err()
}

func (r *Repository) GetSeasonByID(id int) (*models.Season, error) {
	var s models.Season
	err := r.db.QueryRow("SELECT ид, название, дата_начала, дата_окончания, дата_создания FROM сезоны WHERE ид = $1", id).
		Scan(&s.ID, &s.Name, &s.StartDate, &s.EndDate, &s.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *Repository) UpdateSeason(id int, name string, startDate, endDate time.Time) error {
	_, err := r.db.Exec(
		"UPDATE сезоны SET название = $1, дата_начала = $2, дата_окончания = $3 WHERE ид = $4",
		name, startDate, endDate, id,
	)
	return err
}

func (r *Repository) DeleteSeason(id int) error {
	_, err := r.db.Exec("DELETE FROM сезоны WHERE ид = $1", id)
	return err
}

// Турниры
func (r *Repository) CreateTournament(seasonID int, name string, startDate time.Time, endDate *time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO турниры (ид_сезона, название, дата_начала, дата_окончания) VALUES ($1, $2, $3, $4) RETURNING ид",
		seasonID, name, startDate, endDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetTournaments() ([]models.Tournament, error) {
	// Сначала обновляем статусы в базе данных
	r.UpdateAllTournamentStatuses()
	
	rows, err := r.db.Query(`
		SELECT ид, ид_сезона, название, дата_начала, дата_окончания, статус, дата_создания 
		FROM турниры 
		ORDER BY дата_начала DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tournaments []models.Tournament
	for rows.Next() {
		var t models.Tournament
		if err := rows.Scan(&t.ID, &t.SeasonID, &t.Name, &t.StartDate, &t.EndDate, &t.Status, &t.CreatedAt); err != nil {
			return nil, err
		}
		tournaments = append(tournaments, t)
	}
	return tournaments, rows.Err()
}

func (r *Repository) GetTournamentByID(id int) (*models.Tournament, error) {
	// Обновляем статус перед получением
	r.UpdateAllTournamentStatuses()
	
	var t models.Tournament
	err := r.db.QueryRow("SELECT ид, ид_сезона, название, дата_начала, дата_окончания, статус, дата_создания FROM турниры WHERE ид = $1", id).
		Scan(&t.ID, &t.SeasonID, &t.Name, &t.StartDate, &t.EndDate, &t.Status, &t.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) UpdateTournament(id int, seasonID int, name string, startDate time.Time, endDate *time.Time) error {
	_, err := r.db.Exec(
		"UPDATE турниры SET ид_сезона = $1, название = $2, дата_начала = $3, дата_окончания = $4 WHERE ид = $5",
		seasonID, name, startDate, endDate, id,
	)
	return err
}

func (r *Repository) DeleteTournament(id int) error {
	_, err := r.db.Exec("DELETE FROM турниры WHERE ид = $1", id)
	return err
}

// Раунды
func (r *Repository) CreateRound(tournamentID, topicID, roundNumber int, roundDate time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO раунды (ид_турнира, ид_темы, номер_раунда, дата_раунда) VALUES ($1, $2, $3, $4) RETURNING ид",
		tournamentID, topicID, roundNumber, roundDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetRounds() ([]models.Round, error) {
	rows, err := r.db.Query(`
		SELECT ид, ид_турнира, ид_темы, номер_раунда, дата_раунда, дата_создания 
		FROM раунды 
		ORDER BY ид_турнира, номер_раунда
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rounds []models.Round
	for rows.Next() {
		var round models.Round
		if err := rows.Scan(&round.ID, &round.TournamentID, &round.TopicID, &round.RoundNumber, &round.RoundDate, &round.CreatedAt); err != nil {
			return nil, err
		}
		rounds = append(rounds, round)
	}
	return rounds, rows.Err()
}

func (r *Repository) GetRoundsByTournament(tournamentID int) ([]models.Round, error) {
	rows, err := r.db.Query(`
		SELECT ид, ид_турнира, ид_темы, номер_раунда, дата_раунда, дата_создания 
		FROM раунды 
		WHERE ид_турнира = $1
		ORDER BY номер_раунда
	`, tournamentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rounds []models.Round
	for rows.Next() {
		var round models.Round
		if err := rows.Scan(&round.ID, &round.TournamentID, &round.TopicID, &round.RoundNumber, &round.RoundDate, &round.CreatedAt); err != nil {
			return nil, err
		}
		rounds = append(rounds, round)
	}
	return rounds, rows.Err()
}

func (r *Repository) GetRoundByID(id int) (*models.Round, error) {
	var round models.Round
	err := r.db.QueryRow("SELECT ид, ид_турнира, ид_темы, номер_раунда, дата_раунда, дата_создания FROM раунды WHERE ид = $1", id).
		Scan(&round.ID, &round.TournamentID, &round.TopicID, &round.RoundNumber, &round.RoundDate, &round.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &round, nil
}

func (r *Repository) GetRoundsCountByTournament(tournamentID int) (int, error) {
	var count int
	err := r.db.QueryRow("SELECT COUNT(*) FROM раунды WHERE ид_турнира = $1", tournamentID).Scan(&count)
	return count, err
}

func (r *Repository) UpdateRound(id int, tournamentID, topicID, roundNumber int, roundDate time.Time) error {
	_, err := r.db.Exec(
		"UPDATE раунды SET ид_турнира = $1, ид_темы = $2, номер_раунда = $3, дата_раунда = $4 WHERE ид = $5",
		tournamentID, topicID, roundNumber, roundDate, id,
	)
	return err
}

func (r *Repository) DeleteRound(id int) error {
	_, err := r.db.Exec("DELETE FROM раунды WHERE ид = $1", id)
	return err
}

// Выступления
func (r *Repository) CreatePerformance(roundID, participantID int, position string, logicScore, rhetoricScore, eruditionScore *int, judgeID int) (int, error) {
	var id int
	err := r.db.QueryRow(
		`INSERT INTO выступления (ид_раунда, ид_участника, позиция, оценка_логики, оценка_риторики, оценка_эрудиции, ид_судьи) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING ид`,
		roundID, participantID, position, logicScore, rhetoricScore, eruditionScore, judgeID,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetPerformances() ([]models.Performance, error) {
	rows, err := r.db.Query(`
		SELECT ид, ид_раунда, ид_участника, позиция, оценка_логики, оценка_риторики, оценка_эрудиции, ид_судьи, дата_создания 
		FROM выступления 
		ORDER BY ид
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var performances []models.Performance
	for rows.Next() {
		var p models.Performance
		if err := rows.Scan(&p.ID, &p.RoundID, &p.ParticipantID, &p.Position, &p.LogicScore, &p.RhetoricScore, &p.EruditionScore, &p.JudgeID, &p.CreatedAt); err != nil {
			return nil, err
		}
		performances = append(performances, p)
	}
	return performances, rows.Err()
}

func (r *Repository) UpdatePerformance(id int, logicScore, rhetoricScore, eruditionScore *int) error {
	_, err := r.db.Exec(
		"UPDATE выступления SET оценка_логики = $1, оценка_риторики = $2, оценка_эрудиции = $3 WHERE ид = $4",
		logicScore, rhetoricScore, eruditionScore, id,
	)
	return err
}

func (r *Repository) DeletePerformance(id int) error {
	_, err := r.db.Exec("DELETE FROM выступления WHERE ид = $1", id)
	return err
}

// Запрос а) Список всех участников турнира с указанием их команды по каждой теме
func (r *Repository) GetTournamentParticipants(tournamentID int) ([]models.TournamentParticipant, error) {
	query := `
		SELECT DISTINCT
			у.ид as participant_id,
			у.имя as first_name,
			у.фамилия as last_name,
			т.ид as topic_id,
			т.заголовок as topic_title,
			в.позиция as position
		FROM участники у
		JOIN выступления в ON у.ид = в.ид_участника
		JOIN раунды р ON в.ид_раунда = р.ид
		JOIN темы т ON р.ид_темы = т.ид
		WHERE р.ид_турнира = $1
		ORDER BY т.ид, у.ид
	`
	rows, err := r.db.Query(query, tournamentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.TournamentParticipant
	for rows.Next() {
		var tp models.TournamentParticipant
		if err := rows.Scan(&tp.ParticipantID, &tp.FirstName, &tp.LastName, &tp.TopicID, &tp.TopicTitle, &tp.Position); err != nil {
			return nil, err
		}
		results = append(results, tp)
	}
	return results, rows.Err()
}

// Запрос б) Итоговые результаты турнира
func (r *Repository) GetTournamentResults(tournamentID int) ([]models.TournamentResult, error) {
	query := `
		SELECT 
			у.ид as participant_id,
			у.имя as first_name,
			у.фамилия as last_name,
			COALESCE(SUM(расчет_итогового_балла(в.оценка_логики, в.оценка_риторики, в.оценка_эрудиции)), 0) as total_score
		FROM участники у
		JOIN выступления в ON у.ид = в.ид_участника
		JOIN раунды р ON в.ид_раунда = р.ид
		WHERE р.ид_турнира = $1
		GROUP BY у.ид, у.имя, у.фамилия
		ORDER BY total_score DESC
	`
	rows, err := r.db.Query(query, tournamentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.TournamentResult
	place := 1
	for rows.Next() {
		var tr models.TournamentResult
		if err := rows.Scan(&tr.ParticipantID, &tr.FirstName, &tr.LastName, &tr.TotalScore); err != nil {
			return nil, err
		}
		tr.Place = place
		results = append(results, tr)
		place++
	}
	return results, rows.Err()
}

// Запрос в) Статистика побед "За" и "Против" по каждой теме
func (r *Repository) GetTopicsWhereAgainstWins() ([]models.TopicWinStats, error) {
	query := `
		WITH round_scores AS (
			SELECT 
				р.ид_темы,
				р.ид as round_id,
				в.позиция,
				SUM(COALESCE(в.оценка_логики, 0) + COALESCE(в.оценка_риторики, 0) + COALESCE(в.оценка_эрудиции, 0)) as team_score
			FROM выступления в
			JOIN раунды р ON в.ид_раунда = р.ид
			WHERE в.оценка_логики IS NOT NULL 
			  AND в.оценка_риторики IS NOT NULL 
			  AND в.оценка_эрудиции IS NOT NULL
			GROUP BY р.ид_темы, р.ид, в.позиция
		),
		round_winners AS (
			SELECT 
				ид_темы,
				round_id,
				позиция,
				team_score,
				MAX(team_score) OVER (PARTITION BY ид_темы, round_id) as max_score
			FROM round_scores
		),
		winners_only AS (
			SELECT 
				ид_темы,
				round_id,
				позиция,
				team_score
			FROM round_winners
			WHERE team_score = max_score
		),
		wins_by_position AS (
			SELECT 
				ид_темы,
				COUNT(DISTINCT CASE WHEN позиция = 'За' THEN round_id END) as for_wins,
				COUNT(DISTINCT CASE WHEN позиция = 'Против' THEN round_id END) as against_wins
			FROM winners_only
			GROUP BY ид_темы
		)
		SELECT 
			т.ид as topic_id,
			т.заголовок as topic_title,
			COALESCE(w.for_wins, 0) as for_wins,
			COALESCE(w.against_wins, 0) as against_wins
		FROM темы т
		LEFT JOIN wins_by_position w ON т.ид = w.ид_темы
		WHERE COALESCE(w.against_wins, 0) > 0
		ORDER BY against_wins DESC, т.ид
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.TopicWinStats
	for rows.Next() {
		var tws models.TopicWinStats
		if err := rows.Scan(&tws.TopicID, &tws.TopicTitle, &tws.ForWins, &tws.AgainstWins); err != nil {
			return nil, err
		}
		results = append(results, tws)
	}
	return results, rows.Err()
}

// Запрос г) Рейтинг участников по сумме баллов за все турниры текущего сезона
func (r *Repository) GetParticipantRatingForSeason(seasonID int) ([]models.ParticipantRating, error) {
	query := `
		SELECT 
			у.ид as participant_id,
			у.имя as first_name,
			у.фамилия as last_name,
			COALESCE(SUM(расчет_итогового_балла(в.оценка_логики, в.оценка_риторики, в.оценка_эрудиции)), 0) as total_score
		FROM участники у
		INNER JOIN выступления в ON у.ид = в.ид_участника
		INNER JOIN раунды р ON в.ид_раунда = р.ид
		INNER JOIN турниры т ON р.ид_турнира = т.ид
		WHERE т.ид_сезона = $1
		GROUP BY у.ид, у.имя, у.фамилия
		ORDER BY total_score DESC
	`
	rows, err := r.db.Query(query, seasonID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.ParticipantRating
	for rows.Next() {
		var pr models.ParticipantRating
		if err := rows.Scan(&pr.ParticipantID, &pr.FirstName, &pr.LastName, &pr.TotalScore); err != nil {
			return nil, err
		}
		results = append(results, pr)
	}
	return results, rows.Err()
}

// Запрос д) Средняя оценка каждого участника по каждому критерию
func (r *Repository) GetAverageScores() ([]models.AverageScores, error) {
	query := `
		SELECT 
			у.ид as participant_id,
			у.имя as first_name,
			у.фамилия as last_name,
			ROUND(AVG(в.оценка_логики)::numeric, 2) as avg_logic,
			ROUND(AVG(в.оценка_риторики)::numeric, 2) as avg_rhetoric,
			ROUND(AVG(в.оценка_эрудиции)::numeric, 2) as avg_erudition
		FROM участники у
		LEFT JOIN выступления в ON у.ид = в.ид_участника
		WHERE в.оценка_логики IS NOT NULL 
		  AND в.оценка_риторики IS NOT NULL 
		  AND в.оценка_эрудиции IS NOT NULL
		GROUP BY у.ид, у.имя, у.фамилия
		ORDER BY у.ид
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.AverageScores
	for rows.Next() {
		var as models.AverageScores
		if err := rows.Scan(&as.ParticipantID, &as.FirstName, &as.LastName, &as.AvgLogic, &as.AvgRhetoric, &as.AvgErudition); err != nil {
			return nil, err
		}
		results = append(results, as)
	}
	return results, rows.Err()
}

// Запрос е) Список членов жюри, участвовавших в наибольшем количестве турниров
func (r *Repository) GetJudgesByTournamentCount() ([]models.JudgeTournamentCount, error) {
	query := `
		SELECT 
			ж.ид as judge_id,
			ж.имя as first_name,
			ж.фамилия as last_name,
			COUNT(DISTINCT р.ид_турнира) as count
		FROM жюри ж
		JOIN выступления в ON ж.ид = в.ид_судьи
		JOIN раунды р ON в.ид_раунда = р.ид
		GROUP BY ж.ид, ж.имя, ж.фамилия
		ORDER BY count DESC
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.JudgeTournamentCount
	for rows.Next() {
		var jtc models.JudgeTournamentCount
		if err := rows.Scan(&jtc.JudgeID, &jtc.FirstName, &jtc.LastName, &jtc.Count); err != nil {
			return nil, err
		}
		results = append(results, jtc)
	}
	return results, rows.Err()
}

// Запрос ж) Список тем, использованных более одного раза за сезон
func (r *Repository) GetRepeatedTopicsInSeason(seasonID int) ([]models.RepeatedTopic, error) {
	query := `
		SELECT 
			т.ид as topic_id,
			т.заголовок as topic_title,
			COUNT(DISTINCT р.ид_турнира) as usage_count
		FROM темы т
		JOIN раунды р ON т.ид = р.ид_темы
		JOIN турниры тур ON р.ид_турнира = тур.ид
		WHERE тур.ид_сезона = $1
		GROUP BY т.ид, т.заголовок
		HAVING COUNT(DISTINCT р.ид_турнира) > 1
		ORDER BY usage_count DESC
	`
	rows, err := r.db.Query(query, seasonID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.RepeatedTopic
	for rows.Next() {
		var rt models.RepeatedTopic
		if err := rows.Scan(&rt.TopicID, &rt.TopicTitle, &rt.UsageCount); err != nil {
			return nil, err
		}
		results = append(results, rt)
	}
	return results, rows.Err()
}

// Запрос з) Расписание турнира с указанием тем и участников
func (r *Repository) GetTournamentSchedule(tournamentID int) ([]models.TournamentSchedule, error) {
	query := `
		SELECT 
			р.номер_раунда,
			р.дата_раунда,
			т.заголовок as topic_title,
			STRING_AGG(
				у.имя || ' ' || у.фамилия || ' (' || в.позиция || ')',
				', '
				ORDER BY в.позиция, у.фамилия
			) as participants
		FROM раунды р
		JOIN темы т ON р.ид_темы = т.ид
		LEFT JOIN выступления в ON р.ид = в.ид_раунда
		LEFT JOIN участники у ON в.ид_участника = у.ид
		WHERE р.ид_турнира = $1
		GROUP BY р.номер_раунда, р.дата_раунда, т.заголовок
		ORDER BY р.номер_раунда
	`
	rows, err := r.db.Query(query, tournamentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.TournamentSchedule
	for rows.Next() {
		var ts models.TournamentSchedule
		if err := rows.Scan(&ts.RoundNumber, &ts.RoundDate, &ts.TopicTitle, &ts.Participants); err != nil {
			return nil, err
		}
		results = append(results, ts)
	}
	return results, rows.Err()
}

// Получить участников сезона
func (r *Repository) GetParticipantsBySeason(seasonID int) ([]models.Participant, error) {
	query := `
		SELECT DISTINCT у.ид, у.имя, у.фамилия, у.электронная_почта, у.дата_создания
		FROM участники у
		JOIN выступления в ON у.ид = в.ид_участника
		JOIN раунды р ON в.ид_раунда = р.ид
		JOIN турниры т ON р.ид_турнира = т.ид
		WHERE т.ид_сезона = $1
		ORDER BY у.фамилия, у.имя
	`
	rows, err := r.db.Query(query, seasonID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var participants []models.Participant
	for rows.Next() {
		var p models.Participant
		if err := rows.Scan(&p.ID, &p.FirstName, &p.LastName, &p.Email, &p.CreatedAt); err != nil {
			return nil, err
		}
		participants = append(participants, p)
	}
	return participants, rows.Err()
}

// Получить турниры сезона
func (r *Repository) GetTournamentsBySeason(seasonID int) ([]models.Tournament, error) {
	// Обновляем статусы перед получением
	r.UpdateAllTournamentStatuses()
	
	rows, err := r.db.Query("SELECT ид, ид_сезона, название, дата_начала, дата_окончания, статус, дата_создания FROM турниры WHERE ид_сезона = $1 ORDER BY дата_начала", seasonID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tournaments []models.Tournament
	for rows.Next() {
		var t models.Tournament
		if err := rows.Scan(&t.ID, &t.SeasonID, &t.Name, &t.StartDate, &t.EndDate, &t.Status, &t.CreatedAt); err != nil {
			return nil, err
		}
		tournaments = append(tournaments, t)
	}
	return tournaments, rows.Err()
}

// Получить участников раунда
func (r *Repository) GetParticipantsByRound(roundID int) ([]models.Participant, error) {
	query := `
		SELECT DISTINCT у.ид, у.имя, у.фамилия, у.электронная_почта, у.дата_создания
		FROM участники у
		JOIN выступления в ON у.ид = в.ид_участника
		WHERE в.ид_раунда = $1
		ORDER BY у.фамилия, у.имя
	`
	rows, err := r.db.Query(query, roundID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var participants []models.Participant
	for rows.Next() {
		var p models.Participant
		if err := rows.Scan(&p.ID, &p.FirstName, &p.LastName, &p.Email, &p.CreatedAt); err != nil {
			return nil, err
		}
		participants = append(participants, p)
	}
	return participants, rows.Err()
}

// Обновить статусы всех турниров на основе текущей даты
func (r *Repository) UpdateAllTournamentStatuses() error {
	// Используем функцию из базы данных для обновления статусов
	_, err := r.db.Exec("SELECT обновить_все_статусы_турниров()")
	if err != nil {
		// Если функция не существует, используем прямой UPDATE
		_, err = r.db.Exec(`
			UPDATE турниры
			SET статус = CASE
				WHEN дата_окончания IS NOT NULL AND дата_окончания < CURRENT_DATE THEN 'завершен'
				WHEN дата_начала <= CURRENT_DATE AND (дата_окончания IS NULL OR дата_окончания >= CURRENT_DATE) THEN 'активный'
				ELSE 'предстоящий'
			END
		`)
	}
	return err
}
