package redis

import (
	"context"
	"fmt"
	"time"

	"github.com/dennislwm/unified-security-platform/backend/config"
	"github.com/redis/go-redis/v9"
)

// Client Redis 客戶端包裝器
type Client struct {
	client *redis.Client
}

// NewRedisClient 建立新的 Redis 客戶端
func NewRedisClient(cfg *config.RedisConfig) *Client {
	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.RedisAddr(),
		Password: cfg.Password,
		DB:       cfg.DB,
	})

	return &Client{
		client: rdb,
	}
}

// Ping 測試 Redis 連接
func (c *Client) Ping(ctx context.Context) error {
	return c.client.Ping(ctx).Err()
}

// Set 設定鍵值對
func (c *Client) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return c.client.Set(ctx, key, value, expiration).Err()
}

// Get 取得值
func (c *Client) Get(ctx context.Context, key string) (string, error) {
	return c.client.Get(ctx, key).Result()
}

// Del 刪除鍵
func (c *Client) Del(ctx context.Context, keys ...string) error {
	return c.client.Del(ctx, keys...).Err()
}

// Exists 檢查鍵是否存在
func (c *Client) Exists(ctx context.Context, keys ...string) (int64, error) {
	return c.client.Exists(ctx, keys...).Result()
}

// Expire 設定過期時間
func (c *Client) Expire(ctx context.Context, key string, expiration time.Duration) error {
	return c.client.Expire(ctx, key, expiration).Err()
}

// Incr 遞增
func (c *Client) Incr(ctx context.Context, key string) (int64, error) {
	return c.client.Incr(ctx, key).Result()
}

// Decr 遞減
func (c *Client) Decr(ctx context.Context, key string) (int64, error) {
	return c.client.Decr(ctx, key).Result()
}

// HSet 設定 hash 欄位
func (c *Client) HSet(ctx context.Context, key string, values ...interface{}) error {
	return c.client.HSet(ctx, key, values...).Err()
}

// HGet 取得 hash 欄位
func (c *Client) HGet(ctx context.Context, key, field string) (string, error) {
	return c.client.HGet(ctx, key, field).Result()
}

// HGetAll 取得 hash 所有欄位
func (c *Client) HGetAll(ctx context.Context, key string) (map[string]string, error) {
	return c.client.HGetAll(ctx, key).Result()
}

// LPush 從左側推入列表
func (c *Client) LPush(ctx context.Context, key string, values ...interface{}) error {
	return c.client.LPush(ctx, key, values...).Err()
}

// RPush 從右側推入列表
func (c *Client) RPush(ctx context.Context, key string, values ...interface{}) error {
	return c.client.RPush(ctx, key, values...).Err()
}

// LRange 取得列表範圍
func (c *Client) LRange(ctx context.Context, key string, start, stop int64) ([]string, error) {
	return c.client.LRange(ctx, key, start, stop).Result()
}

// SAdd 添加到集合
func (c *Client) SAdd(ctx context.Context, key string, members ...interface{}) error {
	return c.client.SAdd(ctx, key, members...).Err()
}

// SMembers 取得集合所有成員
func (c *Client) SMembers(ctx context.Context, key string) ([]string, error) {
	return c.client.SMembers(ctx, key).Result()
}

// Close 關閉 Redis 連接
func (c *Client) Close() error {
	return c.client.Close()
}

// GetClient 取得原生 Redis 客戶端（用於進階操作）
func (c *Client) GetClient() *redis.Client {
	return c.client
}

// Pipeline 建立管道
func (c *Client) Pipeline() redis.Pipeliner {
	return c.client.Pipeline()
}

// Watch 監聽鍵的變化（樂觀鎖）
func (c *Client) Watch(ctx context.Context, fn func(*redis.Tx) error, keys ...string) error {
	return c.client.Watch(ctx, fn, keys...)
}

// FlushDB 清空當前資料庫（謹慎使用）
func (c *Client) FlushDB(ctx context.Context) error {
	return c.client.FlushDB(ctx).Err()
}

// Info 取得 Redis 伺服器資訊
func (c *Client) Info(ctx context.Context) (string, error) {
	return c.client.Info(ctx).Result()
}

// Stats 取得 Redis 統計資訊
func (c *Client) Stats() string {
	stats := c.client.PoolStats()
	return fmt.Sprintf("Hits=%d Misses=%d Timeouts=%d TotalConns=%d IdleConns=%d StaleConns=%d",
		stats.Hits, stats.Misses, stats.Timeouts, stats.TotalConns, stats.IdleConns, stats.StaleConns)
}





