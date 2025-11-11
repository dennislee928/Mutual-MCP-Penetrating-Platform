package vo

import (
	"time"

	"github.com/dennislwm/unified-security-platform/backend/internal/model"
)

// ScanJobResponse 掃描任務回應 VO
type ScanJobResponse struct {
	ID           uint       `json:"id"`
	Target       string     `json:"target"`
	ScanType     string     `json:"scan_type"`
	Status       string     `json:"status"`
	StartedAt    *time.Time `json:"started_at,omitempty"`
	CompletedAt  *time.Time `json:"completed_at,omitempty"`
	Duration     string     `json:"duration,omitempty"`
	ErrorMessage string     `json:"error_message,omitempty"`
	Metadata     string     `json:"metadata,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// ScanJobDetailResponse 掃描任務詳情回應（包含發現）
type ScanJobDetailResponse struct {
	ScanJobResponse
	Findings []ScanFindingResponse `json:"findings,omitempty"`
}

// ScanFindingResponse 掃描發現回應 VO
type ScanFindingResponse struct {
	ID           uint      `json:"id"`
	ScanJobID    uint      `json:"scan_job_id"`
	Severity     string    `json:"severity"`
	Title        string    `json:"title"`
	Description  string    `json:"description,omitempty"`
	Host         string    `json:"host,omitempty"`
	Port         int       `json:"port,omitempty"`
	Protocol     string    `json:"protocol,omitempty"`
	CVSSScore    *float64  `json:"cvss_score,omitempty"`
	CVEID        string    `json:"cve_id,omitempty"`
	CWEID        string    `json:"cwe_id,omitempty"`
	Evidence     string    `json:"evidence,omitempty"`
	Remediation  string    `json:"remediation,omitempty"`
	References   string    `json:"references,omitempty"`
	DiscoveredAt time.Time `json:"discovered_at"`
}

// PaginatedResponse 分頁回應
type PaginatedResponse struct {
	Data       interface{} `json:"data"`
	Page       int         `json:"page"`
	PageSize   int         `json:"page_size"`
	TotalCount int64       `json:"total_count"`
	TotalPages int         `json:"total_pages"`
}

// FromScanJob 從 Model 轉換為 VO
func FromScanJob(job *model.ScanJob) ScanJobResponse {
	response := ScanJobResponse{
		ID:           job.ID,
		Target:       job.Target,
		ScanType:     job.ScanType,
		Status:       job.Status,
		StartedAt:    job.StartedAt,
		CompletedAt:  job.CompletedAt,
		ErrorMessage: job.ErrorMessage,
		Metadata:     job.Metadata,
		CreatedAt:    job.CreatedAt,
		UpdatedAt:    job.UpdatedAt,
	}

	// 計算執行時間
	if job.StartedAt != nil && job.CompletedAt != nil {
		duration := job.CompletedAt.Sub(*job.StartedAt)
		response.Duration = duration.String()
	}

	return response
}

// FromScanJobWithFindings 從 Model 轉換為詳情 VO
func FromScanJobWithFindings(job *model.ScanJob) ScanJobDetailResponse {
	response := ScanJobDetailResponse{
		ScanJobResponse: FromScanJob(job),
		Findings:        make([]ScanFindingResponse, 0, len(job.Findings)),
	}

	for _, finding := range job.Findings {
		response.Findings = append(response.Findings, FromScanFinding(&finding))
	}

	return response
}

// FromScanFinding 從 Model 轉換為 VO
func FromScanFinding(finding *model.ScanFinding) ScanFindingResponse {
	return ScanFindingResponse{
		ID:           finding.ID,
		ScanJobID:    finding.ScanJobID,
		Severity:     finding.Severity,
		Title:        finding.Title,
		Description:  finding.Description,
		Host:         finding.Host,
		Port:         finding.Port,
		Protocol:     finding.Protocol,
		CVSSScore:    finding.CVSSScore,
		CVEID:        finding.CVEID,
		CWEID:        finding.CWEID,
		Evidence:     finding.Evidence,
		Remediation:  finding.Remediation,
		References:   finding.References,
		DiscoveredAt: finding.DiscoveredAt,
	}
}





