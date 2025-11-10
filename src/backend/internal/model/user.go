package model

import (
	"time"

	"gorm.io/gorm"
)

// User 使用者模型
type User struct {
	ID           uint           `gorm:"primarykey" json:"id"`
	Username     string         `gorm:"uniqueIndex;not null;size:100" json:"username"`
	Email        string         `gorm:"uniqueIndex;not null;size:255" json:"email"`
	PasswordHash string         `gorm:"not null;size:255" json:"-"` // 不返回給前端
	FullName     string         `gorm:"size:255" json:"full_name,omitempty"`
	Role         string         `gorm:"default:user;size:50;check:role IN ('admin', 'analyst', 'user', 'readonly')" json:"role"`
	IsActive     bool           `gorm:"default:true" json:"is_active"`
	LastLogin    *time.Time     `json:"last_login,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName 指定表名
func (User) TableName() string {
	return "users"
}

// IsAdmin 檢查是否為管理員
func (u *User) IsAdmin() bool {
	return u.Role == "admin"
}

// IsAnalyst 檢查是否為分析師
func (u *User) IsAnalyst() bool {
	return u.Role == "analyst"
}

// CanWrite 檢查是否有寫入權限
func (u *User) CanWrite() bool {
	return u.Role == "admin" || u.Role == "analyst" || u.Role == "user"
}

// CanRead 檢查是否有讀取權限
func (u *User) CanRead() bool {
	return u.IsActive // 所有啟用的使用者都可讀取
}



