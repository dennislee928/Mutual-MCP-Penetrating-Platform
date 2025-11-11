package model

import (
	"time"

	"gorm.io/gorm"
)

// ScanJob 掃描任務模型
type ScanJob struct {
	ID           uint           `gorm:"primarykey" json:"id"`
	Target       string         `gorm:"not null;size:255" json:"target"`
	ScanType     string         `gorm:"not null;size:50;check:scan_type IN ('nuclei', 'nmap', 'amass', 'custom')" json:"scan_type"`
	Status       string         `gorm:"default:pending;size:50;check:status IN ('pending', 'running', 'completed', 'failed', 'cancelled')" json:"status"`
	StartedAt    *time.Time     `json:"started_at,omitempty"`
	CompletedAt  *time.Time     `json:"completed_at,omitempty"`
	ErrorMessage string         `gorm:"type:text" json:"error_message,omitempty"`
	Metadata     string         `gorm:"type:jsonb;default:'{}'" json:"metadata,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	// 關聯
	Findings []ScanFinding `gorm:"foreignKey:ScanJobID;constraint:OnDelete:CASCADE" json:"findings,omitempty"`
}

// TableName 指定表名
func (ScanJob) TableName() string {
	return "scan_jobs"
}

// BeforeCreate GORM hook：建立前執行
func (s *ScanJob) BeforeCreate(tx *gorm.DB) error {
	// 可以在這裡添加建立前的驗證邏輯
	return nil
}

// IsCompleted 檢查掃描是否已完成
func (s *ScanJob) IsCompleted() bool {
	return s.Status == "completed"
}

// IsFailed 檢查掃描是否失敗
func (s *ScanJob) IsFailed() bool {
	return s.Status == "failed"
}

// IsRunning 檢查掃描是否正在執行
func (s *ScanJob) IsRunning() bool {
	return s.Status == "running"
}

// Duration 計算掃描執行時間
func (s *ScanJob) Duration() time.Duration {
	if s.StartedAt == nil || s.CompletedAt == nil {
		return 0
	}
	return s.CompletedAt.Sub(*s.StartedAt)
}





