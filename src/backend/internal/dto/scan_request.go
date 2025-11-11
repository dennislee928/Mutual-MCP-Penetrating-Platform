package dto

// CreateScanRequest 建立掃描請求 DTO
type CreateScanRequest struct {
	Target   string            `json:"target" binding:"required"`
	ScanType string            `json:"scan_type" binding:"required,oneof=nuclei nmap amass custom"`
	Metadata map[string]string `json:"metadata,omitempty"`
}

// UpdateScanRequest 更新掃描請求 DTO
type UpdateScanRequest struct {
	Status       *string `json:"status,omitempty" binding:"omitempty,oneof=pending running completed failed cancelled"`
	ErrorMessage *string `json:"error_message,omitempty"`
}

// ScanQueryParams 掃描查詢參數
type ScanQueryParams struct {
	Page     int    `form:"page" binding:"omitempty,min=1"`
	PageSize int    `form:"page_size" binding:"omitempty,min=1,max=100"`
	Status   string `form:"status" binding:"omitempty,oneof=pending running completed failed cancelled"`
	ScanType string `form:"scan_type" binding:"omitempty,oneof=nuclei nmap amass custom"`
	Target   string `form:"target"`
}





