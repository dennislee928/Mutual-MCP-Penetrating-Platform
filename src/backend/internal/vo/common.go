package vo

// ErrorResponse 錯誤回應
type ErrorResponse struct {
	Error   string                 `json:"error"`
	Message string                 `json:"message,omitempty"`
	Code    string                 `json:"code,omitempty"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// SuccessResponse 成功回應
type SuccessResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

// HealthResponse 健康檢查回應
type HealthResponse struct {
	Status  string `json:"status"`
	Service string `json:"service"`
	Version string `json:"version"`
	Time    string `json:"time"`
}

// MetricsResponse 監控指標回應
type MetricsResponse struct {
	ScansTotal     int64            `json:"scans_total"`
	EventsTotal    int64            `json:"events_total"`
	ThreatsBlocked int64            `json:"threats_blocked"`
	ByType         map[string]int64 `json:"by_type,omitempty"`
	BySeverity     map[string]int64 `json:"by_severity,omitempty"`
}


