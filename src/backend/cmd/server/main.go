package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/dennislwm/unified-security-platform/backend/config"
	"github.com/dennislwm/unified-security-platform/backend/pkg/database"
	"github.com/dennislwm/unified-security-platform/backend/pkg/logger"
	"github.com/dennislwm/unified-security-platform/backend/pkg/redis"
	"github.com/gin-gonic/gin"
)

// @title 統一安全平台 API
// @version 1.0
// @description 雲原生安全與基礎設施管理的統一平台 API
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url https://github.com/dennislwm/unified-security-platform
// @contact.email support@example.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:3001
// @BasePath /api/v1

// @securityDefinitions.apikey Bearer
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.

func main() {
	// 載入配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("❌ 載入配置失敗: %v", err)
	}

	// 初始化 logger
	logger := logger.NewLogger(cfg.Server.Mode)
	logger.Info("🚀 啟動統一安全平台後端服務")

	// 連接資料庫
	db, err := database.NewPostgresDB(&cfg.Database)
	if err != nil {
		logger.Fatal("❌ 資料庫連接失敗", "error", err)
	}
	logger.Info("✅ PostgreSQL 連接成功")

	// 連接 Redis
	redisClient := redis.NewRedisClient(&cfg.Redis)
	if err := redisClient.Ping(context.Background()); err != nil {
		logger.Warn("⚠️  Redis 連接失敗，部分功能可能受限", "error", err)
	} else {
		logger.Info("✅ Redis 連接成功")
	}

	// 設定 Gin 模式
	gin.SetMode(cfg.Server.Mode)

	// 建立 Gin 路由器
	router := gin.New()

	// 全局中間件
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(corsMiddleware())

	// 健康檢查端點
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "unified-security-platform-backend",
			"version": "1.0.0",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// API v1 路由組
	v1 := router.Group("/api/v1")
	{
		// 掃描管理
		scans := v1.Group("/scans")
		{
			scans.GET("", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "掃描列表", "data": []string{}})
			})
			scans.POST("", func(c *gin.Context) {
				c.JSON(http.StatusCreated, gin.H{"message": "建立掃描任務"})
			})
			scans.GET("/:id", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "掃描詳情", "id": c.Param("id")})
			})
		}

		// 安全事件
		events := v1.Group("/security-events")
		{
			events.GET("", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "安全事件列表", "data": []string{}})
			})
		}

		// 監控指標
		metrics := v1.Group("/metrics")
		{
			metrics.GET("/summary", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"scans_total":     0,
					"events_total":    0,
					"threats_blocked": 0,
				})
			})
		}

		// 整合端點
		integration := v1.Group("/integration")
		{
			// 呼叫 HexStrike AI
			integration.POST("/hexstrike/scan", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "HexStrike 掃描已觸發"})
			})

			// 呼叫 AI/量子服務
			integration.POST("/ai-quantum/analyze", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "AI 威脅分析已觸發"})
			})
		}
	}

	// Prometheus 指標端點
	router.GET("/metrics/prometheus", func(c *gin.Context) {
		c.String(http.StatusOK, "# Prometheus metrics endpoint\n")
	})

	// Swagger 文件（開發環境）
	if cfg.Server.Mode == "debug" {
		router.GET("/swagger/*any", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "Swagger UI will be here"})
		})
	}

	// 建立 HTTP server
	srv := &http.Server{
		Addr:         fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port),
		Handler:      router,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
	}

	// 啟動服務器（在 goroutine 中）
	go func() {
		logger.Info(fmt.Sprintf("🌐 HTTP 服務器啟動於 http://%s:%d", cfg.Server.Host, cfg.Server.Port))
		logger.Info(fmt.Sprintf("📖 API 文件： http://%s:%d/swagger/index.html", cfg.Server.Host, cfg.Server.Port))
		logger.Info(fmt.Sprintf("❤️  健康檢查： http://%s:%d/health", cfg.Server.Host, cfg.Server.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("❌ 服務器啟動失敗", "error", err)
		}
	}()

	// 等待中斷信號以優雅地關閉服務器
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("🛑 正在關閉服務器...")

	// 優雅關閉，等待現有連接完成
	ctx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("❌ 服務器強制關閉", "error", err)
	}

	// 關閉資料庫連接
	sqlDB, _ := db.DB()
	if sqlDB != nil {
		sqlDB.Close()
	}

	// 關閉 Redis 連接
	redisClient.Close()

	logger.Info("✅ 服務器已安全關閉")
}

// corsMiddleware CORS 中間件
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}



