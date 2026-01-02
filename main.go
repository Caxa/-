package main

import (
	"debate-club/internal/database"
	"debate-club/internal/handlers"
	"debate-club/internal/repository"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

func main() {
	// Загружаем переменные окружения из .env файла
	if err := godotenv.Load(); err != nil {
		log.Println("Файл .env не найден, используются переменные окружения системы")
	}

	// Параметры подключения к БД
	dbHost := flag.String("dbhost", getEnv("DB_HOST", "localhost"), "Database host")
	dbPort := flag.String("dbport", getEnv("DB_PORT", "5432"), "Database port")
	dbUser := flag.String("dbuser", getEnv("DB_USER", "postgres"), "Database user")
	dbPassword := flag.String("dbpassword", getEnv("DB_PASSWORD", ""), "Database password")
	dbName := flag.String("dbname", getEnv("DB_NAME", "debate_club"), "Database name")
	port := flag.String("port", getEnv("PORT", "8080"), "Server port")
	flag.Parse()

	// Если пароль не указан, пытаемся получить из переменной окружения
	if *dbPassword == "" {
		*dbPassword = os.Getenv("DB_PASSWORD")
	}

	// Строка подключения к PostgreSQL
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		*dbHost, *dbPort, *dbUser, *dbPassword, *dbName)

	// Подключение к БД
	db, err := database.NewDB(connStr)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Создание репозитория и обработчиков
	repo := repository.NewRepository(db.DB)
	h, err := handlers.NewHandlers(repo)
	if err != nil {
		log.Fatalf("Failed to create handlers: %v", err)
	}

	// Настройка маршрутов
	mux := http.NewServeMux()

	// Статические файлы (если нужны)
	fs := http.FileServer(http.Dir("static"))
	mux.Handle("/static/", http.StripPrefix("/static/", fs))

	// Главная страница
	mux.HandleFunc("/", h.Home)

	// Участники
	mux.HandleFunc("/participants", h.ParticipantsList)
	mux.HandleFunc("/participants/create", h.CreateParticipant)
	mux.HandleFunc("/participants/update", h.UpdateParticipant)
	mux.HandleFunc("/participants/delete", h.DeleteParticipant)

	// Жюри
	mux.HandleFunc("/judges", h.JudgesList)
	mux.HandleFunc("/judges/create", h.CreateJudge)
	mux.HandleFunc("/judges/update", h.UpdateJudge)
	mux.HandleFunc("/judges/delete", h.DeleteJudge)

	// Темы
	mux.HandleFunc("/topics", h.TopicsList)
	mux.HandleFunc("/topics/create", h.CreateTopic)
	mux.HandleFunc("/topics/update", h.UpdateTopic)
	mux.HandleFunc("/topics/delete", h.DeleteTopic)

	// Сезоны
	mux.HandleFunc("/seasons", h.SeasonsList)
	mux.HandleFunc("/seasons/create", h.CreateSeason)
	mux.HandleFunc("/seasons/update", h.UpdateSeason)
	mux.HandleFunc("/seasons/delete", h.DeleteSeason)
	mux.HandleFunc("/seasons/details", h.SeasonDetails)

	// Турниры
	mux.HandleFunc("/tournaments", h.TournamentsList)
	mux.HandleFunc("/tournaments/create", h.CreateTournament)
	mux.HandleFunc("/tournaments/update", h.UpdateTournament)
	mux.HandleFunc("/tournaments/delete", h.DeleteTournament)
	mux.HandleFunc("/tournaments/details", h.TournamentDetailsPage)
	mux.HandleFunc("/tournaments/", h.TournamentDetails) // Обрабатывает /tournaments/{id}/results и /tournaments/{id}/schedule

	// Раунды
	mux.HandleFunc("/rounds", h.RoundsList)
	mux.HandleFunc("/rounds/create", h.CreateRound)
	mux.HandleFunc("/rounds/update", h.UpdateRound)
	mux.HandleFunc("/rounds/delete", h.DeleteRound)
	mux.HandleFunc("/rounds/details", h.RoundDetails)

	// Выступления
	mux.HandleFunc("/performances", h.PerformancesList)
	mux.HandleFunc("/performances/create", h.CreatePerformance)
	mux.HandleFunc("/performances/update", h.UpdatePerformance)
	mux.HandleFunc("/performances/delete", h.DeletePerformance)

	// Запросы
	mux.HandleFunc("/queries", h.Queries)

	log.Printf("Server starting on port %s", *port)
	log.Printf("Database: %s@%s:%s/%s", *dbUser, *dbHost, *dbPort, *dbName)
	if err := http.ListenAndServe(":"+*port, mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// getEnv получает переменную окружения или возвращает значение по умолчанию
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

