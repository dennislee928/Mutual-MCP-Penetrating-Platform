package database

import (
	"fmt"
	"time"

	"github.com/dennislwm/unified-security-platform/backend/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// NewPostgresDB 建立新的 PostgreSQL 資料庫連接
func NewPostgresDB(cfg *config.DatabaseConfig) (*gorm.DB, error) {
	dsn := cfg.DSN()

	// GORM 配置
	gormConfig := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
		NowFunc: func() time.Time {
			return time.Now().UTC()
		},
		// 命名策略：使用單數表名
		//NamingStrategy: schema.NamingStrategy{
		//	SingularTable: true,
		//},
	}

	// 連接資料庫
	db, err := gorm.Open(postgres.Open(dsn), gormConfig)
	if err != nil {
		return nil, fmt.Errorf("無法連接到 PostgreSQL: %w", err)
	}

	// 取得底層 sql.DB 以配置連接池
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("無法取得 sql.DB: %w", err)
	}

	// 設定連接池
	sqlDB.SetMaxOpenConns(cfg.MaxConns)
	sqlDB.SetMaxIdleConns(cfg.MaxIdle)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// 測試連接
	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("無法 ping PostgreSQL: %w", err)
	}

	return db, nil
}

// AutoMigrate 執行資料庫遷移
func AutoMigrate(db *gorm.DB, models ...interface{}) error {
	return db.AutoMigrate(models...)
}

// Close 關閉資料庫連接
func Close(db *gorm.DB) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}



