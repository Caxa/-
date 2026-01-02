package handlers

import (
	"debate-club/internal/models"
	"debate-club/internal/repository"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"
)

type Handlers struct {
	repo      *repository.Repository
	templates *template.Template
}

func NewHandlers(repo *repository.Repository) (*Handlers, error) {
	tmpl, err := template.New("").Funcs(template.FuncMap{
		"add":    func(a, b int) int { return a + b },
		"sub":    func(a, b int) int { return a - b },
		"printf": fmt.Sprintf,
		"getMapValue": func(m map[int]int, key int) int {
			if m == nil {
				return 0
			}
			if val, ok := m[key]; ok {
				return val
			}
			return 0
		},
	}).ParseGlob("templates/*.html")
	if err != nil {
		return nil, err
	}

	return &Handlers{
		repo:      repo,
		templates: tmpl,
	}, nil
}

func (h *Handlers) Home(w http.ResponseWriter, r *http.Request) {
	// Получаем статистику для дашборда
	participants, _ := h.repo.GetParticipants()
	judges, _ := h.repo.GetJudges()
	topics, _ := h.repo.GetTopics()
	seasons, _ := h.repo.GetSeasons()
	tournaments, _ := h.repo.GetTournaments()
	rounds, _ := h.repo.GetRounds()
	performances, _ := h.repo.GetPerformances()

	// Убеждаемся, что все массивы не nil
	if participants == nil {
		participants = []models.Participant{}
	}
	if judges == nil {
		judges = []models.Judge{}
	}
	if topics == nil {
		topics = []models.Topic{}
	}
	if seasons == nil {
		seasons = []models.Season{}
	}
	if tournaments == nil {
		tournaments = []models.Tournament{}
	}
	if rounds == nil {
		rounds = []models.Round{}
	}
	if performances == nil {
		performances = []models.Performance{}
	}

	data := map[string]interface{}{
		"Stats": map[string]int{
			"Participants": len(participants),
			"Judges":        len(judges),
			"Topics":        len(topics),
			"Seasons":       len(seasons),
			"Tournaments":   len(tournaments),
			"Rounds":        len(rounds),
			"Performances":  len(performances),
		},
	}
	
	if err := h.templates.ExecuteTemplate(w, "index.html", data); err != nil {
		log.Printf("Template error: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

// Участники
func (h *Handlers) ParticipantsList(w http.ResponseWriter, r *http.Request) {
	participants, err := h.repo.GetParticipants()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Получаем средние оценки для участников
	avgScores, _ := h.repo.GetAverageScores()
	avgScoresMap := make(map[int]models.AverageScores)
	for _, as := range avgScores {
		avgScoresMap[as.ParticipantID] = as
	}
	
	// Убеждаемся, что participants не nil
	if participants == nil {
		participants = []models.Participant{}
	}
	
	// Фильтрация и поиск
	search := r.URL.Query().Get("search")
	filtered := participants
	if search != "" {
		filtered = []models.Participant{}
		searchLower := strings.ToLower(search)
		for _, p := range participants {
			if strings.Contains(strings.ToLower(p.FirstName), searchLower) ||
				strings.Contains(strings.ToLower(p.LastName), searchLower) ||
				strings.Contains(strings.ToLower(p.Email), searchLower) {
				filtered = append(filtered, p)
			}
		}
	}
	
	// Убеждаемся, что filtered не nil
	if filtered == nil {
		filtered = []models.Participant{}
	}
	
	// Получаем сообщения об ошибках/успехе из URL
	errorMsg := ""
	successMsg := ""
	if r.URL.Query().Get("error") == "email_exists" {
		email := r.URL.Query().Get("email")
		errorMsg = fmt.Sprintf("Ошибка: Email '%s' уже используется другим участником. Пожалуйста, используйте другой email.", email)
	}
	if r.URL.Query().Get("success") == "created" {
		successMsg = "Участник успешно добавлен!"
	}
	if r.URL.Query().Get("success") == "updated" {
		successMsg = "Участник успешно обновлен!"
	}
	
	data := map[string]interface{}{
		"Participants": filtered,
		"Search":       search,
		"TotalCount":   len(participants),
		"FilteredCount": len(filtered),
		"AvgScores":    avgScoresMap,
		"ErrorMsg":     errorMsg,
		"SuccessMsg":   successMsg,
	}
	if err := h.templates.ExecuteTemplate(w, "participants.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) CreateParticipant(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		firstName := r.FormValue("first_name")
		lastName := r.FormValue("last_name")
		email := r.FormValue("email")

		_, err := h.repo.CreateParticipant(firstName, lastName, email)
		if err != nil {
			// Проверяем, является ли ошибка нарушением уникального ограничения
			if strings.Contains(err.Error(), "duplicate key value violates unique constraint") || 
		   strings.Contains(err.Error(), "участники_электронная_почта_уникальна") {
				http.Redirect(w, r, "/participants?error=email_exists&email="+email, http.StatusSeeOther)
				return
			}
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/participants?success=created", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/participants", http.StatusSeeOther)
}

func (h *Handlers) UpdateParticipant(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		firstName := r.FormValue("first_name")
		lastName := r.FormValue("last_name")
		email := r.FormValue("email")

		if err := h.repo.UpdateParticipant(id, firstName, lastName, email); err != nil {
			// Проверяем, является ли ошибка нарушением уникального ограничения
			if strings.Contains(err.Error(), "duplicate key value violates unique constraint") || 
		   strings.Contains(err.Error(), "участники_электронная_почта_уникальна") {
				http.Redirect(w, r, fmt.Sprintf("/participants?error=email_exists&email=%s&id=%d", email, id), http.StatusSeeOther)
				return
			}
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/participants?success=updated", http.StatusSeeOther)
		return
	}
	// GET - показать форму редактирования
	participants, err := h.repo.GetParticipants()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var participant *models.Participant
	for _, p := range participants {
		if p.ID == id {
			participant = &p
			break
		}
	}
	if participant == nil {
		http.Error(w, "Participant not found", http.StatusNotFound)
		return
	}
	data := map[string]interface{}{
		"Participant":  participant,
		"Participants": participants,
		"Search":       "",
		"TotalCount":   len(participants),
		"FilteredCount": len(participants),
	}
	if err := h.templates.ExecuteTemplate(w, "participants.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) DeleteParticipant(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeleteParticipant(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/participants", http.StatusSeeOther)
}

// Жюри
func (h *Handlers) JudgesList(w http.ResponseWriter, r *http.Request) {
	judges, err := h.repo.GetJudges()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Получаем количество турниров для каждого жюри
	judgesByTournament, _ := h.repo.GetJudgesByTournamentCount()
	judgeTournamentCount := make(map[int]int)
	for _, jtc := range judgesByTournament {
		judgeTournamentCount[jtc.JudgeID] = jtc.Count
	}
	
	// Убеждаемся, что judges не nil
	if judges == nil {
		judges = []models.Judge{}
	}
	
	// Фильтрация и поиск
	search := r.URL.Query().Get("search")
	filtered := judges
	if search != "" {
		filtered = []models.Judge{}
		searchLower := strings.ToLower(search)
		for _, j := range judges {
			if strings.Contains(strings.ToLower(j.FirstName), searchLower) ||
				strings.Contains(strings.ToLower(j.LastName), searchLower) ||
				strings.Contains(strings.ToLower(j.Email), searchLower) {
				filtered = append(filtered, j)
			}
		}
	}
	
	// Убеждаемся, что filtered не nil
	if filtered == nil {
		filtered = []models.Judge{}
	}
	
	// Получаем сообщения об ошибках/успехе из URL
	errorMsg := ""
	successMsg := ""
	if r.URL.Query().Get("error") == "email_exists" {
		email := r.URL.Query().Get("email")
		errorMsg = fmt.Sprintf("Ошибка: Email '%s' уже используется другим членом жюри. Пожалуйста, используйте другой email.", email)
	}
	if r.URL.Query().Get("success") == "created" {
		successMsg = "Член жюри успешно добавлен!"
	}
	if r.URL.Query().Get("success") == "updated" {
		successMsg = "Член жюри успешно обновлен!"
	}
	
	data := map[string]interface{}{
		"Judges":              filtered,
		"Search":              search,
		"TotalCount":          len(judges),
		"FilteredCount":       len(filtered),
		"JudgeTournamentCount": judgeTournamentCount,
		"ErrorMsg":            errorMsg,
		"SuccessMsg":          successMsg,
	}
	if err := h.templates.ExecuteTemplate(w, "judges.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) CreateJudge(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		firstName := r.FormValue("first_name")
		lastName := r.FormValue("last_name")
		email := r.FormValue("email")

		_, err := h.repo.CreateJudge(firstName, lastName, email)
		if err != nil {
			// Проверяем, является ли ошибка нарушением уникального ограничения
			if strings.Contains(err.Error(), "duplicate key value violates unique constraint") || 
		   strings.Contains(err.Error(), "жюри_электронная_почта_уникальна") {
				http.Redirect(w, r, "/judges?error=email_exists&email="+email, http.StatusSeeOther)
				return
			}
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/judges?success=created", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/judges", http.StatusSeeOther)
}

func (h *Handlers) UpdateJudge(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		firstName := r.FormValue("first_name")
		lastName := r.FormValue("last_name")
		email := r.FormValue("email")

		if err := h.repo.UpdateJudge(id, firstName, lastName, email); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/judges", http.StatusSeeOther)
		return
	}
	// GET - показать форму редактирования
	judges, err := h.repo.GetJudges()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var judge *models.Judge
	for _, j := range judges {
		if j.ID == id {
			judge = &j
			break
		}
	}
	if judge == nil {
		http.Error(w, "Judge not found", http.StatusNotFound)
		return
	}
	data := map[string]interface{}{
		"Judge":        judge,
		"Judges":       judges,
		"Search":       "",
		"TotalCount":   len(judges),
		"FilteredCount": len(judges),
	}
	if err := h.templates.ExecuteTemplate(w, "judges.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) DeleteJudge(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeleteJudge(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/judges", http.StatusSeeOther)
}

// Темы
func (h *Handlers) TopicsList(w http.ResponseWriter, r *http.Request) {
	topics, err := h.repo.GetTopics()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Получаем статистику побед по темам
	topicsWinStats, _ := h.repo.GetTopicsWhereAgainstWins()
	topicsWinStatsMap := make(map[int]models.TopicWinStats)
	for _, tws := range topicsWinStats {
		topicsWinStatsMap[tws.TopicID] = tws
	}
	
	// Убеждаемся, что topics не nil
	if topics == nil {
		topics = []models.Topic{}
	}
	
	// Фильтрация и поиск
	search := r.URL.Query().Get("search")
	filtered := topics
	if search != "" {
		filtered = []models.Topic{}
		searchLower := strings.ToLower(search)
		for _, t := range topics {
			if strings.Contains(strings.ToLower(t.Title), searchLower) ||
				strings.Contains(strings.ToLower(t.Description), searchLower) {
				filtered = append(filtered, t)
			}
		}
	}
	
	// Убеждаемся, что filtered не nil
	if filtered == nil {
		filtered = []models.Topic{}
	}
	
	data := map[string]interface{}{
		"Topics":         filtered,
		"Search":         search,
		"TotalCount":     len(topics),
		"FilteredCount":  len(filtered),
		"TopicsWinStats": topicsWinStatsMap,
	}
	if err := h.templates.ExecuteTemplate(w, "topics.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) CreateTopic(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		title := r.FormValue("title")
		description := r.FormValue("description")

		_, err := h.repo.CreateTopic(title, description)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/topics", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/topics", http.StatusSeeOther)
}

func (h *Handlers) UpdateTopic(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		title := r.FormValue("title")
		description := r.FormValue("description")

		if err := h.repo.UpdateTopic(id, title, description); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/topics", http.StatusSeeOther)
		return
	}
	// GET - показать форму редактирования
	topics, err := h.repo.GetTopics()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var topic *models.Topic
	for _, t := range topics {
		if t.ID == id {
			topic = &t
			break
		}
	}
	if topic == nil {
		http.Error(w, "Topic not found", http.StatusNotFound)
		return
	}
	data := map[string]interface{}{
		"Topic":        topic,
		"Topics":       topics,
		"Search":       "",
		"TotalCount":   len(topics),
		"FilteredCount": len(topics),
	}
	if err := h.templates.ExecuteTemplate(w, "topics.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) DeleteTopic(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeleteTopic(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/topics", http.StatusSeeOther)
}

// Сезоны
func (h *Handlers) SeasonsList(w http.ResponseWriter, r *http.Request) {
	seasons, err := h.repo.GetSeasons()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Получаем рейтинг участников для каждого сезона
	seasonRatings := make(map[int][]models.ParticipantRating)
	for _, s := range seasons {
		rating, _ := h.repo.GetParticipantRatingForSeason(s.ID)
		if len(rating) > 0 {
			seasonRatings[s.ID] = rating[:min(3, len(rating))] // Топ-3
		}
	}
	
	// Убеждаемся, что seasons не nil
	if seasons == nil {
		seasons = []models.Season{}
	}
	
	// Фильтрация и поиск
	search := r.URL.Query().Get("search")
	filtered := seasons
	if search != "" {
		filtered = []models.Season{}
		searchLower := strings.ToLower(search)
		for _, s := range seasons {
			if strings.Contains(strings.ToLower(s.Name), searchLower) {
				filtered = append(filtered, s)
			}
		}
	}
	
	// Убеждаемся, что filtered не nil
	if filtered == nil {
		filtered = []models.Season{}
	}
	
	data := map[string]interface{}{
		"Seasons":       filtered,
		"Search":        search,
		"TotalCount":    len(seasons),
		"FilteredCount": len(filtered),
		"SeasonRatings": seasonRatings,
	}
	if err := h.templates.ExecuteTemplate(w, "seasons.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func (h *Handlers) CreateSeason(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		name := r.FormValue("name")
		startDate, _ := time.Parse("2006-01-02", r.FormValue("start_date"))
		endDate, _ := time.Parse("2006-01-02", r.FormValue("end_date"))

		_, err := h.repo.CreateSeason(name, startDate, endDate)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/seasons", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/seasons", http.StatusSeeOther)
}

func (h *Handlers) UpdateSeason(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		name := r.FormValue("name")
		startDate, _ := time.Parse("2006-01-02", r.FormValue("start_date"))
		endDate, _ := time.Parse("2006-01-02", r.FormValue("end_date"))

		if err := h.repo.UpdateSeason(id, name, startDate, endDate); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/seasons", http.StatusSeeOther)
		return
	}
	// GET - показать форму редактирования
	seasons, err := h.repo.GetSeasons()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var season *models.Season
	for _, s := range seasons {
		if s.ID == id {
			season = &s
			break
		}
	}
	if season == nil {
		http.Error(w, "Season not found", http.StatusNotFound)
		return
	}
	data := map[string]interface{}{
		"Seasons":      seasons,
		"Season":       season,
		"Search":       "",
		"TotalCount":   len(seasons),
		"FilteredCount": len(seasons),
	}
	if err := h.templates.ExecuteTemplate(w, "seasons.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) DeleteSeason(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeleteSeason(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/seasons", http.StatusSeeOther)
}

// Турниры
func (h *Handlers) TournamentsList(w http.ResponseWriter, r *http.Request) {
	// Обновляем статусы турниров перед отображением
	h.repo.UpdateAllTournamentStatuses()
	
	tournaments, err := h.repo.GetTournaments()
	if err != nil {
		log.Printf("Error getting tournaments: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	log.Printf("Retrieved %d tournaments from database", len(tournaments))
	
	seasons, _ := h.repo.GetSeasons()
	if tournaments == nil {
		tournaments = []models.Tournament{}
	}
	if seasons == nil {
		seasons = []models.Season{}
	}
	
	// Фильтрация и поиск
	search := r.URL.Query().Get("search")
	filtered := tournaments
	if search != "" {
		filtered = []models.Tournament{}
		searchLower := strings.ToLower(search)
		for _, t := range tournaments {
			if strings.Contains(strings.ToLower(t.Name), searchLower) ||
				strings.Contains(strings.ToLower(t.Status), searchLower) {
				filtered = append(filtered, t)
			}
		}
	}
	
	// Убеждаемся, что filtered не nil
	if filtered == nil {
		filtered = []models.Tournament{}
	}
	
	log.Printf("After filtering: %d tournaments", len(filtered))
	
	// Получаем количество раундов для отфильтрованных турниров
	tournamentRoundsCount := make(map[int]int)
	for _, t := range filtered {
		count, _ := h.repo.GetRoundsCountByTournament(t.ID)
		tournamentRoundsCount[t.ID] = count
	}
	
	data := map[string]interface{}{
		"Tournaments":        filtered,
		"Seasons":            seasons,
		"Search":             search,
		"TotalCount":         len(tournaments),
		"FilteredCount":      len(filtered),
		"TournamentRoundsCount": tournamentRoundsCount,
	}
	
	log.Printf("TournamentsList: Sending data to template: %d tournaments (filtered), %d seasons", len(filtered), len(seasons))
	log.Printf("TournamentsList: filtered is nil? %v, len=%d", filtered == nil, len(filtered))
	if len(filtered) > 0 {
		log.Printf("TournamentsList: First tournament: %+v", filtered[0])
	}
	
	if err := h.templates.ExecuteTemplate(w, "tournaments.html", data); err != nil {
		log.Printf("Template error: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (h *Handlers) CreateTournament(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		seasonID, _ := strconv.Atoi(r.FormValue("season_id"))
		name := r.FormValue("name")
		startDate, _ := time.Parse("2006-01-02", r.FormValue("start_date"))
		var endDate *time.Time
		if ed := r.FormValue("end_date"); ed != "" {
			parsed, _ := time.Parse("2006-01-02", ed)
			endDate = &parsed
		}

		_, err := h.repo.CreateTournament(seasonID, name, startDate, endDate)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/tournaments", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/tournaments", http.StatusSeeOther)
}

func (h *Handlers) UpdateTournament(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		seasonID, _ := strconv.Atoi(r.FormValue("season_id"))
		name := r.FormValue("name")
		startDate, _ := time.Parse("2006-01-02", r.FormValue("start_date"))
		var endDate *time.Time
		if ed := r.FormValue("end_date"); ed != "" {
			parsed, _ := time.Parse("2006-01-02", ed)
			endDate = &parsed
		}

		if err := h.repo.UpdateTournament(id, seasonID, name, startDate, endDate); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/tournaments", http.StatusSeeOther)
		return
	}
	// GET - показать форму редактирования
	tournaments, _ := h.repo.GetTournaments()
	seasons, _ := h.repo.GetSeasons()
	var tournament *models.Tournament
	for _, t := range tournaments {
		if t.ID == id {
			tournament = &t
			break
		}
	}
	if tournament == nil {
		http.Error(w, "Tournament not found", http.StatusNotFound)
		return
	}
	data := map[string]interface{}{
		"Tournaments":  tournaments,
		"Seasons":      seasons,
		"Tournament":   tournament,
		"Search":       "",
		"TotalCount":   len(tournaments),
		"FilteredCount": len(tournaments),
	}
	if err := h.templates.ExecuteTemplate(w, "tournaments.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) DeleteTournament(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeleteTournament(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/tournaments", http.StatusSeeOther)
}

func (h *Handlers) TournamentDetails(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	tournamentID, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if tournamentID == 0 {
		// Пытаемся извлечь ID из пути /tournaments/{id}/results или /tournaments/{id}/schedule
		parts := strings.Split(strings.Trim(path, "/"), "/")
		if len(parts) >= 2 {
			tournamentID, _ = strconv.Atoi(parts[1])
		}
	}
	
	if tournamentID == 0 {
		http.Error(w, "Tournament ID required", http.StatusBadRequest)
		return
	}
	
	tournaments, _ := h.repo.GetTournaments()
	var tournament *models.Tournament
	for _, t := range tournaments {
		if t.ID == tournamentID {
			tournament = &t
			break
		}
	}
	if tournament == nil {
		http.Error(w, "Tournament not found", http.StatusNotFound)
		return
	}
	
	if strings.Contains(path, "/results") {
		// Показываем результаты турнира
		results, _ := h.repo.GetTournamentResults(tournamentID)
		data := map[string]interface{}{
			"Tournament": tournament,
			"Results":    results,
			"Title":      "Итоговые результаты: " + tournament.Name,
		}
		if err := h.templates.ExecuteTemplate(w, "tournament_results.html", data); err != nil {
			log.Printf("Template error: %v", err)
		}
	} else if strings.Contains(path, "/schedule") {
		// Показываем расписание турнира
		schedule, _ := h.repo.GetTournamentSchedule(tournamentID)
		data := map[string]interface{}{
			"Tournament": tournament,
			"Schedule":   schedule,
			"Title":      "Расписание: " + tournament.Name,
		}
		if err := h.templates.ExecuteTemplate(w, "tournament_schedule.html", data); err != nil {
			log.Printf("Template error: %v", err)
		}
	} else {
		http.Error(w, "Invalid path", http.StatusBadRequest)
	}
}

// Раунды
func (h *Handlers) RoundsList(w http.ResponseWriter, r *http.Request) {
	rounds, err := h.repo.GetRounds()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	tournaments, _ := h.repo.GetTournaments()
	topics, _ := h.repo.GetTopics()
	
	// Поиск и фильтрация
	search := r.URL.Query().Get("search")
	filterTournament := r.URL.Query().Get("tournament")
	filterTopic := r.URL.Query().Get("topic")
	filterDateFrom := r.URL.Query().Get("date_from")
	filterDateTo := r.URL.Query().Get("date_to")
	
	var filtered []models.Round
	for _, round := range rounds {
		// Фильтр по турниру
		if filterTournament != "" {
			tournamentID, _ := strconv.Atoi(filterTournament)
			if round.TournamentID != tournamentID {
				continue
			}
		}
		
		// Фильтр по теме
		if filterTopic != "" {
			topicID, _ := strconv.Atoi(filterTopic)
			if round.TopicID != topicID {
				continue
			}
		}
		
		// Фильтр по дате от
		if filterDateFrom != "" {
			dateFrom, err := time.Parse("2006-01-02", filterDateFrom)
			if err == nil && round.RoundDate.Before(dateFrom) {
				continue
			}
		}
		
		// Фильтр по дате до
		if filterDateTo != "" {
			dateTo, err := time.Parse("2006-01-02", filterDateTo)
			if err == nil && round.RoundDate.After(dateTo) {
				continue
			}
		}
		
		// Текстовый поиск
		if search != "" {
			matched := false
			searchLower := strings.ToLower(search)
			// Поиск по названию турнира
			for _, t := range tournaments {
				if t.ID == round.TournamentID {
					if strings.Contains(strings.ToLower(t.Name), searchLower) {
						matched = true
						break
					}
				}
			}
			// Поиск по теме
			if !matched {
				for _, topic := range topics {
					if topic.ID == round.TopicID {
						if strings.Contains(strings.ToLower(topic.Title+" "+topic.Description), searchLower) {
							matched = true
							break
						}
					}
				}
			}
			// Поиск по номеру раунда
			if !matched {
				if strings.Contains(strings.ToLower(fmt.Sprintf("раунд %d", round.RoundNumber)), searchLower) {
					matched = true
				}
			}
			if !matched {
				continue
			}
		}
		
		filtered = append(filtered, round)
	}
	
	// Убеждаемся, что все массивы не nil
	if filtered == nil {
		filtered = []models.Round{}
	}
	if tournaments == nil {
		tournaments = []models.Tournament{}
	}
	if topics == nil {
		topics = []models.Topic{}
	}
	
	data := map[string]interface{}{
		"Rounds":           filtered,
		"Tournaments":      tournaments,
		"Topics":           topics,
		"Search":           search,
		"FilterTournament": filterTournament,
		"FilterTopic":      filterTopic,
		"FilterDateFrom":   filterDateFrom,
		"FilterDateTo":     filterDateTo,
		"TotalCount":       len(rounds),
		"FilteredCount":    len(filtered),
	}
	if err := h.templates.ExecuteTemplate(w, "rounds.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) CreateRound(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		tournamentID, _ := strconv.Atoi(r.FormValue("tournament_id"))
		topicID, _ := strconv.Atoi(r.FormValue("topic_id"))
		roundNumber, _ := strconv.Atoi(r.FormValue("round_number"))
		roundDate, _ := time.Parse("2006-01-02", r.FormValue("round_date"))

		_, err := h.repo.CreateRound(tournamentID, topicID, roundNumber, roundDate)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/rounds", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/rounds", http.StatusSeeOther)
}

func (h *Handlers) UpdateRound(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		tournamentID, _ := strconv.Atoi(r.FormValue("tournament_id"))
		topicID, _ := strconv.Atoi(r.FormValue("topic_id"))
		roundNumber, _ := strconv.Atoi(r.FormValue("round_number"))
		roundDate, _ := time.Parse("2006-01-02", r.FormValue("round_date"))

		if err := h.repo.UpdateRound(id, tournamentID, topicID, roundNumber, roundDate); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/rounds", http.StatusSeeOther)
		return
	}
	// GET - показать форму редактирования
	rounds, _ := h.repo.GetRounds()
	tournaments, _ := h.repo.GetTournaments()
	topics, _ := h.repo.GetTopics()
	var round *models.Round
	for _, rd := range rounds {
		if rd.ID == id {
			round = &rd
			break
		}
	}
	if round == nil {
		http.Error(w, "Round not found", http.StatusNotFound)
		return
	}
	data := map[string]interface{}{
		"Rounds":      rounds,
		"Tournaments": tournaments,
		"Topics":      topics,
		"Round":       round,
		"EditMode":    true,
	}
	if err := h.templates.ExecuteTemplate(w, "rounds.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) DeleteRound(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeleteRound(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/rounds", http.StatusSeeOther)
}

// Выступления
func (h *Handlers) PerformancesList(w http.ResponseWriter, r *http.Request) {
	performances, err := h.repo.GetPerformances()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	participants, _ := h.repo.GetParticipants()
	judges, _ := h.repo.GetJudges()
	rounds, _ := h.repo.GetRounds()
	topics, _ := h.repo.GetTopics()
	tournaments, _ := h.repo.GetTournaments()
	seasons, _ := h.repo.GetSeasons()
	
	// Поиск и фильтрация
	search := r.URL.Query().Get("search")
	filterParticipant := r.URL.Query().Get("participant")
	filterTournament := r.URL.Query().Get("tournament")
	filterTopic := r.URL.Query().Get("topic")
	filterPosition := r.URL.Query().Get("position")
	filterJudge := r.URL.Query().Get("judge")
	
	var filtered []models.Performance
	for _, perf := range performances {
		// Поиск по участнику
		if filterParticipant != "" {
			participantID, _ := strconv.Atoi(filterParticipant)
			if perf.ParticipantID != participantID {
				continue
			}
		}
		
		// Поиск по турниру
		if filterTournament != "" {
			tournamentID, _ := strconv.Atoi(filterTournament)
			matched := false
			for _, round := range rounds {
				if round.ID == perf.RoundID && round.TournamentID == tournamentID {
					matched = true
					break
				}
			}
			if !matched {
				continue
			}
		}
		
		// Поиск по теме
		if filterTopic != "" {
			topicID, _ := strconv.Atoi(filterTopic)
			matched := false
			for _, round := range rounds {
				if round.ID == perf.RoundID && round.TopicID == topicID {
					matched = true
					break
				}
			}
			if !matched {
				continue
			}
		}
		
		// Фильтр по позиции
		if filterPosition != "" && perf.Position != filterPosition {
			continue
		}
		
		// Фильтр по жюри
		if filterJudge != "" {
			judgeID, _ := strconv.Atoi(filterJudge)
			if perf.JudgeID != judgeID {
				continue
			}
		}
		
		// Текстовый поиск
		if search != "" {
			matched := false
			searchLower := strings.ToLower(search)
			// Поиск по имени участника
			for _, p := range participants {
				if p.ID == perf.ParticipantID {
					if strings.Contains(strings.ToLower(p.FirstName+" "+p.LastName), searchLower) {
						matched = true
						break
					}
				}
			}
			// Поиск по названию турнира
			if !matched {
				for _, round := range rounds {
					if round.ID == perf.RoundID {
						for _, t := range tournaments {
							if t.ID == round.TournamentID {
								if strings.Contains(strings.ToLower(t.Name), searchLower) {
									matched = true
									break
								}
							}
						}
						break
					}
				}
			}
			// Поиск по теме
			if !matched {
				for _, round := range rounds {
					if round.ID == perf.RoundID {
						for _, topic := range topics {
							if topic.ID == round.TopicID {
								if strings.Contains(strings.ToLower(topic.Title+" "+topic.Description), searchLower) {
									matched = true
									break
								}
							}
						}
						break
					}
				}
			}
			if !matched {
				continue
			}
		}
		
		filtered = append(filtered, perf)
	}
	
	// Убеждаемся, что все массивы не nil
	if filtered == nil {
		filtered = []models.Performance{}
	}
	if participants == nil {
		participants = []models.Participant{}
	}
	if judges == nil {
		judges = []models.Judge{}
	}
	if rounds == nil {
		rounds = []models.Round{}
	}
	if topics == nil {
		topics = []models.Topic{}
	}
	if tournaments == nil {
		tournaments = []models.Tournament{}
	}
	if seasons == nil {
		seasons = []models.Season{}
	}
	
	data := map[string]interface{}{
		"Performances": filtered,
		"Participants": participants,
		"Judges":       judges,
		"Rounds":       rounds,
		"Topics":       topics,
		"Tournaments":  tournaments,
		"Seasons":      seasons,
		"Search":       search,
		"FilterParticipant": filterParticipant,
		"FilterTournament": filterTournament,
		"FilterTopic":      filterTopic,
		"FilterPosition":    filterPosition,
		"FilterJudge":       filterJudge,
		"TotalCount":        len(performances),
		"FilteredCount":     len(filtered),
	}
	if err := h.templates.ExecuteTemplate(w, "performances.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

func (h *Handlers) CreatePerformance(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		roundID, _ := strconv.Atoi(r.FormValue("round_id"))
		participantID, _ := strconv.Atoi(r.FormValue("participant_id"))
		position := r.FormValue("position")
		judgeID, _ := strconv.Atoi(r.FormValue("judge_id"))

		var logicScore, rhetoricScore, eruditionScore *int
		if ls := r.FormValue("logic_score"); ls != "" {
			val, _ := strconv.Atoi(ls)
			logicScore = &val
		}
		if rs := r.FormValue("rhetoric_score"); rs != "" {
			val, _ := strconv.Atoi(rs)
			rhetoricScore = &val
		}
		if es := r.FormValue("erudition_score"); es != "" {
			val, _ := strconv.Atoi(es)
			eruditionScore = &val
		}

		_, err := h.repo.CreatePerformance(roundID, participantID, position, logicScore, rhetoricScore, eruditionScore, judgeID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/performances", http.StatusSeeOther)
		return
	}
	http.Redirect(w, r, "/performances", http.StatusSeeOther)
}

func (h *Handlers) UpdatePerformance(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if r.Method == "POST" {
		var logicScore, rhetoricScore, eruditionScore *int
		if ls := r.FormValue("logic_score"); ls != "" {
			val, _ := strconv.Atoi(ls)
			logicScore = &val
		}
		if rs := r.FormValue("rhetoric_score"); rs != "" {
			val, _ := strconv.Atoi(rs)
			rhetoricScore = &val
		}
		if es := r.FormValue("erudition_score"); es != "" {
			val, _ := strconv.Atoi(es)
			eruditionScore = &val
		}

		if err := h.repo.UpdatePerformance(id, logicScore, rhetoricScore, eruditionScore); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/performances", http.StatusSeeOther)
		return
	}

	performances, _ := h.repo.GetPerformances()
	var performance *models.Performance
	for _, p := range performances {
		if p.ID == id {
			performance = &p
			break
		}
	}
	if performance == nil {
		http.Error(w, "Performance not found", http.StatusNotFound)
		return
	}
	http.Redirect(w, r, "/performances", http.StatusSeeOther)
}

func (h *Handlers) DeletePerformance(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	if err := h.repo.DeletePerformance(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/performances", http.StatusSeeOther)
}

// Запросы - все объединены в один handler Queries

func (h *Handlers) Queries(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q == "" {
		if err := h.templates.ExecuteTemplate(w, "queries.html", nil); err != nil {
			log.Printf("Template error: %v", err)
		}
		return
	}

	var results interface{}
	var title string
	var headers []string

	switch q {
	case "a":
		tournamentID, _ := strconv.Atoi(r.URL.Query().Get("tournament_id"))
		if tournamentID == 0 {
			tournaments, _ := h.repo.GetTournaments()
			data := map[string]interface{}{"Tournaments": tournaments, "Query": "a"}
			h.templates.ExecuteTemplate(w, "queries.html", data)
			return
		}
		participants, _ := h.repo.GetTournamentParticipants(tournamentID)
		title = "Участники турнира по темам"
		headers = []string{"ID", "Имя", "Фамилия", "Тема", "Позиция"}
		rows := make([][]interface{}, 0, len(participants))
		for _, p := range participants {
			rows = append(rows, []interface{}{p.ParticipantID, p.FirstName, p.LastName, p.TopicTitle, p.Position})
		}
		results = rows
	case "b":
		tournamentID, _ := strconv.Atoi(r.URL.Query().Get("tournament_id"))
		if tournamentID == 0 {
			tournaments, _ := h.repo.GetTournaments()
			data := map[string]interface{}{"Tournaments": tournaments, "Query": "b"}
			h.templates.ExecuteTemplate(w, "queries.html", data)
			return
		}
		tournamentResults, _ := h.repo.GetTournamentResults(tournamentID)
		title = "Итоговые результаты турнира"
		headers = []string{"Место", "Имя", "Фамилия", "Сумма баллов"}
		rows := make([][]interface{}, 0, len(tournamentResults))
		for _, tr := range tournamentResults {
			rows = append(rows, []interface{}{tr.Place, tr.FirstName, tr.LastName, tr.TotalScore})
		}
		results = rows
	case "c":
		topicsWin, _ := h.repo.GetTopicsWhereAgainstWins()
		title = "Темы, где побеждает «против»"
		headers = []string{"ID", "Тема", "Количество побед"}
		rows := make([][]interface{}, 0, len(topicsWin))
		for _, t := range topicsWin {
			rows = append(rows, []interface{}{t.TopicID, t.TopicTitle, t.AgainstWins})
		}
		results = rows
	case "d":
		seasonID, _ := strconv.Atoi(r.URL.Query().Get("season_id"))
		if seasonID == 0 {
			seasons, _ := h.repo.GetSeasons()
			data := map[string]interface{}{"Seasons": seasons, "Query": "d"}
			h.templates.ExecuteTemplate(w, "queries.html", data)
			return
		}
		ratings, _ := h.repo.GetParticipantRatingForSeason(seasonID)
		title = "Рейтинг участников за сезон"
		headers = []string{"Имя", "Фамилия", "Сумма баллов"}
		rows := make([][]interface{}, 0, len(ratings))
		for _, r := range ratings {
			rows = append(rows, []interface{}{r.FirstName, r.LastName, r.TotalScore})
		}
		results = rows
	case "e":
		avgScores, _ := h.repo.GetAverageScores()
		title = "Средние оценки по критериям"
		headers = []string{"Имя", "Фамилия", "Логика", "Риторика", "Эрудиция"}
		rows := make([][]interface{}, 0, len(avgScores))
		for _, a := range avgScores {
			rows = append(rows, []interface{}{a.FirstName, a.LastName, fmt.Sprintf("%.2f", a.AvgLogic), fmt.Sprintf("%.2f", a.AvgRhetoric), fmt.Sprintf("%.2f", a.AvgErudition)})
		}
		results = rows
	case "f":
		judgesCount, _ := h.repo.GetJudgesByTournamentCount()
		title = "Жюри по количеству турниров"
		headers = []string{"Имя", "Фамилия", "Количество турниров"}
		rows := make([][]interface{}, 0, len(judgesCount))
		for _, j := range judgesCount {
			rows = append(rows, []interface{}{j.FirstName, j.LastName, j.Count})
		}
		results = rows
	case "g":
		seasonID, _ := strconv.Atoi(r.URL.Query().Get("season_id"))
		if seasonID == 0 {
			seasons, _ := h.repo.GetSeasons()
			data := map[string]interface{}{"Seasons": seasons, "Query": "g"}
			h.templates.ExecuteTemplate(w, "queries.html", data)
			return
		}
		repeated, _ := h.repo.GetRepeatedTopicsInSeason(seasonID)
		title = "Повторяющиеся темы за сезон"
		headers = []string{"ID", "Тема", "Количество использований"}
		rows := make([][]interface{}, 0, len(repeated))
		for _, rt := range repeated {
			rows = append(rows, []interface{}{rt.TopicID, rt.TopicTitle, rt.UsageCount})
		}
		results = rows
	case "h":
		tournamentID, _ := strconv.Atoi(r.URL.Query().Get("tournament_id"))
		if tournamentID == 0 {
			tournaments, _ := h.repo.GetTournaments()
			data := map[string]interface{}{"Tournaments": tournaments, "Query": "h"}
			h.templates.ExecuteTemplate(w, "queries.html", data)
			return
		}
		schedule, _ := h.repo.GetTournamentSchedule(tournamentID)
		title = "Расписание турнира"
		headers = []string{"Раунд", "Дата", "Тема", "Участники"}
		rows := make([][]interface{}, 0, len(schedule))
		for _, s := range schedule {
			rows = append(rows, []interface{}{s.RoundNumber, s.RoundDate.Format("2006-01-02"), s.TopicTitle, s.Participants})
		}
		results = rows
	}

	data := map[string]interface{}{
		"Title":   title,
		"Headers": headers,
		"Results": results,
		"Query":   q,
	}
	if err := h.templates.ExecuteTemplate(w, "queries.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

// Детальная страница сезона
func (h *Handlers) SeasonDetails(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	season, _ := h.repo.GetSeasonByID(id)
	if season == nil {
		http.Error(w, "Season not found", http.StatusNotFound)
		return
	}
	
	participants, _ := h.repo.GetParticipantsBySeason(id)
	tournaments, _ := h.repo.GetTournamentsBySeason(id)
	
	// Получаем количество раундов для каждого турнира
	tournamentRoundsCount := make(map[int]int)
	for _, t := range tournaments {
		count, _ := h.repo.GetRoundsCountByTournament(t.ID)
		tournamentRoundsCount[t.ID] = count
	}
	
	data := map[string]interface{}{
		"Season":              season,
		"Participants":        participants,
		"Tournaments":         tournaments,
		"TournamentRoundsCount": tournamentRoundsCount,
	}
	if err := h.templates.ExecuteTemplate(w, "season_details.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

// Детальная страница турнира (раунды)
func (h *Handlers) TournamentDetailsPage(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	tournament, _ := h.repo.GetTournamentByID(id)
	if tournament == nil {
		http.Error(w, "Tournament not found", http.StatusNotFound)
		return
	}
	
	rounds, _ := h.repo.GetRoundsByTournament(id)
	topics, _ := h.repo.GetTopics()
	topicsMap := make(map[int]models.Topic)
	for _, t := range topics {
		topicsMap[t.ID] = t
	}
	
	data := map[string]interface{}{
		"Tournament": tournament,
		"Rounds":    rounds,
		"Topics":    topicsMap,
	}
	if err := h.templates.ExecuteTemplate(w, "tournament_details.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}

// Детальная страница раунда (участники)
func (h *Handlers) RoundDetails(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	round, _ := h.repo.GetRoundByID(id)
	if round == nil {
		http.Error(w, "Round not found", http.StatusNotFound)
		return
	}
	
	participants, _ := h.repo.GetParticipantsByRound(id)
	topic, _ := h.repo.GetTopicByID(round.TopicID)
	tournament, _ := h.repo.GetTournamentByID(round.TournamentID)
	
	data := map[string]interface{}{
		"Round":        round,
		"Participants": participants,
		"Topic":        topic,
		"Tournament":   tournament,
	}
	if err := h.templates.ExecuteTemplate(w, "round_details.html", data); err != nil {
		log.Printf("Template error: %v", err)
	}
}
