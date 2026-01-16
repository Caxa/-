package models

import "time"

// Справочные таблицы (Reference Tables)

type TournamentStatus struct {
	ID          int       `json:"id"`
	Code        string    `json:"code"`        // 'upcoming', 'active', 'completed'
	Name        string    `json:"name"`        // 'Предстоящий', 'Активный', 'Завершен'
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

type DebatePosition struct {
	ID          int       `json:"id"`
	Code        string    `json:"code"`        // 'for', 'against'
	Name        string    `json:"name"`        // 'За', 'Против'
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

// Основные таблицы (Main Tables)

type Participant struct {
	ID        int       `json:"id"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

type Judge struct {
	ID        int       `json:"id"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

type Topic struct {
	ID          int       `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

type Season struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	StartDate time.Time `json:"start_date"`
	EndDate   time.Time `json:"end_date"`
	CreatedAt time.Time `json:"created_at"`
}

type Tournament struct {
	ID        int       `json:"id"`
	SeasonID  int       `json:"season_id"`
	Name      string    `json:"name"`
	StartDate time.Time `json:"start_date"`
	EndDate   *time.Time `json:"end_date,omitempty"`
	StatusID  int       `json:"status_id"` // Ссылка на tournament_statuses
	Status    *TournamentStatus `json:"status,omitempty"` // Загружается отдельно
	CreatedAt time.Time `json:"created_at"`
}

type Round struct {
	ID          int       `json:"id"`
	TournamentID int      `json:"tournament_id"`
	TopicID     int       `json:"topic_id"`
	RoundNumber int       `json:"round_number"`
	RoundDate   time.Time `json:"round_date"`
	CreatedAt   time.Time `json:"created_at"`
}

type TournamentRegistration struct {
	ID            int       `json:"id"`
	TournamentID  int       `json:"tournament_id"`
	ParticipantID int       `json:"participant_id"`
	PositionID    int       `json:"position_id"` // Ссылка на debate_positions
	Position      *DebatePosition `json:"position,omitempty"` // Загружается отдельно
	RegisteredAt  time.Time `json:"registered_at"`
}

type Performance struct {
	ID             int    `json:"id"`
	RoundID        int    `json:"round_id"`
	ParticipantID  int    `json:"participant_id"`
	PositionID     int    `json:"position_id"` // Ссылка на debate_positions
	Position       *DebatePosition `json:"position,omitempty"` // Загружается отдельно
	LogicScore     *int   `json:"logic_score"`
	RhetoricScore  *int   `json:"rhetoric_score"`
	EruditionScore *int   `json:"erudition_score"`
	JudgeID        int    `json:"judge_id"`
	CreatedAt      time.Time `json:"created_at"`
}

type TournamentParticipant struct {
	ParticipantID int    `json:"participant_id"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	TopicID       int    `json:"topic_id"`
	TopicTitle    string `json:"topic_title"`
	Position      string `json:"position"`
}

type TournamentResult struct {
	Place         int    `json:"place"`
	ParticipantID int    `json:"participant_id"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	TotalScore    int    `json:"total_score"`
}

type TopicWinStats struct {
	TopicID    int    `json:"topic_id"`
	TopicTitle string `json:"topic_title"`
	ForWins    int    `json:"for_wins"`
	AgainstWins int  `json:"against_wins"`
}

type ParticipantRating struct {
	ParticipantID int    `json:"participant_id"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	TotalScore    int    `json:"total_score"`
}

type AverageScores struct {
	ParticipantID int     `json:"participant_id"`
	FirstName     string  `json:"first_name"`
	LastName      string  `json:"last_name"`
	AvgLogic      float64 `json:"avg_logic"`
	AvgRhetoric   float64 `json:"avg_rhetoric"`
	AvgErudition  float64 `json:"avg_erudition"`
}

type JudgeTournamentCount struct {
	JudgeID   int    `json:"judge_id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Count     int    `json:"count"`
}

type RepeatedTopic struct {
	TopicID    int    `json:"topic_id"`
	TopicTitle string `json:"topic_title"`
	UsageCount int    `json:"usage_count"`
}

type TournamentSchedule struct {
	RoundNumber int       `json:"round_number"`
	RoundDate   time.Time `json:"round_date"`
	TopicTitle  string    `json:"topic_title"`
	Participants string   `json:"participants"`
}

// Дополнительные структуры для запросов
type ParticipantAudit struct {
	ID           int       `json:"id"`
	ParticipantID int      `json:"participant_id"`
	Action       string    `json:"action"` // 'INSERT', 'UPDATE', 'DELETE'
	ChangeDate   time.Time `json:"change_date"`
	OldData      string    `json:"old_data"` // JSONB as string
	NewData      string    `json:"new_data"` // JSONB as string
}
