package main

import (
	"crypto/sha256"
	"database/sql"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	_ "modernc.org/sqlite"
)

//go:embed index.html
var staticFS embed.FS

type Feedback struct {
	ID          int64  `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Votes       int64  `json:"votes"`
	Voted       bool   `json:"voted"`
	CreatedAt   string `json:"createdAt"`
}

var (
	db         *sql.DB
	adminToken string
	ipSalt     string
	limiter    = newLimiter(30, time.Minute)
)

func main() {
	dbPath := envOr("DB_PATH", "/data/feedback.db")
	adminToken = os.Getenv("ADMIN_TOKEN")
	ipSalt = envOr("IP_SALT", "change-me")
	addr := envOr("LISTEN_ADDR", ":8080")

	var err error
	db, err = sql.Open("sqlite", dbPath+"?_pragma=journal_mode(WAL)&_pragma=busy_timeout(3000)")
	if err != nil {
		log.Fatal(err)
	}
	if err := initSchema(); err != nil {
		log.Fatal(err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/feedback", listFeedback)
	mux.HandleFunc("POST /api/feedback", createFeedback)
	mux.HandleFunc("POST /api/feedback/{id}/vote", voteFeedback)
	mux.HandleFunc("DELETE /api/feedback/{id}", deleteFeedback)
	mux.Handle("GET /", http.FileServerFS(staticFS))

	log.Printf("feedback service on %s", addr)
	if err := http.ListenAndServe(addr, withCORS(mux)); err != nil {
		log.Fatal(err)
	}
}

func initSchema() error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS feedback (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			title TEXT NOT NULL,
			description TEXT NOT NULL DEFAULT '',
			created_at TEXT NOT NULL
		);
		CREATE TABLE IF NOT EXISTS votes (
			feedback_id INTEGER NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
			ip_hash TEXT NOT NULL,
			created_at TEXT NOT NULL,
			PRIMARY KEY (feedback_id, ip_hash)
		);
		CREATE INDEX IF NOT EXISTS idx_feedback_created ON feedback(created_at);
	`)
	return err
}

func listFeedback(w http.ResponseWriter, r *http.Request) {
	hash := hashIP(clientIP(r))
	rows, err := db.Query(`
		SELECT f.id, f.title, f.description, f.created_at,
		       COALESCE(COUNT(v.feedback_id), 0) AS votes,
		       MAX(CASE WHEN v.ip_hash = ? THEN 1 ELSE 0 END) AS voted
		FROM feedback f
		LEFT JOIN votes v ON v.feedback_id = f.id
		GROUP BY f.id
		ORDER BY votes DESC, f.created_at DESC
		LIMIT 500
	`, hash)
	if err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	defer rows.Close()
	out := []Feedback{}
	for rows.Next() {
		var f Feedback
		var voted int
		if err := rows.Scan(&f.ID, &f.Title, &f.Description, &f.CreatedAt, &f.Votes, &voted); err != nil {
			httpErr(w, http.StatusInternalServerError, err)
			return
		}
		f.Voted = voted == 1
		out = append(out, f)
	}
	writeJSON(w, out)
}

func createFeedback(w http.ResponseWriter, r *http.Request) {
	if !limiter.allow(clientIP(r)) {
		httpErr(w, http.StatusTooManyRequests, errors.New("rate limit"))
		return
	}
	var in struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Website     string `json:"website"` // honeypot
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		httpErr(w, http.StatusBadRequest, err)
		return
	}
	in.Title = strings.TrimSpace(in.Title)
	in.Description = strings.TrimSpace(in.Description)
	if in.Website != "" {
		// Bot detected; pretend success.
		writeJSON(w, map[string]any{"ok": true})
		return
	}
	if len(in.Title) < 3 || len(in.Title) > 140 {
		httpErr(w, http.StatusBadRequest, errors.New("title 3-140 chars"))
		return
	}
	if len(in.Description) > 2000 {
		httpErr(w, http.StatusBadRequest, errors.New("description too long"))
		return
	}
	res, err := db.Exec(
		"INSERT INTO feedback (title, description, created_at) VALUES (?, ?, ?)",
		in.Title, in.Description, time.Now().UTC().Format(time.RFC3339),
	)
	if err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	id, _ := res.LastInsertId()
	// Auto-upvote by author.
	_, _ = db.Exec(
		"INSERT OR IGNORE INTO votes (feedback_id, ip_hash, created_at) VALUES (?, ?, ?)",
		id, hashIP(clientIP(r)), time.Now().UTC().Format(time.RFC3339),
	)
	writeJSON(w, map[string]any{"id": id})
}

func voteFeedback(w http.ResponseWriter, r *http.Request) {
	if !limiter.allow(clientIP(r)) {
		httpErr(w, http.StatusTooManyRequests, errors.New("rate limit"))
		return
	}
	id, err := strconv.ParseInt(r.PathValue("id"), 10, 64)
	if err != nil {
		httpErr(w, http.StatusBadRequest, err)
		return
	}
	hash := hashIP(clientIP(r))
	// Toggle behaviour: if already voted, remove; else insert.
	var existing int
	row := db.QueryRow("SELECT COUNT(*) FROM votes WHERE feedback_id=? AND ip_hash=?", id, hash)
	if err := row.Scan(&existing); err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	if existing > 0 {
		if _, err := db.Exec("DELETE FROM votes WHERE feedback_id=? AND ip_hash=?", id, hash); err != nil {
			httpErr(w, http.StatusInternalServerError, err)
			return
		}
		writeJSON(w, map[string]any{"voted": false})
		return
	}
	if _, err := db.Exec(
		"INSERT INTO votes (feedback_id, ip_hash, created_at) VALUES (?, ?, ?)",
		id, hash, time.Now().UTC().Format(time.RFC3339),
	); err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	writeJSON(w, map[string]any{"voted": true})
}

func deleteFeedback(w http.ResponseWriter, r *http.Request) {
	if adminToken == "" {
		httpErr(w, http.StatusForbidden, errors.New("admin disabled"))
		return
	}
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") || strings.TrimPrefix(auth, "Bearer ") != adminToken {
		httpErr(w, http.StatusUnauthorized, errors.New("auth"))
		return
	}
	id, err := strconv.ParseInt(r.PathValue("id"), 10, 64)
	if err != nil {
		httpErr(w, http.StatusBadRequest, err)
		return
	}
	if _, err := db.Exec("DELETE FROM feedback WHERE id=?", id); err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	writeJSON(w, map[string]any{"ok": true})
}

func hashIP(ip string) string {
	h := sha256.Sum256([]byte(ipSalt + "|" + ip))
	return hex.EncodeToString(h[:16])
}

func clientIP(r *http.Request) string {
	if f := r.Header.Get("X-Forwarded-For"); f != "" {
		if comma := strings.Index(f, ","); comma > 0 {
			f = f[:comma]
		}
		return strings.TrimSpace(f)
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func httpErr(w http.ResponseWriter, code int, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// --- Rate limiter ---

type limiterState struct {
	mu      sync.Mutex
	buckets map[string][]time.Time
	max     int
	window  time.Duration
}

func newLimiter(max int, window time.Duration) *limiterState {
	l := &limiterState{
		buckets: map[string][]time.Time{},
		max:     max,
		window:  window,
	}
	go l.gc()
	return l
}

func (l *limiterState) allow(key string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	cutoff := now.Add(-l.window)
	hits := l.buckets[key]
	out := hits[:0]
	for _, t := range hits {
		if t.After(cutoff) {
			out = append(out, t)
		}
	}
	if len(out) >= l.max {
		l.buckets[key] = out
		return false
	}
	l.buckets[key] = append(out, now)
	return true
}

func (l *limiterState) gc() {
	t := time.NewTicker(l.window)
	for range t.C {
		l.mu.Lock()
		cutoff := time.Now().Add(-l.window)
		for k, hits := range l.buckets {
			out := hits[:0]
			for _, h := range hits {
				if h.After(cutoff) {
					out = append(out, h)
				}
			}
			if len(out) == 0 {
				delete(l.buckets, k)
			} else {
				l.buckets[k] = out
			}
		}
		l.mu.Unlock()
	}
}
