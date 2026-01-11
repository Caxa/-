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

// Получение справочных данных

func (r *Repository) GetTournamentStatuses() ([]models.TournamentStatus, error) {
	rows, err := r.db.Query("SELECT id, code, name, description, created_at FROM tournament_statuses ORDER BY id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var statuses []models.TournamentStatus
	for rows.Next() {
		var s models.TournamentStatus
		if err := rows.Scan(&s.ID, &s.Code, &s.Name, &s.Description, &s.CreatedAt); err != nil {
			return nil, err
		}
		statuses = append(statuses, s)
	}
	return statuses, rows.Err()
}

func (r *Repository) GetDebatePositions() ([]models.DebatePosition, error) {
	rows, err := r.db.Query("SELECT id, code, name, description, created_at FROM debate_positions ORDER BY id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var positions []models.DebatePosition
	for rows.Next() {
		var p models.DebatePosition
		if err := rows.Scan(&p.ID, &p.Code, &p.Name, &p.Description, &p.CreatedAt); err != nil {
			return nil, err
		}
		positions = append(positions, p)
	}
	return positions, rows.Err()
}

// Участники
func (r *Repository) CreateParticipant(firstName, lastName, email string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO participants (first_name, last_name, email) VALUES ($1, $2, $3) RETURNING id",
		firstName, lastName, email,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetParticipants() ([]models.Participant, error) {
	rows, err := r.db.Query("SELECT id, first_name, last_name, email, created_at FROM participants ORDER BY id")
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
		"UPDATE participants SET first_name = $1, last_name = $2, email = $3 WHERE id = $4",
		firstName, lastName, email, id,
	)
	return err
}

func (r *Repository) DeleteParticipant(id int) error {
	_, err := r.db.Exec("DELETE FROM participants WHERE id = $1", id)
	return err
}

// Жюри
func (r *Repository) CreateJudge(firstName, lastName, email string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO judges (first_name, last_name, email) VALUES ($1, $2, $3) RETURNING id",
		firstName, lastName, email,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetJudges() ([]models.Judge, error) {
	rows, err := r.db.Query("SELECT id, first_name, last_name, email, created_at FROM judges ORDER BY id")
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
		"UPDATE judges SET first_name = $1, last_name = $2, email = $3 WHERE id = $4",
		firstName, lastName, email, id,
	)
	return err
}

func (r *Repository) DeleteJudge(id int) error {
	_, err := r.db.Exec("DELETE FROM judges WHERE id = $1", id)
	return err
}

// Темы
func (r *Repository) CreateTopic(title, description string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO topics (title, description) VALUES ($1, $2) RETURNING id",
		title, description,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetTopics() ([]models.Topic, error) {
	rows, err := r.db.Query("SELECT id, title, description, created_at FROM topics ORDER BY id")
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
	err := r.db.QueryRow("SELECT id, title, description, created_at FROM topics WHERE id = $1", id).
		Scan(&t.ID, &t.Title, &t.Description, &t.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) UpdateTopic(id int, title, description string) error {
	_, err := r.db.Exec(
		"UPDATE topics SET title = $1, description = $2 WHERE id = $3",
		title, description, id,
	)
	return err
}

func (r *Repository) DeleteTopic(id int) error {
	_, err := r.db.Exec("DELETE FROM topics WHERE id = $1", id)
	return err
}

// Сезоны
func (r *Repository) CreateSeason(name string, startDate, endDate time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO seasons (name, start_date, end_date) VALUES ($1, $2, $3) RETURNING id",
		name, startDate, endDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetSeasons() ([]models.Season, error) {
	rows, err := r.db.Query("SELECT id, name, start_date, end_date, created_at FROM seasons ORDER BY id")
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
	err := r.db.QueryRow("SELECT id, name, start_date, end_date, created_at FROM seasons WHERE id = $1", id).
		Scan(&s.ID, &s.Name, &s.StartDate, &s.EndDate, &s.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *Repository) UpdateSeason(id int, name string, startDate, endDate time.Time) error {
	_, err := r.db.Exec(
		"UPDATE seasons SET name = $1, start_date = $2, end_date = $3 WHERE id = $4",
		name, startDate, endDate, id,
	)
	return err
}

func (r *Repository) DeleteSeason(id int) error {
	_, err := r.db.Exec("DELETE FROM seasons WHERE id = $1", id)
	return err
}

// Турниры
func (r *Repository) CreateTournament(seasonID int, name string, startDate time.Time, endDate *time.Time) (int, error) {
	// Получаем статус "upcoming" по умолчанию (триггер обновит его автоматически)
	var statusID int
	err := r.db.QueryRow("SELECT id FROM tournament_statuses WHERE code = 'upcoming'").Scan(&statusID)
	if err != nil {
		// Если статуса нет, используем значение по умолчанию (будет установлено триггером)
		statusID = 1
	}
	
	var id int
	err = r.db.QueryRow(
		"INSERT INTO tournaments (season_id, name, start_date, end_date, status_id) VALUES ($1, $2, $3, $4, $5) RETURNING id",
		seasonID, name, startDate, endDate, statusID,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetTournaments() ([]models.Tournament, error) {
	// Сначала обновляем статусы в базе данных
	r.UpdateAllTournamentStatuses()
	
	rows, err := r.db.Query(`
		SELECT 
			t.id, 
			t.season_id, 
			t.name, 
			t.start_date, 
			t.end_date, 
			t.status_id,
			ts.code as status_code,
			ts.name as status_name,
			t.created_at 
		FROM tournaments t
		LEFT JOIN tournament_statuses ts ON t.status_id = ts.id
		ORDER BY t.start_date DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tournaments []models.Tournament
	for rows.Next() {
		var t models.Tournament
		var statusCode, statusName sql.NullString
		if err := rows.Scan(&t.ID, &t.SeasonID, &t.Name, &t.StartDate, &t.EndDate, &t.StatusID, &statusCode, &statusName, &t.CreatedAt); err != nil {
			return nil, err
		}
		if statusCode.Valid && statusName.Valid {
			t.Status = &models.TournamentStatus{
				ID:   t.StatusID,
				Code: statusCode.String,
				Name: statusName.String,
			}
		}
		tournaments = append(tournaments, t)
	}
	return tournaments, rows.Err()
}

func (r *Repository) GetTournamentByID(id int) (*models.Tournament, error) {
	// Обновляем статус перед получением
	r.UpdateAllTournamentStatuses()
	
	var t models.Tournament
	var statusCode, statusName sql.NullString
	err := r.db.QueryRow(`
		SELECT 
			t.id, 
			t.season_id, 
			t.name, 
			t.start_date, 
			t.end_date, 
			t.status_id,
			ts.code as status_code,
			ts.name as status_name,
			t.created_at 
		FROM tournaments t
		LEFT JOIN tournament_statuses ts ON t.status_id = ts.id
		WHERE t.id = $1
	`, id).
		Scan(&t.ID, &t.SeasonID, &t.Name, &t.StartDate, &t.EndDate, &t.StatusID, &statusCode, &statusName, &t.CreatedAt)
	if err != nil {
		return nil, err
	}
	if statusCode.Valid && statusName.Valid {
		t.Status = &models.TournamentStatus{
			ID:   t.StatusID,
			Code: statusCode.String,
			Name: statusName.String,
		}
	}
	return &t, nil
}

func (r *Repository) UpdateTournament(id int, seasonID int, name string, startDate time.Time, endDate *time.Time) error {
	_, err := r.db.Exec(
		"UPDATE tournaments SET season_id = $1, name = $2, start_date = $3, end_date = $4 WHERE id = $5",
		seasonID, name, startDate, endDate, id,
	)
	return err
}

func (r *Repository) DeleteTournament(id int) error {
	_, err := r.db.Exec("DELETE FROM tournaments WHERE id = $1", id)
	return err
}

// Раунды
func (r *Repository) CreateRound(tournamentID, topicID, roundNumber int, roundDate time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO rounds (tournament_id, topic_id, round_number, round_date) VALUES ($1, $2, $3, $4) RETURNING id",
		tournamentID, topicID, roundNumber, roundDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetRounds() ([]models.Round, error) {
	rows, err := r.db.Query(`
		SELECT id, tournament_id, topic_id, round_number, round_date, created_at 
		FROM rounds 
		ORDER BY tournament_id, round_number
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
		SELECT id, tournament_id, topic_id, round_number, round_date, created_at 
		FROM rounds 
		WHERE tournament_id = $1
		ORDER BY round_number
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
	err := r.db.QueryRow("SELECT id, tournament_id, topic_id, round_number, round_date, created_at FROM rounds WHERE id = $1", id).
		Scan(&round.ID, &round.TournamentID, &round.TopicID, &round.RoundNumber, &round.RoundDate, &round.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &round, nil
}

func (r *Repository) GetRoundsCountByTournament(tournamentID int) (int, error) {
	var count int
	err := r.db.QueryRow("SELECT COUNT(*) FROM rounds WHERE tournament_id = $1", tournamentID).Scan(&count)
	return count, err
}

func (r *Repository) UpdateRound(id int, tournamentID, topicID, roundNumber int, roundDate time.Time) error {
	_, err := r.db.Exec(
		"UPDATE rounds SET tournament_id = $1, topic_id = $2, round_number = $3, round_date = $4 WHERE id = $5",
		tournamentID, topicID, roundNumber, roundDate, id,
	)
	return err
}

func (r *Repository) DeleteRound(id int) error {
	_, err := r.db.Exec("DELETE FROM rounds WHERE id = $1", id)
	return err
}

// Выступления
func (r *Repository) CreatePerformance(roundID, participantID int, positionCode string, logicScore, rhetoricScore, eruditionScore *int, judgeID int) (int, error) {
	// Получаем position_id по коду ('for' или 'against')
	var positionID int
	err := r.db.QueryRow("SELECT id FROM debate_positions WHERE code = $1", positionCode).Scan(&positionID)
	if err != nil {
		return 0, err
	}
	
	var id int
	err = r.db.QueryRow(
		`INSERT INTO performances (round_id, participant_id, position_id, logic_score, rhetoric_score, erudition_score, judge_id) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
		roundID, participantID, positionID, logicScore, rhetoricScore, eruditionScore, judgeID,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetPerformances() ([]models.Performance, error) {
	rows, err := r.db.Query(`
		SELECT 
			perf.id, 
			perf.round_id, 
			perf.participant_id, 
			perf.position_id,
			dp.code as position_code,
			dp.name as position_name,
			perf.logic_score, 
			perf.rhetoric_score, 
			perf.erudition_score, 
			perf.judge_id, 
			perf.created_at 
		FROM performances perf
		LEFT JOIN debate_positions dp ON perf.position_id = dp.id
		ORDER BY perf.id
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var performances []models.Performance
	for rows.Next() {
		var p models.Performance
		var positionCode, positionName sql.NullString
		if err := rows.Scan(&p.ID, &p.RoundID, &p.ParticipantID, &p.PositionID, &positionCode, &positionName, &p.LogicScore, &p.RhetoricScore, &p.EruditionScore, &p.JudgeID, &p.CreatedAt); err != nil {
			return nil, err
		}
		if positionCode.Valid && positionName.Valid {
			p.Position = &models.DebatePosition{
				ID:   p.PositionID,
				Code: positionCode.String,
				Name: positionName.String,
			}
		}
		performances = append(performances, p)
	}
	return performances, rows.Err()
}

func (r *Repository) UpdatePerformance(id int, logicScore, rhetoricScore, eruditionScore *int) error {
	_, err := r.db.Exec(
		"UPDATE performances SET logic_score = $1, rhetoric_score = $2, erudition_score = $3 WHERE id = $4",
		logicScore, rhetoricScore, eruditionScore, id,
	)
	return err
}

func (r *Repository) DeletePerformance(id int) error {
	_, err := r.db.Exec("DELETE FROM performances WHERE id = $1", id)
	return err
}

// Запрос а) Список всех участников турнира с указанием их команды по каждой теме
func (r *Repository) GetTournamentParticipants(tournamentID int) ([]models.TournamentParticipant, error) {
	query := `
		SELECT DISTINCT
			p.id as participant_id,
			p.first_name as first_name,
			p.last_name as last_name,
			t.id as topic_id,
			t.title as topic_title,
			dp.name as position
		FROM participants p
		JOIN performances perf ON p.id = perf.participant_id
		JOIN rounds r ON perf.round_id = r.id
		JOIN topics t ON r.topic_id = t.id
		JOIN debate_positions dp ON perf.position_id = dp.id
		WHERE r.tournament_id = $1
		ORDER BY t.id, p.id
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
			p.id as participant_id,
			p.first_name as first_name,
			p.last_name as last_name,
			COALESCE(SUM(calculate_total_score(perf.logic_score, perf.rhetoric_score, perf.erudition_score)), 0) as total_score
		FROM participants p
		JOIN performances perf ON p.id = perf.participant_id
		JOIN rounds r ON perf.round_id = r.id
		WHERE r.tournament_id = $1
		GROUP BY p.id, p.first_name, p.last_name
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
				r.topic_id,
				r.id as round_id,
				dp.code as position_code,
				SUM(COALESCE(perf.logic_score, 0) + COALESCE(perf.rhetoric_score, 0) + COALESCE(perf.erudition_score, 0)) as team_score
			FROM performances perf
			JOIN rounds r ON perf.round_id = r.id
			JOIN debate_positions dp ON perf.position_id = dp.id
			WHERE perf.logic_score IS NOT NULL 
			  AND perf.rhetoric_score IS NOT NULL 
			  AND perf.erudition_score IS NOT NULL
			GROUP BY r.topic_id, r.id, dp.code
		),
		round_winners AS (
			SELECT 
				topic_id,
				round_id,
				position_code,
				team_score,
				MAX(team_score) OVER (PARTITION BY topic_id, round_id) as max_score
			FROM round_scores
		),
		winners_only AS (
			SELECT 
				topic_id,
				round_id,
				position_code,
				team_score
			FROM round_winners
			WHERE team_score = max_score
		),
		wins_by_position AS (
			SELECT 
				topic_id,
				COUNT(DISTINCT CASE WHEN position_code = 'for' THEN round_id END) as for_wins,
				COUNT(DISTINCT CASE WHEN position_code = 'against' THEN round_id END) as against_wins
			FROM winners_only
			GROUP BY topic_id
		)
		SELECT 
			t.id as topic_id,
			t.title as topic_title,
			COALESCE(w.for_wins, 0) as for_wins,
			COALESCE(w.against_wins, 0) as against_wins
		FROM topics t
		LEFT JOIN wins_by_position w ON t.id = w.topic_id
		ORDER BY t.id
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
			p.id as participant_id,
			p.first_name as first_name,
			p.last_name as last_name,
			COALESCE(SUM(calculate_total_score(perf.logic_score, perf.rhetoric_score, perf.erudition_score)), 0) as total_score
		FROM participants p
		INNER JOIN performances perf ON p.id = perf.participant_id
		INNER JOIN rounds r ON perf.round_id = r.id
		INNER JOIN tournaments t ON r.tournament_id = t.id
		WHERE t.season_id = $1
		GROUP BY p.id, p.first_name, p.last_name
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
			p.id as participant_id,
			p.first_name as first_name,
			p.last_name as last_name,
			ROUND(AVG(perf.logic_score)::numeric, 2) as avg_logic,
			ROUND(AVG(perf.rhetoric_score)::numeric, 2) as avg_rhetoric,
			ROUND(AVG(perf.erudition_score)::numeric, 2) as avg_erudition
		FROM participants p
		LEFT JOIN performances perf ON p.id = perf.participant_id
		WHERE perf.logic_score IS NOT NULL 
		  AND perf.rhetoric_score IS NOT NULL 
		  AND perf.erudition_score IS NOT NULL
		GROUP BY p.id, p.first_name, p.last_name
		ORDER BY p.id
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
			j.id as judge_id,
			j.first_name as first_name,
			j.last_name as last_name,
			COUNT(DISTINCT r.tournament_id) as count
		FROM judges j
		JOIN performances perf ON j.id = perf.judge_id
		JOIN rounds r ON perf.round_id = r.id
		GROUP BY j.id, j.first_name, j.last_name
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
			t.id as topic_id,
			t.title as topic_title,
			COUNT(DISTINCT r.tournament_id) as usage_count
		FROM topics t
		JOIN rounds r ON t.id = r.topic_id
		JOIN tournaments tour ON r.tournament_id = tour.id
		WHERE tour.season_id = $1
		GROUP BY t.id, t.title
		HAVING COUNT(DISTINCT r.tournament_id) > 1
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
			r.round_number,
			r.round_date,
			t.title as topic_title,
			STRING_AGG(
				p.first_name || ' ' || p.last_name || ' (' || dp.name || ')',
				', '
				ORDER BY dp.code, p.last_name
			) as participants
		FROM rounds r
		JOIN topics t ON r.topic_id = t.id
		LEFT JOIN performances perf ON r.id = perf.round_id
		LEFT JOIN participants p ON perf.participant_id = p.id
		LEFT JOIN debate_positions dp ON perf.position_id = dp.id
		WHERE r.tournament_id = $1
		GROUP BY r.round_number, r.round_date, t.title
		ORDER BY r.round_number
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
		SELECT DISTINCT p.id, p.first_name, p.last_name, p.email, p.created_at
		FROM participants p
		JOIN performances perf ON p.id = perf.participant_id
		JOIN rounds r ON perf.round_id = r.id
		JOIN tournaments t ON r.tournament_id = t.id
		WHERE t.season_id = $1
		ORDER BY p.last_name, p.first_name
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
	
	rows, err := r.db.Query(`
		SELECT 
			t.id, 
			t.season_id, 
			t.name, 
			t.start_date, 
			t.end_date, 
			t.status_id,
			ts.code as status_code,
			ts.name as status_name,
			t.created_at 
		FROM tournaments t
		LEFT JOIN tournament_statuses ts ON t.status_id = ts.id
		WHERE t.season_id = $1 
		ORDER BY t.start_date
	`, seasonID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tournaments []models.Tournament
	for rows.Next() {
		var t models.Tournament
		var statusCode, statusName sql.NullString
		if err := rows.Scan(&t.ID, &t.SeasonID, &t.Name, &t.StartDate, &t.EndDate, &t.StatusID, &statusCode, &statusName, &t.CreatedAt); err != nil {
			return nil, err
		}
		if statusCode.Valid && statusName.Valid {
			t.Status = &models.TournamentStatus{
				ID:   t.StatusID,
				Code: statusCode.String,
				Name: statusName.String,
			}
		}
		tournaments = append(tournaments, t)
	}
	return tournaments, rows.Err()
}

// Получить участников раунда
func (r *Repository) GetParticipantsByRound(roundID int) ([]models.Participant, error) {
	query := `
		SELECT DISTINCT p.id, p.first_name, p.last_name, p.email, p.created_at
		FROM participants p
		JOIN performances perf ON p.id = perf.participant_id
		WHERE perf.round_id = $1
		ORDER BY p.last_name, p.first_name
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
	_, err := r.db.Exec("SELECT update_all_tournament_statuses()")
	if err != nil {
		// Если функция не существует, используем прямой UPDATE с JOIN на tournament_statuses
		_, err = r.db.Exec(`
			WITH status_ids AS (
				SELECT 
					id as upcoming_id,
					(SELECT id FROM tournament_statuses WHERE code = 'active') as active_id,
					(SELECT id FROM tournament_statuses WHERE code = 'completed') as completed_id
				FROM tournament_statuses WHERE code = 'upcoming'
				LIMIT 1
			)
			UPDATE tournaments t
			SET status_id = CASE
				WHEN t.end_date IS NOT NULL AND t.end_date < CURRENT_DATE THEN (SELECT completed_id FROM status_ids)
				WHEN t.start_date <= CURRENT_DATE AND (t.end_date IS NULL OR t.end_date >= CURRENT_DATE) THEN (SELECT active_id FROM status_ids)
				ELSE (SELECT upcoming_id FROM status_ids)
			END
		`)
	}
	return err
}
