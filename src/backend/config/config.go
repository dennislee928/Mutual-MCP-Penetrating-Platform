package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// Config 統一安全平台配置
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Services ServicesConfig
}

// ServerConfig HTTP 伺服器配置
type ServerConfig struct {
	Port            int
	Host            string
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	ShutdownTimeout time.Duration
	Mode            string // debug, release, test
}

// DatabaseConfig 資料庫配置（PostgreSQL）
type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
	MaxConns int
	MaxIdle  int
}

// RedisConfig Redis 快取配置
type RedisConfig struct {
	Host     string
	Port     int
	Password string
	DB       int
}

// JWTConfig JWT 認證配置
type JWTConfig struct {
	Secret     string
	Expiration time.Duration
}

// ServicesConfig 外部服務配置
type ServicesConfig struct {
	HexStrikeURL  string // HexStrike AI 服務 URL
	AIQuantumURL  string // AI/量子服務 URL
	VaultAddr     string // Vault 地址
	VaultToken    string // Vault Token
	PrometheusURL string // Prometheus URL
}

// Load 從環境變數載入配置
func Load() (*Config, error) {
	config := &Config{
		Server: ServerConfig{
			Port:            getEnvAsInt("SERVER_PORT", 3001),
			Host:            getEnv("SERVER_HOST", "0.0.0.0"),
			ReadTimeout:     getEnvAsDuration("SERVER_READ_TIMEOUT", 15*time.Second),
			WriteTimeout:    getEnvAsDuration("SERVER_WRITE_TIMEOUT", 15*time.Second),
			ShutdownTimeout: getEnvAsDuration("SERVER_SHUTDOWN_TIMEOUT", 30*time.Second),
			Mode:            getEnv("GIN_MODE", "debug"), // debug, release, test
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", 5432),
			User:     getEnv("DB_USER", "sectools"),
			Password: getEnv("DB_PASSWORD", "changeme"),
			DBName:   getEnv("DB_NAME", "sectools"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
			MaxConns: getEnvAsInt("DB_MAX_CONNS", 25),
			MaxIdle:  getEnvAsInt("DB_MAX_IDLE", 5),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnvAsInt("REDIS_PORT", 6379),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		JWT: JWTConfig{
			Secret:     getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
			Expiration: getEnvAsDuration("JWT_EXPIRATION", 24*time.Hour),
		},
		Services: ServicesConfig{
			HexStrikeURL:  getEnv("HEXSTRIKE_URL", "http://localhost:8888"),
			AIQuantumURL:  getEnv("AI_QUANTUM_URL", "http://localhost:8000"),
			VaultAddr:     getEnv("VAULT_ADDR", "http://localhost:8200"),
			VaultToken:    getEnv("VAULT_TOKEN", "root"),
			PrometheusURL: getEnv("PROMETHEUS_URL", "http://localhost:9090"),
		},
	}

	// 驗證必要配置
	if err := config.validate(); err != nil {
		return nil, err
	}

	return config, nil
}

// validate 驗證配置
func (c *Config) validate() error {
	if c.Database.Password == "changeme" {
		return fmt.Errorf("請設定 DB_PASSWORD 環境變數")
	}
	if c.JWT.Secret == "your-secret-key-change-in-production" {
		return fmt.Errorf("請設定 JWT_SECRET 環境變數")
	}
	return nil
}

// DSN 回傳 PostgreSQL DSN 連接字串
func (c *DatabaseConfig) DSN() string {
	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Host, c.Port, c.User, c.Password, c.DBName, c.SSLMode,
	)
}

// RedisAddr 回傳 Redis 地址
func (c *RedisConfig) RedisAddr() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}

// Helper functions

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}

