package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/server-monitor/agent/internal/auth"
	"github.com/server-monitor/agent/internal/metrics"
)

// NewMux creates an HTTP handler with all API routes
func NewMux(token string) http.Handler {
	mux := http.NewServeMux()

	// Health check - no auth required
	mux.HandleFunc("GET /health", handleHealth)

	// Metrics endpoint - requires auth if token is set
	mux.HandleFunc("GET /metrics", handleMetrics)

	// System info only
	mux.HandleFunc("GET /system", handleSystem)

	// CPU metrics
	mux.HandleFunc("GET /cpu", handleCPU)

	// Memory metrics
	mux.HandleFunc("GET /memory", handleMemory)

	// Disk metrics
	mux.HandleFunc("GET /disk", handleDisk)

	// Network metrics
	mux.HandleFunc("GET /network", handleNetwork)

	// Apply auth and CORS middleware to all routes
	return corsMiddleware(auth.Middleware(token)(mux))
}

// corsMiddleware adds CORS headers to allow browser-based access
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func handleMetrics(w http.ResponseWriter, r *http.Request) {
	m, err := metrics.Collect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": fmt.Sprintf("failed to collect metrics: %v", err)})
		return
	}
	writeJSON(w, http.StatusOK, m)
}

func handleSystem(w http.ResponseWriter, r *http.Request) {
	m, err := metrics.Collect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, m.System)
}

func handleCPU(w http.ResponseWriter, r *http.Request) {
	m, err := metrics.Collect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, m.CPU)
}

func handleMemory(w http.ResponseWriter, r *http.Request) {
	m, err := metrics.Collect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, m.Memory)
}

func handleDisk(w http.ResponseWriter, r *http.Request) {
	m, err := metrics.Collect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, m.Disk)
}

func handleNetwork(w http.ResponseWriter, r *http.Request) {
	m, err := metrics.Collect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, m.Network)
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
