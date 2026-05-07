package main

import (
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	_ "modernc.org/sqlite"
)

const (
	codeAlphabet  = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Crockford-ish, no I/O/0/1
	codeLen       = 6
	maxGpxBytes   = 5 * 1024 * 1024
	defaultTTLDays = 7
)

var (
	db        *sql.DB
	ipSalt    string
	limiter   = newLimiter(20, time.Minute)
	gpxLimiter = newLimiter(60, time.Minute)
)

func main() {
	dbPath := envOr("DB_PATH", "/data/share.db")
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
	go gcExpired()

	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/share", createShare)
	mux.HandleFunc("GET /api/share/{code}", getShareMeta)
	mux.HandleFunc("GET /api/share/{code}/course.gpx", getShareGpx)

	log.Printf("share service on %s", addr)
	if err := http.ListenAndServe(addr, withCORS(mux)); err != nil {
		log.Fatal(err)
	}
}

func initSchema() error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS shares (
			code        TEXT PRIMARY KEY,
			name        TEXT NOT NULL DEFAULT '',
			gpx         BLOB NOT NULL,
			distance_m  INTEGER NOT NULL DEFAULT 0,
			creator_ip  TEXT NOT NULL DEFAULT '',
			created_at  TEXT NOT NULL,
			expires_at  TEXT NOT NULL
		);
		CREATE INDEX IF NOT EXISTS idx_shares_expires ON shares(expires_at);
	`)
	return err
}

func createShare(w http.ResponseWriter, r *http.Request) {
	if !limiter.allow(clientIP(r)) {
		httpErr(w, http.StatusTooManyRequests, errors.New("rate limit"))
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, maxGpxBytes+8192)
	var in struct {
		Name      string `json:"name"`
		Gpx       string `json:"gpx"`
		DistanceM int64  `json:"distanceM"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		httpErr(w, http.StatusBadRequest, err)
		return
	}
	in.Name = strings.TrimSpace(in.Name)
	if len(in.Name) > 200 {
		in.Name = in.Name[:200]
	}
	if len(in.Gpx) < 32 {
		httpErr(w, http.StatusBadRequest, errors.New("gpx empty"))
		return
	}
	if len(in.Gpx) > maxGpxBytes {
		httpErr(w, http.StatusBadRequest, errors.New("gpx too large"))
		return
	}
	if !strings.Contains(in.Gpx, "<gpx") {
		httpErr(w, http.StatusBadRequest, errors.New("not a gpx document"))
		return
	}

	now := time.Now().UTC()
	expires := now.Add(defaultTTLDays * 24 * time.Hour)
	creatorHash := hashIP(clientIP(r))

	for try := 0; try < 8; try++ {
		code := newCode()
		_, err := db.Exec(
			`INSERT INTO shares (code, name, gpx, distance_m, creator_ip, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)`,
			code, in.Name, []byte(in.Gpx), in.DistanceM, creatorHash,
			now.Format(time.RFC3339), expires.Format(time.RFC3339),
		)
		if err == nil {
			writeJSON(w, map[string]any{
				"code":      code,
				"expiresAt": expires.Format(time.RFC3339),
			})
			return
		}
		if !strings.Contains(err.Error(), "UNIQUE") {
			httpErr(w, http.StatusInternalServerError, err)
			return
		}
	}
	httpErr(w, http.StatusInternalServerError, errors.New("could not allocate code"))
}

func getShareMeta(w http.ResponseWriter, r *http.Request) {
	code := normaliseCode(r.PathValue("code"))
	if !validCode(code) {
		httpErr(w, http.StatusBadRequest, errors.New("invalid code"))
		return
	}
	var name, createdAt, expiresAt string
	var distanceM int64
	row := db.QueryRow(
		`SELECT name, distance_m, created_at, expires_at FROM shares WHERE code = ? AND expires_at > ?`,
		code, time.Now().UTC().Format(time.RFC3339),
	)
	if err := row.Scan(&name, &distanceM, &createdAt, &expiresAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			httpErr(w, http.StatusNotFound, errors.New("not found or expired"))
			return
		}
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	writeJSON(w, map[string]any{
		"code":      code,
		"name":      name,
		"distanceM": distanceM,
		"createdAt": createdAt,
		"expiresAt": expiresAt,
	})
}

func getShareGpx(w http.ResponseWriter, r *http.Request) {
	if !gpxLimiter.allow(clientIP(r)) {
		httpErr(w, http.StatusTooManyRequests, errors.New("rate limit"))
		return
	}
	code := normaliseCode(r.PathValue("code"))
	if !validCode(code) {
		httpErr(w, http.StatusBadRequest, errors.New("invalid code"))
		return
	}
	var gpx []byte
	var name string
	row := db.QueryRow(
		`SELECT name, gpx FROM shares WHERE code = ? AND expires_at > ?`,
		code, time.Now().UTC().Format(time.RFC3339),
	)
	if err := row.Scan(&name, &gpx); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			httpErr(w, http.StatusNotFound, errors.New("not found or expired"))
			return
		}
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	filename := "wegwiesel-" + code + ".gpx"
	w.Header().Set("Content-Type", "application/gpx+xml; charset=utf-8")
	w.Header().Set("Content-Disposition", `attachment; filename="`+filename+`"`)
	w.Header().Set("Cache-Control", "private, max-age=60")
	_, _ = io.Copy(w, strings.NewReader(string(gpx)))
}

func newCode() string {
	buf := make([]byte, codeLen)
	if _, err := rand.Read(buf); err != nil {
		// Crypto/rand should never fail on supported platforms; panic per std-lib precedent.
		panic(err)
	}
	out := make([]byte, codeLen)
	for i := range buf {
		out[i] = codeAlphabet[int(buf[i])%len(codeAlphabet)]
	}
	return string(out)
}

func normaliseCode(s string) string {
	return strings.ToUpper(strings.TrimSpace(s))
}

func validCode(s string) bool {
	if len(s) != codeLen {
		return false
	}
	for _, ch := range s {
		if !strings.ContainsRune(codeAlphabet, ch) {
			return false
		}
	}
	return true
}

func gcExpired() {
	t := time.NewTicker(1 * time.Hour)
	for range t.C {
		_, err := db.Exec(`DELETE FROM shares WHERE expires_at <= ?`, time.Now().UTC().Format(time.RFC3339))
		if err != nil {
			log.Printf("gc error: %v", err)
		}
	}
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
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// --- Rate limiter (copied from feedback service) ---

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
