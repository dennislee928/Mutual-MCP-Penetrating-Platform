package logger

import (
	"log/slog"
	"os"
)

// Logger 日誌記錄器
type Logger struct {
	logger *slog.Logger
}

// NewLogger 建立新的 logger
func NewLogger(mode string) *Logger {
	var level slog.Level

	switch mode {
	case "debug":
		level = slog.LevelDebug
	case "release":
		level = slog.LevelInfo
	case "test":
		level = slog.LevelWarn
	default:
		level = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{
		Level: level,
	}

	// 使用 JSON 格式的 handler（便於日誌聚合系統解析）
	handler := slog.NewJSONHandler(os.Stdout, opts)
	logger := slog.New(handler)

	return &Logger{
		logger: logger,
	}
}

// Debug 記錄 debug 級別日誌
func (l *Logger) Debug(msg string, args ...any) {
	l.logger.Debug(msg, args...)
}

// Info 記錄 info 級別日誌
func (l *Logger) Info(msg string, args ...any) {
	l.logger.Info(msg, args...)
}

// Warn 記錄 warn 級別日誌
func (l *Logger) Warn(msg string, args ...any) {
	l.logger.Warn(msg, args...)
}

// Error 記錄 error 級別日誌
func (l *Logger) Error(msg string, args ...any) {
	l.logger.Error(msg, args...)
}

// Fatal 記錄 fatal 級別日誌並退出
func (l *Logger) Fatal(msg string, args ...any) {
	l.logger.Error(msg, args...)
	os.Exit(1)
}

// With 建立帶有預設欄位的子 logger
func (l *Logger) With(args ...any) *Logger {
	return &Logger{
		logger: l.logger.With(args...),
	}
}

// WithGroup 建立帶有群組的子 logger
func (l *Logger) WithGroup(name string) *Logger {
	return &Logger{
		logger: l.logger.WithGroup(name),
	}
}


