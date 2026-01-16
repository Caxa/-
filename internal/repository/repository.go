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
	rows, err := r.db.Query("SELECT id, код, название, описание, дата_создания FROM статусы_турниров ORDER BY id")
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
	rows, err := r.db.Query("SELECT id, код, название, описание, дата_создания FROM позиции_дебатов ORDER BY id")
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
		"INSERT INTO участники (имя, фамилия, электронная_почта) VALUES ($1, $2, $3) RETURNING id",
		firstName, lastName, email,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetParticipants() ([]models.Participant, error) {
	rows, err := r.db.Query("SELECT id, имя, фамилия, электронная_почта, дата_создания FROM участники ORDER BY id")
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
		"UPDATE участники SET имя = $1, фамилия = $2, электронная_почта = $3 WHERE id = $4",
		firstName, lastName, email, id,
	)
	return err
}

func (r *Repository) DeleteParticipant(id int) error {
	_, err := r.db.Exec("DELETE FROM участники WHERE id = $1", id)
	return err
}

// Жюри
func (r *Repository) CreateJudge(firstName, lastName, email string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO жюри (имя, фамилия, электронная_почта) VALUES ($1, $2, $3) RETURNING id",
		firstName, lastName, email,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetJudges() ([]models.Judge, error) {
	rows, err := r.db.Query("SELECT id, имя, фамилия, электронная_почта, дата_создания FROM жюри ORDER BY id")
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
		"UPDATE жюри SET имя = $1, фамилия = $2, электронная_почта = $3 WHERE id = $4",
		firstName, lastName, email, id,
	)
	return err
}

func (r *Repository) DeleteJudge(id int) error {
	_, err := r.db.Exec("DELETE FROM жюри WHERE id = $1", id)
	return err
}

// Темы
func (r *Repository) CreateTopic(title, description string) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO темы (заголовок, описание) VALUES ($1, $2) RETURNING id",
		title, description,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetTopics() ([]models.Topic, error) {
	rows, err := r.db.Query("SELECT id, заголовок, описание, дата_создания FROM темы ORDER BY id")
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
	err := r.db.QueryRow("SELECT id, заголовок, описание, дата_создания FROM темы WHERE id = $1", id).
		Scan(&t.ID, &t.Title, &t.Description, &t.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) UpdateTopic(id int, title, description string) error {
	_, err := r.db.Exec(
		"UPDATE темы SET заголовок = $1, описание = $2 WHERE id = $3",
		title, description, id,
	)
	return err
}

func (r *Repository) DeleteTopic(id int) error {
	_, err := r.db.Exec("DELETE FROM темы WHERE id = $1", id)
	return err
}

// Сезоны
func (r *Repository) CreateSeason(name string, startDate, endDate time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO сезоны (название, дата_начала, дата_окончания) VALUES ($1, $2, $3) RETURNING id",
		name, startDate, endDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetSeasons() ([]models.Season, error) {
	rows, err := r.db.Query("SELECT id, название, дата_начала, дата_окончания, дата_создания FROM сезоны ORDER BY id")
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
	err := r.db.QueryRow("SELECT id, название, дата_начала, дата_окончания, дата_создания FROM сезоны WHERE id = $1", id).
		Scan(&s.ID, &s.Name, &s.StartDate, &s.EndDate, &s.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *Repository) UpdateSeason(id int, name string, startDate, endDate time.Time) error {
	_, err := r.db.Exec(
		"UPDATE сезоны SET название = $1, дата_начала = $2, дата_окончания = $3 WHERE id = $4",
		name, startDate, endDate, id,
	)
	return err
}

func (r *Repository) DeleteSeason(id int) error {
	_, err := r.db.Exec("DELETE FROM сезоны WHERE id = $1", id)
	return err
}

// Турниры
func (r *Repository) CreateTournament(seasonID int, name string, startDate time.Time, endDate *time.Time) (int, error) {
	// Получаем статус "upcoming" по умолчанию (триггер обновит его автоматически)
	var statusID int
	err := r.db.QueryRow("SELECT id FROM статусы_турниров WHERE код = 'upcoming'").Scan(&statusID)
	if err != nil {
		// Если статуса нет, используем значение по умолчанию (будет установлено триггером)
		statusID = 1
	}
	
	var id int
	err = r.db.QueryRow(
		"INSERT INTO турниры (ид_сезона, название, дата_начала, дата_окончания, ид_статуса) VALUES ($1, $2, $3, $4, $5) RETURNING id",
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
			t.ид_сезона, 
			t.название, 
			t.дата_начала, 
			t.дата_окончания, 
			t.ид_статуса,
			ts.код as status_code,
			ts.название as status_name,
			t.дата_создания 
		FROM турниры t
		LEFT JOIN статусы_турниров ts ON t.ид_статуса = ts.id
		ORDER BY t.дата_начала DESC
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
			t.ид_сезона, 
			t.название, 
			t.дата_начала, 
			t.дата_окончания, 
			t.ид_статуса,
			ts.код as status_code,
			ts.название as status_name,
			t.дата_создания 
		FROM турниры t
		LEFT JOIN статусы_турниров ts ON t.ид_статуса = ts.id
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
		"UPDATE турниры SET ид_сезона = $1, название = $2, дата_начала = $3, дата_окончания = $4 WHERE id = $5",
		seasonID, name, startDate, endDate, id,
	)
	return err
}

func (r *Repository) DeleteTournament(id int) error {
	_, err := r.db.Exec("DELETE FROM турниры WHERE id = $1", id)
	return err
}

// Раунды
func (r *Repository) CreateRound(tournamentID, topicID, roundNumber int, roundDate time.Time) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO раунды (ид_турнира, ид_темы, номер_раунда, дата_раунда) VALUES ($1, $2, $3, $4) RETURNING id",
		tournamentID, topicID, roundNumber, roundDate,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetRounds() ([]models.Round, error) {
	rows, err := r.db.Query(`
		SELECT id, ид_турнира, ид_темы, номер_раунда, дата_раунда, дата_создания 
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
		SELECT id, ид_турнира, ид_темы, номер_раунда, дата_раунда, дата_создания 
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
	err := r.db.QueryRow("SELECT id, ид_турнира, ид_темы, номер_раунда, дата_раунда, дата_создания FROM раунды WHERE id = $1", id).
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
		"UPDATE раунды SET ид_турнира = $1, ид_темы = $2, номер_раунда = $3, дата_раунда = $4 WHERE id = $5",
		tournamentID, topicID, roundNumber, roundDate, id,
	)
	return err
}

func (r *Repository) DeleteRound(id int) error {
	_, err := r.db.Exec("DELETE FROM раунды WHERE id = $1", id)
	return err
}

// Выступления
func (r *Repository) CreatePerformance(roundID, participantID int, positionCode string, logicScore, rhetoricScore, eruditionScore *int, judgeID int) (int, error) {
	// Получаем ид_позиции по коду ('for' или 'against')
	var positionID int
	err := r.db.QueryRow("SELECT id FROM позиции_дебатов WHERE код = $1", positionCode).Scan(&positionID)
	if err != nil {
		return 0, err
	}
	
	var id int
	err = r.db.QueryRow(
		`INSERT INTO выступления (ид_раунда, ид_участника, ид_позиции, оценка_логики, оценка_риторики, оценка_эрудиции, ид_судьи) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
		roundID, participantID, positionID, logicScore, rhetoricScore, eruditionScore, judgeID,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetPerformances() ([]models.Performance, error) {
	rows, err := r.db.Query(`
		SELECT 
			perf.id, 
			perf.ид_раунда, 
			perf.ид_участника, 
			perf.ид_позиции,
			dp.код as position_code,
			dp.название as position_name,
			perf.оценка_логики, 
			perf.оценка_риторики, 
			perf.оценка_эрудиции, 
			perf.ид_судьи, 
			perf.дата_создания 
		FROM выступления perf
		LEFT JOIN позиции_дебатов dp ON perf.ид_позиции = dp.id
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
		"UPDATE выступления SET оценка_логики = $1, оценка_риторики = $2, оценка_эрудиции = $3 WHERE id = $4",
		logicScore, rhetoricScore, eruditionScore, id,
	)
	return err
}

func (r *Repository) DeletePerformance(id int) error {
	_, err := r.db.Exec("DELETE FROM выступления WHERE id = $1", id)
	return err
}

// Запрос а) Список всех участников турнира с указанием их команды по каждой теме
func (r *Repository) GetTournamentParticipants(tournamentID int) ([]models.TournamentParticipant, error) {
	query := `
		SELECT DISTINCT
			p.id as ид_участника,
			p.имя as имя,
			p.фамилия as фамилия,
			t.id as ид_темы,
			t.заголовок as topic_title,
			dp.название as position
		FROM участники p
		JOIN выступления perf ON p.id = perf.ид_участника
		JOIN раунды r ON perf.ид_раунда = r.id
		JOIN темы t ON r.ид_темы = t.id
		JOIN позиции_дебатов dp ON perf.ид_позиции = dp.id
		WHERE r.ид_турнира = $1
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
			p.id as ид_участника,
			p.имя as имя,
			p.фамилия as фамилия,
			COALESCE(SUM(расчет_итогового_балла(perf.оценка_логики, perf.оценка_риторики, perf.оценка_эрудиции)), 0) as total_score
		FROM участники p
		JOIN выступления perf ON p.id = perf.ид_участника
		JOIN раунды r ON perf.ид_раунда = r.id
		WHERE r.ид_турнира = $1
		GROUP BY p.id, p.имя, p.фамилия
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
		),
		round_winners AS (
			SELECT DISTINCT ON (rs.ид_темы, rs.ид_раунда)
				rs.ид_темы,
				rs.ид_раунда,
				rs.position_code,
				rs.team_score
			FROM round_scores rs
			WHERE rs.team_score = (
				SELECT MAX(rs2.team_score)
				FROM round_scores rs2
				WHERE rs2.ид_темы = rs.ид_темы 
				  AND rs2.ид_раунда = rs.ид_раунда
			)
			ORDER BY rs.ид_темы, rs.ид_раунда, rs.team_score DESC, rs.position_code
		),
		wins_by_position AS (
			SELECT 
				ид_темы,
				COUNT(CASE WHEN position_code = 'for' THEN 1 END) as for_wins,
				COUNT(CASE WHEN position_code = 'against' THEN 1 END) as against_wins
			FROM round_winners
			GROUP BY ид_темы
		)
		SELECT 
			t.id as ид_темы,
			t.заголовок as topic_title,
			COALESCE(w.for_wins, 0) as for_wins,
			COALESCE(w.against_wins, 0) as against_wins
		FROM темы t
		LEFT JOIN wins_by_position w ON t.id = w.ид_темы
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
			p.id as ид_участника,
			p.имя as имя,
			p.фамилия as фамилия,
			COALESCE(SUM(расчет_итогового_балла(perf.оценка_логики, perf.оценка_риторики, perf.оценка_эрудиции)), 0) as total_score
		FROM участники p
		INNER JOIN выступления perf ON p.id = perf.ид_участника
		INNER JOIN раунды r ON perf.ид_раунда = r.id
		INNER JOIN турниры t ON r.ид_турнира = t.id
		WHERE t.ид_сезона = $1
		GROUP BY p.id, p.имя, p.фамилия
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
			p.id as ид_участника,
			p.имя as имя,
			p.фамилия as фамилия,
			ROUND(AVG(perf.оценка_логики)::numeric, 2) as avg_logic,
			ROUND(AVG(perf.оценка_риторики)::numeric, 2) as avg_rhetoric,
			ROUND(AVG(perf.оценка_эрудиции)::numeric, 2) as avg_erudition
		FROM участники p
		LEFT JOIN выступления perf ON p.id = perf.ид_участника
		WHERE perf.оценка_логики IS NOT NULL 
		  AND perf.оценка_риторики IS NOT NULL 
		  AND perf.оценка_эрудиции IS NOT NULL
		GROUP BY p.id, p.имя, p.фамилия
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
			j.id as ид_судьи,
			j.имя as имя,
			j.фамилия as фамилия,
			COUNT(DISTINCT r.ид_турнира) as count
		FROM жюри j
		JOIN выступления perf ON j.id = perf.ид_судьи
		JOIN раунды r ON perf.ид_раунда = r.id
		GROUP BY j.id, j.имя, j.фамилия
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
			t.id as ид_темы,
			t.заголовок as topic_title,
			COUNT(DISTINCT r.ид_турнира) as usage_count
		FROM темы t
		JOIN раунды r ON t.id = r.ид_темы
		JOIN турниры tour ON r.ид_турнира = tour.id
		WHERE tour.ид_сезона = $1
		GROUP BY t.id, t.заголовок
		HAVING COUNT(DISTINCT r.ид_турнира) > 1
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
			r.номер_раунда,
			r.дата_раунда,
			t.заголовок as topic_title,
			STRING_AGG(
				p.имя || ' ' || p.фамилия || ' (' || dp.название || ')',
				', '
				ORDER BY dp.код, p.фамилия
			) as участники
		FROM раунды r
		JOIN темы t ON r.ид_темы = t.id
		LEFT JOIN выступления perf ON r.id = perf.ид_раунда
		LEFT JOIN участники p ON perf.ид_участника = p.id
		LEFT JOIN позиции_дебатов dp ON perf.ид_позиции = dp.id
		WHERE r.ид_турнира = $1
		GROUP BY r.номер_раунда, r.дата_раунда, t.заголовок
		ORDER BY r.номер_раунда
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
		SELECT DISTINCT p.id, p.имя, p.фамилия, p.электронная_почта, p.дата_создания
		FROM участники p
		JOIN выступления perf ON p.id = perf.ид_участника
		JOIN раунды r ON perf.ид_раунда = r.id
		JOIN турниры t ON r.ид_турнира = t.id
		WHERE t.ид_сезона = $1
		ORDER BY p.фамилия, p.имя
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
			t.ид_сезона, 
			t.название, 
			t.дата_начала, 
			t.дата_окончания, 
			t.ид_статуса,
			ts.код as status_code,
			ts.название as status_name,
			t.дата_создания 
		FROM турниры t
		LEFT JOIN статусы_турниров ts ON t.ид_статуса = ts.id
		WHERE t.ид_сезона = $1 
		ORDER BY t.дата_начала
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
		SELECT DISTINCT p.id, p.имя, p.фамилия, p.электронная_почта, p.дата_создания
		FROM участники p
		JOIN выступления perf ON p.id = perf.ид_участника
		WHERE perf.ид_раунда = $1
		ORDER BY p.фамилия, p.имя
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
		// Если функция не существует, используем прямой UPDATE с JOIN на статусы_турниров
		_, err = r.db.Exec(`
			WITH status_ids AS (
				SELECT 
					id as upcoming_id,
					(SELECT id FROM статусы_турниров WHERE код = 'active') as active_id,
					(SELECT id FROM статусы_турниров WHERE код = 'completed') as completed_id
				FROM статусы_турниров WHERE код = 'upcoming'
				LIMIT 1
			)
			UPDATE турниры t
			SET ид_статуса = CASE
				WHEN t.дата_окончания IS NOT NULL AND t.дата_окончания < CURRENT_DATE THEN (SELECT completed_id FROM status_ids)
				WHEN t.дата_начала <= CURRENT_DATE AND (t.дата_окончания IS NULL OR t.дата_окончания >= CURRENT_DATE) THEN (SELECT active_id FROM status_ids)
				ELSE (SELECT upcoming_id FROM status_ids)
			END
		`)
	}
	return err
}

// Регистрации на турнир
func (r *Repository) RegisterParticipantForTournament(tournamentID, participantID, positionID int) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO регистрации_на_турнир (ид_турнира, ид_участника, ид_позиции) VALUES ($1, $2, $3) RETURNING id",
		tournamentID, participantID, positionID,
	).Scan(&id)
	return id, err
}

func (r *Repository) GetTournamentRegistrations(tournamentID int) ([]models.TournamentRegistration, error) {
	rows, err := r.db.Query(`
		SELECT 
			r.id,
			r.ид_турнира,
			r.ид_участника,
			r.ид_позиции,
			dp.код as position_code,
			dp.название as position_name,
			r.дата_регистрации
		FROM регистрации_на_турнир r
		LEFT JOIN позиции_дебатов dp ON r.ид_позиции = dp.id
		WHERE r.ид_турнира = $1
		ORDER BY r.дата_регистрации
	`, tournamentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var registrations []models.TournamentRegistration
	for rows.Next() {
		var reg models.TournamentRegistration
		var positionCode, positionName sql.NullString
		if err := rows.Scan(&reg.ID, &reg.TournamentID, &reg.ParticipantID, &reg.PositionID, &positionCode, &positionName, &reg.RegisteredAt); err != nil {
			return nil, err
		}
		if positionCode.Valid && positionName.Valid {
			reg.Position = &models.DebatePosition{
				ID:   reg.PositionID,
				Code: positionCode.String,
				Name: positionName.String,
			}
		}
		registrations = append(registrations, reg)
	}
	return registrations, rows.Err()
}

func (r *Repository) UnregisterParticipantFromTournament(tournamentID, participantID int) error {
	_, err := r.db.Exec(
		"DELETE FROM регистрации_на_турнир WHERE ид_турнира = $1 AND ид_участника = $2",
		tournamentID, participantID,
	)
	return err
}

func (r *Repository) GetRegistrationCountsByPosition(tournamentID int) (forCount, againstCount int, err error) {
	var forID, againstID int
	err = r.db.QueryRow("SELECT id FROM позиции_дебатов WHERE код = 'for'").Scan(&forID)
	if err != nil {
		return 0, 0, err
	}
	err = r.db.QueryRow("SELECT id FROM позиции_дебатов WHERE код = 'against'").Scan(&againstID)
	if err != nil {
		return 0, 0, err
	}
	
	err = r.db.QueryRow(`
		SELECT 
			COUNT(CASE WHEN ид_позиции = $1 THEN 1 END) as for_count,
			COUNT(CASE WHEN ид_позиции = $2 THEN 1 END) as against_count
		FROM регистрации_на_турнир
		WHERE ид_турнира = $3
	`, forID, againstID, tournamentID).Scan(&forCount, &againstCount)
	return forCount, againstCount, err
}

func (r *Repository) GetTotalRegistrationCount(tournamentID int) (int, error) {
	var count int
	err := r.db.QueryRow(
		"SELECT COUNT(DISTINCT ид_участника) FROM регистрации_на_турнир WHERE ид_турнира = $1",
		tournamentID,
	).Scan(&count)
	return count, err
}

// Проверить и обработать турнир (перенос при недостатке участников, перераспределение)
func (r *Repository) CheckAndProcessTournament(tournamentID int) (moved bool, redistributed bool, err error) {
	// Проверяем и переносим, если нужно
	var movedResult bool
	err = r.db.QueryRow("SELECT проверить_и_перенести_турнир($1)", tournamentID).Scan(&movedResult)
	if err != nil {
		return false, false, err
	}
	
	if movedResult {
		return true, false, nil
	}
	
	// Если не перенесен, проверяем перераспределение
	// Функция перераспределить_участников_турнира ничего не возвращает,
	// но она выполнит перераспределение, если нужно
	_, err = r.db.Exec("SELECT перераспределить_участников_турнира($1)", tournamentID)
	if err != nil {
		return false, false, err
	}
	
	// Перераспределение выполняется автоматически функцией, если условия выполнены
	// Возвращаем false для redistributed, так как мы не можем точно определить, было ли оно
	// В реальности перераспределение происходит только при определенных условиях
	return false, false, nil
}

// Обработать все турниры, которые начинаются сегодня или завтра
func (r *Repository) ProcessUpcomingTournaments() error {
	_, err := r.db.Exec("SELECT обработать_турниры_в_день_начала()")
	return err
}
