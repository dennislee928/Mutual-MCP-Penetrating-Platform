package handler

import (
	"net/http"
	"strconv"

	"github.com/dennislwm/unified-security-platform/backend/internal/dto"
	"github.com/dennislwm/unified-security-platform/backend/internal/service"
	"github.com/dennislwm/unified-security-platform/backend/internal/vo"
	"github.com/gin-gonic/gin"
)

// ScanHandler 掃描處理器
type ScanHandler struct {
	service *service.ScanService
}

// NewScanHandler 建立新的 ScanHandler
func NewScanHandler(service *service.ScanService) *ScanHandler {
	return &ScanHandler{service: service}
}

// CreateScan 建立掃描任務
// @Summary 建立新的掃描任務
// @Description 建立一個新的安全掃描任務
// @Tags scans
// @Accept json
// @Produce json
// @Param scan body dto.CreateScanRequest true "掃描任務資訊"
// @Success 201 {object} vo.ScanJobResponse
// @Failure 400 {object} vo.ErrorResponse
// @Failure 500 {object} vo.ErrorResponse
// @Router /scans [post]
func (h *ScanHandler) CreateScan(c *gin.Context) {
	var req dto.CreateScanRequest

	// 綁定並驗證請求
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, vo.ErrorResponse{
			Error:   "invalid_request",
			Message: err.Error(),
		})
		return
	}

	// 呼叫 service
	scan, err := h.service.CreateScan(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, vo.ErrorResponse{
			Error:   "create_failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, scan)
}

// GetScan 取得掃描任務詳情
// @Summary 取得掃描任務詳情
// @Description 根據 ID 取得掃描任務的詳細資訊（包含發現）
// @Tags scans
// @Produce json
// @Param id path int true "掃描任務 ID"
// @Success 200 {object} vo.ScanJobDetailResponse
// @Failure 404 {object} vo.ErrorResponse
// @Failure 500 {object} vo.ErrorResponse
// @Router /scans/{id} [get]
func (h *ScanHandler) GetScan(c *gin.Context) {
	// 解析 ID
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, vo.ErrorResponse{
			Error:   "invalid_id",
			Message: "無效的掃描任務 ID",
		})
		return
	}

	// 呼叫 service
	scan, err := h.service.GetScanByID(uint(id))
	if err != nil {
		if err.Error() == "掃描任務不存在" {
			c.JSON(http.StatusNotFound, vo.ErrorResponse{
				Error:   "not_found",
				Message: err.Error(),
			})
			return
		}
		c.JSON(http.StatusInternalServerError, vo.ErrorResponse{
			Error:   "query_failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, scan)
}

// GetScans 取得掃描任務列表
// @Summary 取得掃描任務列表
// @Description 取得掃描任務列表（支援分頁和過濾）
// @Tags scans
// @Produce json
// @Param page query int false "頁碼" default(1)
// @Param page_size query int false "每頁數量" default(10)
// @Param status query string false "狀態過濾"
// @Param scan_type query string false "類型過濾"
// @Param target query string false "目標過濾"
// @Success 200 {object} vo.PaginatedResponse
// @Failure 400 {object} vo.ErrorResponse
// @Failure 500 {object} vo.ErrorResponse
// @Router /scans [get]
func (h *ScanHandler) GetScans(c *gin.Context) {
	var params dto.ScanQueryParams

	// 綁定查詢參數
	if err := c.ShouldBindQuery(&params); err != nil {
		c.JSON(http.StatusBadRequest, vo.ErrorResponse{
			Error:   "invalid_params",
			Message: err.Error(),
		})
		return
	}

	// 呼叫 service
	scans, err := h.service.GetScans(&params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, vo.ErrorResponse{
			Error:   "query_failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, scans)
}

// UpdateScanStatus 更新掃描狀態
// @Summary 更新掃描狀態
// @Description 更新掃描任務的狀態
// @Tags scans
// @Accept json
// @Produce json
// @Param id path int true "掃描任務 ID"
// @Param update body dto.UpdateScanRequest true "更新資訊"
// @Success 200 {object} vo.SuccessResponse
// @Failure 400 {object} vo.ErrorResponse
// @Failure 404 {object} vo.ErrorResponse
// @Failure 500 {object} vo.ErrorResponse
// @Router /scans/{id} [patch]
func (h *ScanHandler) UpdateScanStatus(c *gin.Context) {
	// 解析 ID
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, vo.ErrorResponse{
			Error:   "invalid_id",
			Message: "無效的掃描任務 ID",
		})
		return
	}

	var req dto.UpdateScanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, vo.ErrorResponse{
			Error:   "invalid_request",
			Message: err.Error(),
		})
		return
	}

	// 更新狀態
	if req.Status != nil {
		if err := h.service.UpdateScanStatus(uint(id), *req.Status); err != nil {
			if err.Error() == "掃描任務不存在" {
				c.JSON(http.StatusNotFound, vo.ErrorResponse{
					Error:   "not_found",
					Message: err.Error(),
				})
				return
			}
			c.JSON(http.StatusInternalServerError, vo.ErrorResponse{
				Error:   "update_failed",
				Message: err.Error(),
			})
			return
		}
	}

	c.JSON(http.StatusOK, vo.SuccessResponse{
		Success: true,
		Message: "掃描狀態已更新",
	})
}

// DeleteScan 刪除掃描任務
// @Summary 刪除掃描任務
// @Description 軟刪除掃描任務
// @Tags scans
// @Produce json
// @Param id path int true "掃描任務 ID"
// @Success 200 {object} vo.SuccessResponse
// @Failure 400 {object} vo.ErrorResponse
// @Failure 404 {object} vo.ErrorResponse
// @Failure 500 {object} vo.ErrorResponse
// @Router /scans/{id} [delete]
func (h *ScanHandler) DeleteScan(c *gin.Context) {
	// 解析 ID
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, vo.ErrorResponse{
			Error:   "invalid_id",
			Message: "無效的掃描任務 ID",
		})
		return
	}

	// 呼叫 service
	if err := h.service.DeleteScan(uint(id)); err != nil {
		if err.Error() == "掃描任務不存在" {
			c.JSON(http.StatusNotFound, vo.ErrorResponse{
				Error:   "not_found",
				Message: err.Error(),
			})
			return
		}
		c.JSON(http.StatusInternalServerError, vo.ErrorResponse{
			Error:   "delete_failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, vo.SuccessResponse{
		Success: true,
		Message: "掃描任務已刪除",
	})
}

// GetMetrics 取得掃描指標
// @Summary 取得掃描統計指標
// @Description 取得掃描任務的統計資訊
// @Tags scans
// @Produce json
// @Success 200 {object} vo.MetricsResponse
// @Failure 500 {object} vo.ErrorResponse
// @Router /scans/metrics [get]
func (h *ScanHandler) GetMetrics(c *gin.Context) {
	metrics, err := h.service.GetMetrics()
	if err != nil {
		c.JSON(http.StatusInternalServerError, vo.ErrorResponse{
			Error:   "query_failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, metrics)
}



