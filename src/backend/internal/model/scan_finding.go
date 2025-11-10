package model

import (
	"time"
)

// ScanFinding 掃描發現模型
type ScanFinding struct {
	ID           uint      `gorm:"primarykey" json:"id"`
	ScanJobID    uint      `gorm:"not null;index" json:"scan_job_id"`
	Severity     string    `gorm:"not null;size:20;check:severity IN ('critical', 'high', 'medium', 'low', 'info')" json:"severity"`
	Title        string    `gorm:"not null;size:255" json:"title"`
	Description  string    `gorm:"type:text" json:"description,omitempty"`
	Host         string    `gorm:"size:255;index" json:"host,omitempty"`
	Port         int       `json:"port,omitempty"`
	Protocol     string    `gorm:"size:20" json:"protocol,omitempty"`
	CVSSScore    *float64  `gorm:"type:decimal(3,1)" json:"cvss_score,omitempty"`
	CVEID        string    `gorm:"size:50" json:"cve_id,omitempty"`
	CWEID        string    `gorm:"size:50" json:"cwe_id,omitempty"`
	Evidence     string    `gorm:"type:jsonb;default:'{}'" json:"evidence,omitempty"`
	Remediation  string    `gorm:"type:text" json:"remediation,omitempty"`
	References   string    `gorm:"type:text[]" json:"references,omitempty"`
	DiscoveredAt time.Time `gorm:"index" json:"discovered_at"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// 關聯
	ScanJob *ScanJob `gorm:"foreignKey:ScanJobID" json:"-"`
}

// TableName 指定表名
func (ScanFinding) TableName() string {
	return "scan_findings"
}

// IsCritical 判斷是否為高危發現
func (f *ScanFinding) IsCritical() bool {
	return f.Severity == "critical"
}

// IsHighRisk 判斷是否為高風險發現
func (f *ScanFinding) IsHighRisk() bool {
	return f.Severity == "critical" || f.Severity == "high"
}

// SeverityScore 取得嚴重性分數（用於排序）
func (f *ScanFinding) SeverityScore() int {
	switch f.Severity {
	case "critical":
		return 5
	case "high":
		return 4
	case "medium":
		return 3
	case "low":
		return 2
	case "info":
		return 1
	default:
		return 0
	}
}



