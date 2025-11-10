package model

import (
	"time"
)

// SecurityEvent 安全事件模型
type SecurityEvent struct {
	ID          uint       `gorm:"primarykey" json:"id"`
	EventType   string     `gorm:"not null;size:50;check:event_type IN ('intrusion', 'anomaly', 'threat', 'alert', 'incident')" json:"event_type"`
	Severity    string     `gorm:"not null;size:20;check:severity IN ('critical', 'high', 'medium', 'low', 'info')" json:"severity"`
	Source      string     `gorm:"size:255" json:"source,omitempty"`
	Destination string     `gorm:"size:255" json:"destination,omitempty"`
	Description string     `gorm:"type:text;not null" json:"description"`
	Details     string     `gorm:"type:jsonb;default:'{}'" json:"details,omitempty"`
	Status      string     `gorm:"default:open;size:50;check:status IN ('open', 'investigating', 'resolved', 'false_positive')" json:"status"`
	AssignedTo  string     `gorm:"size:100" json:"assigned_to,omitempty"`
	ResolvedAt  *time.Time `json:"resolved_at,omitempty"`
	CreatedAt   time.Time  `gorm:"index" json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// TableName 指定表名
func (SecurityEvent) TableName() string {
	return "security_events"
}

// IsOpen 檢查事件是否開放中
func (e *SecurityEvent) IsOpen() bool {
	return e.Status == "open"
}

// IsResolved 檢查事件是否已解決
func (e *SecurityEvent) IsResolved() bool {
	return e.Status == "resolved"
}

// IsCritical 判斷是否為高危事件
func (e *SecurityEvent) IsCritical() bool {
	return e.Severity == "critical"
}

// ResolutionTime 計算解決時間
func (e *SecurityEvent) ResolutionTime() time.Duration {
	if e.ResolvedAt == nil {
		return 0
	}
	return e.ResolvedAt.Sub(e.CreatedAt)
}


