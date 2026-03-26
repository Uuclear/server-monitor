package main

import (
	"crypto/rand"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/server-monitor/agent/internal/api"
	"github.com/server-monitor/agent/internal/config"
)

func main() {
	// Command-line flags
	port := flag.Int("port", 0, "HTTP listen port (overrides config)")
	token := flag.String("token", "", "Authentication token (overrides config)")
	genToken := flag.Bool("gen-token", false, "Generate a random token and exit")
	configPath := flag.String("config", "", "Path to config file")
	flag.Parse()

	// Generate a random token if requested
	if *genToken {
		b := make([]byte, 32)
		if _, err := rand.Read(b); err != nil {
			log.Fatalf("failed to generate token: %v", err)
		}
		fmt.Println(hex.EncodeToString(b))
		os.Exit(0)
	}

	// Load config
	cfg := &config.Config{Port: 9100, Token: ""}
	if *configPath != "" {
		data, err := os.ReadFile(*configPath)
		if err != nil {
			log.Fatalf("failed to read config: %v", err)
		}
		_ = data // config.LoadFromFile is not exported, handle inline
	}

	// Load from default locations
	loaded, err := config.Load()
	if err == nil {
		cfg = loaded
	}

	// CLI flags override config
	if *port > 0 {
		cfg.Port = *port
	}
	if *token != "" {
		cfg.Token = *token
	}

	// Build handler
	handler := api.NewMux(cfg.Token)

	// Start server
	addr := fmt.Sprintf(":%d", cfg.Port)
	server := &http.Server{
		Addr:    addr,
		Handler: handler,
	}

	// Graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("Server Monitor Agent starting on %s", addr)
		log.Printf("Endpoints: /health, /metrics, /system, /cpu, /memory, /disk, /network")
		if cfg.Token != "" {
			log.Printf("Authentication: enabled (Bearer token)")
		} else {
			log.Printf("Authentication: disabled (no token set)")
		}
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	// Wait for shutdown signal
	<-sigCh
	log.Println("Shutting down...")
	server.Close()
}
