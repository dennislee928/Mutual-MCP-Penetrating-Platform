package service

import (
	"errors"
	"time"

	"github.com/dennislwm/unified-security-platform/backend/internal/dto"
	"github.com/dennislwm/unified-security-platform/backend/internal/model"
	"github.com/dennislwm/unified-security-platform/backend/internal/repository"
	"github.com/dennislwm/unified-security-platform/backend/internal/vo"
	"gorm.io/gorm"
)

// ScanService 掃描業務邏輯層
type ScanService struct {
	repo *repository.ScanRepository
}

// NewScanService 建立新的 ScanService
func NewScanService(repo *repository.ScanRepository) *ScanService {
	return &ScanService{repo: repo}
}

// CreateScan 建立新的掃描任務
func (s *ScanService) CreateScan(req *dto.CreateScanRequest) (*vo.ScanJobResponse, error) {
	// 建立 Model
	scan := &model.ScanJob{
		Target:   req.Target,
		ScanType: req.ScanType,
		Status:   "pending",
	}

	// 儲存到資料庫
	if err := s.repo.Create(scan); err != nil {
		return nil, err
	}

	// 轉換為 VO 並返回
	response := vo.FromScanJob(scan)
	return &response, nil
}

// GetScanByID 根據 ID 取得掃描任務
func (s *ScanService) GetScanByID(id uint) (*vo.ScanJobDetailResponse, error) {
	// 從資料庫查詢
	scan, err := s.repo.FindByIDWithFindings(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("掃描任務不存在")
		}
		return nil, err
	}

	// 轉換為 VO 並返回
	response := vo.FromScanJobWithFindings(scan)
	return &response, nil
}

// GetScans 取得掃描任務列表（分頁）
func (s *ScanService) GetScans(params *dto.ScanQueryParams) (*vo.PaginatedResponse, error) {
	// 設定預設值
	if params.Page == 0 {
		params.Page = 1
	}
	if params.PageSize == 0 {
		params.PageSize = 10
	}

	// 從資料庫查詢
	scans, total, err := s.repo.FindAll(params)
	if err != nil {
		return nil, err
	}

	// 轉換為 VO
	scanResponses := make([]vo.ScanJobResponse, 0, len(scans))
	for i := range scans {
		scanResponses = append(scanResponses, vo.FromScanJob(&scans[i]))
	}

	// 計算總頁數
	totalPages := int(total) / params.PageSize
	if int(total)%params.PageSize != 0 {
		totalPages++
	}

	// 建立分頁回應
	response := &vo.PaginatedResponse{
		Data:       scanResponses,
		Page:       params.Page,
		PageSize:   params.PageSize,
		TotalCount: total,
		TotalPages: totalPages,
	}

	return response, nil
}

// UpdateScanStatus 更新掃描任務狀態
func (s *ScanService) UpdateScanStatus(id uint, status string) error {
	// 查詢掃描任務
	scan, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("掃描任務不存在")
		}
		return err
	}

	// 更新狀態
	scan.Status = status
	if status == "running" && scan.StartedAt == nil {
		now := time.Now()
		scan.StartedAt = &now
	}
	if status == "completed" || status == "failed" {
		now := time.Now()
		scan.CompletedAt = &now
	}

	// 儲存變更
	return s.repo.Update(scan)
}

// DeleteScan 刪除掃描任務
func (s *ScanService) DeleteScan(id uint) error {
	// 檢查是否存在
	_, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("掃描任務不存在")
		}
		return err
	}

	// 執行刪除
	return s.repo.Delete(id)
}

// GetMetrics 取得掃描統計指標
func (s *ScanService) GetMetrics() (*vo.MetricsResponse, error) {
	// 取得按狀態統計
	byStatus, err := s.repo.CountByStatus()
	if err != nil {
		return nil, err
	}

	// 取得按類型統計
	byType, err := s.repo.CountByScanType()
	if err != nil {
		return nil, err
	}

	// 計算總數
	var total int64
	for _, count := range byStatus {
		total += count
	}

	response := &vo.MetricsResponse{
		ScansTotal: total,
		ByType:     byType,
	}

	return response, nil
}


