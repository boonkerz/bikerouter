// Wegwiesel live-tracking server.
//
// Stateless, in-memory. Each session keeps the last N pings plus metadata
// with a TTL. No accounts, no persistence, no analytics — sessions vanish
// when the TTL lapses or the user explicitly stops.
package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	sessionIDBytes  = 6                // → 12 hex chars
	maxTrailPoints  = 500              // keep the last N pings per session
	defaultTTL      = 12 * time.Hour
	maxTTL          = 24 * time.Hour
	pingMinInterval = 5 * time.Second  // server-side rate limit per session
)

type ping struct {
	Lat   float64 `json:"lat"`
	Lon   float64 `json:"lon"`
	Ele   float64 `json:"ele,omitempty"`
	Speed float64 `json:"speed,omitempty"`
	T     int64   `json:"t"` // millis since epoch
}

type session struct {
	mu        sync.RWMutex
	createdAt time.Time
	expiresAt time.Time
	lastPing  time.Time
	trail     []ping
	name      string
}

var (
	sessions   = struct {
		sync.RWMutex
		m map[string]*session
	}{m: map[string]*session{}}
)

func main() {
	addr := envOr("LISTEN_ADDR", ":8080")

	go gcExpired()

	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/track", createTrack)
	mux.HandleFunc("PUT /api/track/{id}", postPing)
	mux.HandleFunc("DELETE /api/track/{id}", endTrack)
	mux.HandleFunc("GET /api/track/{id}", getTrack)
	mux.HandleFunc("GET /track/{id}", viewerHTML)

	log.Printf("tracking service on %s", addr)
	if err := http.ListenAndServe(addr, withCORS(mux)); err != nil {
		log.Fatal(err)
	}
}

func createTrack(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name      string `json:"name,omitempty"`
		TTLHours  int    `json:"ttl_hours,omitempty"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	ttl := defaultTTL
	if body.TTLHours > 0 {
		ttl = time.Duration(body.TTLHours) * time.Hour
		if ttl > maxTTL {
			ttl = maxTTL
		}
	}

	id := newID()
	now := time.Now()
	s := &session{
		createdAt: now,
		expiresAt: now.Add(ttl),
		trail:     make([]ping, 0, 32),
		name:      body.Name,
	}
	sessions.Lock()
	sessions.m[id] = s
	sessions.Unlock()

	writeJSON(w, http.StatusCreated, map[string]any{
		"id":          id,
		"expires_at":  s.expiresAt.UTC().Format(time.RFC3339),
		"viewer_path": "/track/" + id,
	})
}

func postPing(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	s := getSession(id)
	if s == nil {
		http.Error(w, "not_found", http.StatusNotFound)
		return
	}
	if time.Now().After(s.expiresAt) {
		http.Error(w, "expired", http.StatusGone)
		return
	}

	var p ping
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "bad_json", http.StatusBadRequest)
		return
	}
	if p.Lat < -90 || p.Lat > 90 || p.Lon < -180 || p.Lon > 180 {
		http.Error(w, "out_of_range", http.StatusBadRequest)
		return
	}

	s.mu.Lock()
	now := time.Now()
	if now.Sub(s.lastPing) < pingMinInterval {
		s.mu.Unlock()
		w.WriteHeader(http.StatusTooManyRequests)
		return
	}
	s.lastPing = now
	if p.T == 0 {
		p.T = now.UnixMilli()
	}
	s.trail = append(s.trail, p)
	if len(s.trail) > maxTrailPoints {
		s.trail = s.trail[len(s.trail)-maxTrailPoints:]
	}
	s.mu.Unlock()
	w.WriteHeader(http.StatusNoContent)
}

func endTrack(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	sessions.Lock()
	delete(sessions.m, id)
	sessions.Unlock()
	w.WriteHeader(http.StatusNoContent)
}

func getTrack(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	s := getSession(id)
	if s == nil {
		http.Error(w, "not_found", http.StatusNotFound)
		return
	}
	if time.Now().After(s.expiresAt) {
		http.Error(w, "expired", http.StatusGone)
		return
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	trail := append([]ping(nil), s.trail...)
	writeJSON(w, http.StatusOK, map[string]any{
		"id":         id,
		"name":       s.name,
		"created_at": s.createdAt.UTC().Format(time.RFC3339),
		"expires_at": s.expiresAt.UTC().Format(time.RFC3339),
		"trail":      trail,
		"last":       lastPing(trail),
	})
}

func lastPing(t []ping) any {
	if len(t) == 0 {
		return nil
	}
	return t[len(t)-1]
}

func viewerHTML(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if strings.ContainsAny(id, "<>\"'") {
		http.Error(w, "bad_id", http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_, _ = w.Write(viewerTemplate(id))
}

func getSession(id string) *session {
	sessions.RLock()
	defer sessions.RUnlock()
	return sessions.m[id]
}

func newID() string {
	b := make([]byte, sessionIDBytes)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func gcExpired() {
	for range time.Tick(5 * time.Minute) {
		now := time.Now()
		sessions.Lock()
		for id, s := range sessions.m {
			if now.After(s.expiresAt) {
				delete(sessions.m, id)
			}
		}
		sessions.Unlock()
	}
}

func envOr(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
