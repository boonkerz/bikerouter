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
	"strconv"
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
	mux.HandleFunc("GET /api/share/{code}/course.fit", getShareFit)
	mux.HandleFunc("PATCH /api/share/{code}", publishShare)
	mux.HandleFunc("DELETE /api/share/{code}", deleteShare)
	mux.HandleFunc("GET /api/library", listLibrary)

	log.Printf("share service on %s", addr)
	if err := http.ListenAndServe(addr, withCORS(mux)); err != nil {
		log.Fatal(err)
	}
}

func initSchema() error {
	if _, err := db.Exec(`
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
	`); err != nil {
		return err
	}
	// v1.10: public library columns. Older rows get sensible defaults via ADD
	// COLUMN; ignore "duplicate column name" errors so the migration is
	// idempotent across restarts.
	addColumns := []string{
		`ALTER TABLE shares ADD COLUMN edit_token TEXT NOT NULL DEFAULT ''`,
		`ALTER TABLE shares ADD COLUMN published INTEGER NOT NULL DEFAULT 0`,
		`ALTER TABLE shares ADD COLUMN approved INTEGER NOT NULL DEFAULT 1`,
		`ALTER TABLE shares ADD COLUMN title TEXT NOT NULL DEFAULT ''`,
		`ALTER TABLE shares ADD COLUMN description TEXT NOT NULL DEFAULT ''`,
		`ALTER TABLE shares ADD COLUMN profile TEXT NOT NULL DEFAULT ''`,
		`ALTER TABLE shares ADD COLUMN ascent INTEGER NOT NULL DEFAULT 0`,
		`ALTER TABLE shares ADD COLUMN center_lat REAL NOT NULL DEFAULT 0`,
		`ALTER TABLE shares ADD COLUMN center_lon REAL NOT NULL DEFAULT 0`,
		`ALTER TABLE shares ADD COLUMN published_at TEXT NOT NULL DEFAULT ''`,
		`CREATE INDEX IF NOT EXISTS idx_shares_published ON shares(published, approved, published_at)`,
	}
	for _, q := range addColumns {
		if _, err := db.Exec(q); err != nil {
			if strings.Contains(err.Error(), "duplicate column") {
				continue
			}
			if strings.Contains(err.Error(), "already exists") {
				continue
			}
			return err
		}
	}
	return nil
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
	editToken := newEditToken()

	for try := 0; try < 8; try++ {
		code := newCode()
		_, err := db.Exec(
			`INSERT INTO shares (code, name, gpx, distance_m, creator_ip, created_at, expires_at, edit_token) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
			code, in.Name, []byte(in.Gpx), in.DistanceM, creatorHash,
			now.Format(time.RFC3339), expires.Format(time.RFC3339), editToken,
		)
		if err == nil {
			writeJSON(w, map[string]any{
				"code":      code,
				"expiresAt": expires.Format(time.RFC3339),
				"editToken": editToken,
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

func newEditToken() string {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		panic(err)
	}
	return hex.EncodeToString(buf)
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

func getShareFit(w http.ResponseWriter, r *http.Request) {
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
	fitBytes, err := gpxToFitCourse(gpx, sanitizeName(name))
	if err != nil {
		log.Printf("gpx→fit conversion failed for %s: %v", code, err)
		httpErr(w, http.StatusInternalServerError, errors.New("conversion failed"))
		return
	}
	filename := "wegwiesel-" + code + ".fit"
	w.Header().Set("Content-Type", "application/vnd.ant.fit")
	w.Header().Set("Content-Disposition", `attachment; filename="`+filename+`"`)
	w.Header().Set("Cache-Control", "private, max-age=60")
	_, _ = w.Write(fitBytes)
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
		// Published shares survive past their original 7-day TTL — the
		// public library is meant to persist. Unpublished shares still GC.
		_, err := db.Exec(
			`DELETE FROM shares WHERE expires_at <= ? AND published = 0`,
			time.Now().UTC().Format(time.RFC3339),
		)
		if err != nil {
			log.Printf("gc error: %v", err)
		}
	}
}

func publishShare(w http.ResponseWriter, r *http.Request) {
	code := normaliseCode(r.PathValue("code"))
	if !validCode(code) {
		httpErr(w, http.StatusBadRequest, errors.New("invalid code"))
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 16*1024)
	var in struct {
		EditToken   string  `json:"editToken"`
		Published   *bool   `json:"published"`
		Title       *string `json:"title"`
		Description *string `json:"description"`
		Profile     *string `json:"profile"`
		Ascent      *int    `json:"ascent"`
		CenterLat   *float64 `json:"centerLat"`
		CenterLon   *float64 `json:"centerLon"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		httpErr(w, http.StatusBadRequest, err)
		return
	}
	if in.EditToken == "" {
		httpErr(w, http.StatusUnauthorized, errors.New("edit_token required"))
		return
	}

	var stored string
	row := db.QueryRow(`SELECT edit_token FROM shares WHERE code = ?`, code)
	if err := row.Scan(&stored); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			httpErr(w, http.StatusNotFound, errors.New("not found"))
			return
		}
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	if stored == "" || stored != in.EditToken {
		httpErr(w, http.StatusForbidden, errors.New("wrong edit_token"))
		return
	}

	// Build a dynamic UPDATE only over the fields the caller actually sent.
	sets := []string{}
	args := []any{}
	if in.Published != nil {
		sets = append(sets, "published = ?")
		v := 0
		if *in.Published {
			v = 1
		}
		args = append(args, v)
		if *in.Published {
			sets = append(sets, "published_at = ?")
			args = append(args, time.Now().UTC().Format(time.RFC3339))
		}
	}
	if in.Title != nil {
		t := strings.TrimSpace(*in.Title)
		if len(t) > 200 {
			t = t[:200]
		}
		sets = append(sets, "title = ?")
		args = append(args, t)
	}
	if in.Description != nil {
		d := strings.TrimSpace(*in.Description)
		if len(d) > 2000 {
			d = d[:2000]
		}
		sets = append(sets, "description = ?")
		args = append(args, d)
	}
	if in.Profile != nil {
		p := strings.TrimSpace(*in.Profile)
		if len(p) > 64 {
			p = p[:64]
		}
		sets = append(sets, "profile = ?")
		args = append(args, p)
	}
	if in.Ascent != nil {
		sets = append(sets, "ascent = ?")
		args = append(args, *in.Ascent)
	}
	if in.CenterLat != nil && in.CenterLon != nil {
		sets = append(sets, "center_lat = ?", "center_lon = ?")
		args = append(args, *in.CenterLat, *in.CenterLon)
	}

	if len(sets) == 0 {
		httpErr(w, http.StatusBadRequest, errors.New("no fields to update"))
		return
	}
	args = append(args, code)
	if _, err := db.Exec(
		"UPDATE shares SET "+strings.Join(sets, ", ")+" WHERE code = ?", args...,
	); err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	writeJSON(w, map[string]any{"ok": true})
}

func deleteShare(w http.ResponseWriter, r *http.Request) {
	code := normaliseCode(r.PathValue("code"))
	if !validCode(code) {
		httpErr(w, http.StatusBadRequest, errors.New("invalid code"))
		return
	}
	token := r.URL.Query().Get("editToken")
	if token == "" {
		httpErr(w, http.StatusUnauthorized, errors.New("edit_token required"))
		return
	}
	res, err := db.Exec(
		`DELETE FROM shares WHERE code = ? AND edit_token = ?`,
		code, token,
	)
	if err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		httpErr(w, http.StatusForbidden, errors.New("wrong edit_token or already gone"))
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func listLibrary(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	profile := strings.TrimSpace(q.Get("profile"))
	search := strings.ToLower(strings.TrimSpace(q.Get("q")))
	minKm, _ := strconv.ParseFloat(q.Get("minKm"), 64)
	maxKm, _ := strconv.ParseFloat(q.Get("maxKm"), 64)
	bbox := strings.Split(q.Get("bbox"), ",") // minLat,minLon,maxLat,maxLon
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 0 {
		page = 0
	}
	const pageSize = 30

	where := []string{"published = 1", "approved = 1"}
	args := []any{}
	if profile != "" {
		where = append(where, "profile = ?")
		args = append(args, profile)
	}
	if minKm > 0 {
		where = append(where, "distance_m >= ?")
		args = append(args, int64(minKm*1000))
	}
	if maxKm > 0 {
		where = append(where, "distance_m <= ?")
		args = append(args, int64(maxKm*1000))
	}
	if len(bbox) == 4 {
		minLat, _ := strconv.ParseFloat(bbox[0], 64)
		minLon, _ := strconv.ParseFloat(bbox[1], 64)
		maxLat, _ := strconv.ParseFloat(bbox[2], 64)
		maxLon, _ := strconv.ParseFloat(bbox[3], 64)
		where = append(where, "center_lat BETWEEN ? AND ?", "center_lon BETWEEN ? AND ?")
		args = append(args, minLat, maxLat, minLon, maxLon)
	}
	if search != "" {
		where = append(where, "(lower(title) LIKE ? OR lower(description) LIKE ?)")
		needle := "%" + search + "%"
		args = append(args, needle, needle)
	}
	args = append(args, pageSize, page*pageSize)

	rows, err := db.Query(
		`SELECT code, title, description, profile, distance_m, ascent, center_lat, center_lon, published_at
		 FROM shares
		 WHERE `+strings.Join(where, " AND ")+`
		 ORDER BY published_at DESC
		 LIMIT ? OFFSET ?`,
		args...,
	)
	if err != nil {
		httpErr(w, http.StatusInternalServerError, err)
		return
	}
	defer rows.Close()

	type item struct {
		Code        string  `json:"code"`
		Title       string  `json:"title"`
		Description string  `json:"description"`
		Profile     string  `json:"profile"`
		DistanceM   int64   `json:"distanceM"`
		Ascent      int     `json:"ascent"`
		CenterLat   float64 `json:"centerLat"`
		CenterLon   float64 `json:"centerLon"`
		PublishedAt string  `json:"publishedAt"`
	}
	out := []item{}
	for rows.Next() {
		var it item
		if err := rows.Scan(&it.Code, &it.Title, &it.Description, &it.Profile,
			&it.DistanceM, &it.Ascent, &it.CenterLat, &it.CenterLon, &it.PublishedAt); err != nil {
			httpErr(w, http.StatusInternalServerError, err)
			return
		}
		out = append(out, it)
	}
	writeJSON(w, map[string]any{
		"page":  page,
		"items": out,
	})
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
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
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
