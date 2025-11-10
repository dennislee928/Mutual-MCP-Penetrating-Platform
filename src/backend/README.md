# 統一安全平台 - Go 後端服務

> 雲原生安全與基礎設施管理的統一平台後端 API

## 📋 目錄

- [概述](#概述)
- [技術棧](#技術棧)
- [專案結構](#專案結構)
- [快速開始](#快速開始)
- [開發指南](#開發指南)
- [API 文件](#api-文件)
- [部署](#部署)

## 概述

這是統一安全平台的 Go 後端服務，負責：

- 🛡️ 安全掃描任務管理
- 🚨 安全事件監控與告警
- 🤖 與 HexStrike AI 和 AI/量子服務整合
- 📊 監控指標收集與暴露
- 🔐 身份驗證與授權

## 技術棧

- **語言**: Go 1.24+
- **框架**: Gin（Web 框架）
- **ORM**: GORM（資料庫 ORM）
- **資料庫**: PostgreSQL 15+
- **快取**: Redis 7+
- **驗證**: go-playground/validator
- **日誌**: slog（標準庫）
- **配置**: 環境變數
- **遷移**: golang-migrate
- **文件**: Swagger/OpenAPI

## 專案結構

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # 應用程式入口
├── internal/                    # 內部包（不可被外部引用）
│   ├── model/                   # GORM 資料模型
│   ├── dto/                     # 請求 DTO（Data Transfer Object）
│   ├── vo/                      # 回應 VO（Value Object）
│   ├── handler/                 # HTTP 處理器（Controller）
│   ├── service/                 # 業務邏輯層
│   ├── repository/              # 資料存取層
│   └── middleware/              # 中間件
├── pkg/                         # 公共包（可被外部引用）
│   ├── database/                # 資料庫工具
│   ├── redis/                   # Redis 客戶端
│   └── logger/                  # 日誌工具
├── config/                      # 配置管理
├── database/
│   └── migrations/              # SQL 遷移檔案
├── docs/                        # Swagger 文件（自動生成）
├── go.mod                       # Go 模組定義
├── go.sum                       # 依賴校驗和
├── Makefile                     # Make 指令
└── README.md                    # 本文件
```

## 快速開始

### 前置需求

- Go 1.24 或更高版本
- PostgreSQL 15+
- Redis 7+ （可選，用於快取）
- Make（可選，用於執行 Makefile 指令）

### 安裝

1. **克隆專案**（如果還沒有）

```bash
git clone <repo-url>
cd src/backend
```

2. **安裝依賴**

```bash
go mod download
# 或使用 Makefile
make deps
```

3. **設定環境變數**

建立 `.env` 檔案：

```env
# 伺服器配置
SERVER_PORT=3001
SERVER_HOST=0.0.0.0
GIN_MODE=debug

# 資料庫配置
DB_HOST=localhost
DB_PORT=5432
DB_USER=sectools
DB_PASSWORD=your_secure_password
DB_NAME=sectools
DB_SSLMODE=disable

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT 配置
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRATION=24h

# 外部服務配置
HEXSTRIKE_URL=http://localhost:8888
AI_QUANTUM_URL=http://localhost:8000
VAULT_ADDR=http://localhost:8200
VAULT_TOKEN=root
```

4. **執行資料庫遷移**

```bash
# 使用 golang-migrate（需先安裝）
make migrate-up

# 或直接使用 GORM AutoMigrate（程式會自動執行）
```

5. **啟動服務**

```bash
# 開發模式
make dev

# 或建置後執行
make build
make run

# 或直接執行
go run cmd/server/main.go
```

服務將在 http://localhost:3001 啟動。

### 驗證安裝

```bash
# 健康檢查
curl http://localhost:3001/health

# 應該回傳
{
  "status": "ok",
  "service": "unified-security-platform-backend",
  "version": "1.0.0",
  "time": "2025-11-10T10:00:00Z"
}
```

## 開發指南

### 可用指令

```bash
make help           # 顯示所有可用指令
make build          # 建置應用程式
make run            # 執行應用程式
make dev            # 開發模式（hot reload）
make test           # 執行測試
make test-coverage  # 測試覆蓋率
make lint           # 程式碼檢查
make clean          # 清理建置檔案
make swagger        # 產生 Swagger 文件
```

### 添加新功能

#### 1. 建立 Model（資料模型）

```go
// internal/model/scan_job.go
package model

import (
    "time"
    "gorm.io/gorm"
)

type ScanJob struct {
    ID          uint           `gorm:"primarykey"`
    Target      string         `gorm:"not null"`
    ScanType    string         `gorm:"not null"`
    Status      string         `gorm:"default:pending"`
    StartedAt   *time.Time
    CompletedAt *time.Time
    CreatedAt   time.Time
    UpdatedAt   time.Time
    DeletedAt   gorm.DeletedAt `gorm:"index"`
}
```

#### 2. 建立 DTO/VO（資料傳輸物件）

```go
// internal/dto/scan_request.go
package dto

type CreateScanRequest struct {
    Target   string `json:"target" binding:"required,url"`
    ScanType string `json:"scan_type" binding:"required,oneof=nuclei nmap amass"`
}

// internal/vo/scan_response.go
package vo

type ScanResponse struct {
    ID       uint   `json:"id"`
    Target   string `json:"target"`
    ScanType string `json:"scan_type"`
    Status   string `json:"status"`
}
```

#### 3. 建立 Service（業務邏輯）

```go
// internal/service/scan_service.go
package service

type ScanService struct {
    repo repository.ScanRepository
}

func NewScanService(repo repository.ScanRepository) *ScanService {
    return &ScanService{repo: repo}
}

func (s *ScanService) CreateScan(dto *dto.CreateScanRequest) (*vo.ScanResponse, error) {
    // 業務邏輯
}
```

#### 4. 建立 Handler（路由處理器）

```go
// internal/handler/scan_handler.go
package handler

type ScanHandler struct {
    service *service.ScanService
}

func (h *ScanHandler) CreateScan(c *gin.Context) {
    var req dto.CreateScanRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    // 呼叫 service
}
```

### 程式碼風格

- 遵循 [Effective Go](https://golang.org/doc/effective_go.html)
- 使用 `gofmt` 格式化程式碼
- 使用 `golangci-lint` 進行靜態分析
- 所有公開函式和類型必須有註解
- 錯誤處理不可忽略

### 測試

```bash
# 執行所有測試
make test

# 執行特定包的測試
go test ./internal/service/...

# 執行測試並顯示覆蓋率
make test-coverage
```

## API 文件

### Swagger UI

開發模式下，可訪問 Swagger UI：

```
http://localhost:3001/swagger/index.html
```

### 主要端點

#### 健康檢查

```http
GET /health
```

#### 掃描管理

```http
GET    /api/v1/scans          # 取得掃描列表
POST   /api/v1/scans          # 建立新掃描
GET    /api/v1/scans/:id      # 取得掃描詳情
DELETE /api/v1/scans/:id      # 刪除掃描
```

#### 安全事件

```http
GET /api/v1/security-events   # 取得安全事件列表
```

#### 監控指標

```http
GET /api/v1/metrics/summary            # 取得指標摘要
GET /metrics/prometheus                # Prometheus 指標端點
```

#### 整合端點

```http
POST /api/v1/integration/hexstrike/scan      # 觸發 HexStrike 掃描
POST /api/v1/integration/ai-quantum/analyze  # 觸發 AI 威脅分析
```

## 部署

### Docker 部署

```bash
# 建置映像
make docker-build

# 執行容器
make docker-run
```

### Kubernetes 部署

參見 `../../infrastructure/kubernetes/backend-deployment.yaml`

## 環境變數

| 變數名稱 | 描述 | 預設值 | 必填 |
|---------|------|--------|------|
| `SERVER_PORT` | HTTP 伺服器埠號 | 3001 | 否 |
| `GIN_MODE` | Gin 模式 (debug/release/test) | debug | 否 |
| `DB_HOST` | PostgreSQL 主機 | localhost | 是 |
| `DB_PORT` | PostgreSQL 埠號 | 5432 | 否 |
| `DB_USER` | 資料庫使用者 | sectools | 是 |
| `DB_PASSWORD` | 資料庫密碼 | - | 是 |
| `DB_NAME` | 資料庫名稱 | sectools | 是 |
| `REDIS_HOST` | Redis 主機 | localhost | 否 |
| `REDIS_PORT` | Redis 埠號 | 6379 | 否 |
| `JWT_SECRET` | JWT 密鑰 | - | 是 |
| `HEXSTRIKE_URL` | HexStrike AI 服務 URL | http://localhost:8888 | 否 |
| `AI_QUANTUM_URL` | AI/量子服務 URL | http://localhost:8000 | 否 |

## 故障排除

### 資料庫連接失敗

```
Error: 無法連接到 PostgreSQL
```

**解決方法**:
1. 確認 PostgreSQL 服務正在執行
2. 檢查 `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD` 環境變數
3. 確認資料庫 `sectools` 已建立

### Redis 連接失敗

```
Warning: Redis 連接失敗，部分功能可能受限
```

**解決方法**:
- Redis 是可選的，不影響核心功能
- 如需使用快取功能，請確認 Redis 服務正在執行

## 授權

MIT License

## 貢獻

請參閱根目錄的 `CONTRIBUTING.md`

## 支援

如有問題，請提交 Issue。


