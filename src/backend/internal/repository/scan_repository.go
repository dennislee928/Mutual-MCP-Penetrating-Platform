package repository

import (
	"github.com/dennislwm/unified-security-platform/backend/internal/dto"
	"github.com/dennislwm/unified-security-platform/backend/internal/model"
	"gorm.io/gorm"
)

// ScanRepository 掃描資料存取層
type ScanRepository struct {
	db *gorm.DB
}

// NewScanRepository 建立新的 ScanRepository
func NewScanRepository(db *gorm.DB) *ScanRepository {
	return &ScanRepository{db: db}
}

// Create 建立新的掃描任務
func (r *ScanRepository) Create(scan *model.ScanJob) error {
	return r.db.Create(scan).Error
}

// FindByID 根據 ID 查詢掃描任務
func (r *ScanRepository) FindByID(id uint) (*model.ScanJob, error) {
	var scan model.ScanJob
	err := r.db.First(&scan, id).Error
	return &scan, err
}

// FindByIDWithFindings 根據 ID 查詢掃描任務（包含發現）
func (r *ScanRepository) FindByIDWithFindings(id uint) (*model.ScanJob, error) {
	var scan model.ScanJob
	err := r.db.Preload("Findings").First(&scan, id).Error
	return &scan, err
}

// FindAll 查詢所有掃描任務（分頁）
func (r *ScanRepository) FindAll(params *dto.ScanQueryParams) ([]model.ScanJob, int64, error) {
	var scans []model.ScanJob
	var total int64

	query := r.db.Model(&model.ScanJob{})

	// 應用過濾條件
	if params.Status != "" {
		query = query.Where("status = ?", params.Status)
	}
	if params.ScanType != "" {
		query = query.Where("scan_type = ?", params.ScanType)
	}
	if params.Target != "" {
		query = query.Where("target LIKE ?", "%"+params.Target+"%")
	}

	// 計算總數
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 應用分頁
	if params.Page > 0 && params.PageSize > 0 {
		offset := (params.Page - 1) * params.PageSize
		query = query.Offset(offset).Limit(params.PageSize)
	}

	// 排序並查詢
	err := query.Order("created_at DESC").Find(&scans).Error
	return scans, total, err
}

// Update 更新掃描任務
func (r *ScanRepository) Update(scan *model.ScanJob) error {
	return r.db.Save(scan).Error
}

// Delete 軟刪除掃描任務
func (r *ScanRepository) Delete(id uint) error {
	return r.db.Delete(&model.ScanJob{}, id).Error
}

// CountByStatus 根據狀態統計掃描任務數量
func (r *ScanRepository) CountByStatus() (map[string]int64, error) {
	type Result struct {
		Status string
		Count  int64
	}

	var results []Result
	err := r.db.Model(&model.ScanJob{}).
		Select("status, COUNT(*) as count").
		Group("status").
		Find(&results).Error

	if err != nil {
		return nil, err
	}

	counts := make(map[string]int64)
	for _, r := range results {
		counts[r.Status] = r.Count
	}

	return counts, nil
}

// CountByScanType 根據掃描類型統計數量
func (r *ScanRepository) CountByScanType() (map[string]int64, error) {
	type Result struct {
		ScanType string
		Count    int64
	}

	var results []Result
	err := r.db.Model(&model.ScanJob{}).
		Select("scan_type, COUNT(*) as count").
		Group("scan_type").
		Find(&results).Error

	if err != nil {
		return nil, err
	}

	counts := make(map[string]int64)
	for _, r := range results {
		counts[r.ScanType] = r.Count
	}

	return counts, nil
}



