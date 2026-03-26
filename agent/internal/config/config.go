package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// Config holds the agent configuration
type Config struct {
	Port  int    `json:"port"`  // HTTP API port
	Token string `json:"token"` // Authentication token
}

const defaultConfigPath = "/etc/server-monitor/config.json"
const defaultPort = 9100

// Load reads configuration from file, or returns defaults
func Load() (*Config, error) {
	cfg := &Config{
		Port:  defaultPort,
		Token: "",
	}

	// Try default path first
	if _, err := os.Stat(defaultConfigPath); err == nil {
		return loadFromFile(defaultConfigPath)
	}

	// Try current directory
	cwd, _ := os.Getwd()
	localPath := filepath.Join(cwd, "config.json")
	if _, err := os.Stat(localPath); err == nil {
		return loadFromFile(localPath)
	}

	return cfg, nil
}

func loadFromFile(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	cfg := &Config{
		Port:  defaultPort,
		Token: "",
	}

	if err := json.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	return cfg, nil
}
