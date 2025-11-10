# 統一安全平台 - Docker Compose 部署指南

## 📋 概述

本目錄包含統一安全平台的完整 Docker Compose 配置，整合了所有服務：

- 🔵 **Go 後端**：防禦面 API（端口 3001）
- 🟣 **Python AI/量子**：AI 威脅偵測與量子計算（端口 8000）
- 🔴 **Python HexStrike AI**：攻擊面滲透測試（端口 8888）
- 🟢 **Next.js 前端**：統一 Web UI（端口 3000）
- 🗄️ **PostgreSQL**：中央資料庫（端口 5432）
- 🔑 **Redis**：快取層（端口 6379）
- 🔐 **Vault**：密鑰管理（端口 8200）
- 📊 **Prometheus**：指標收集（端口 9090）
- 📈 **Grafana**：監控儀表板（端口 3002）
- 📜 **Loki**：日誌聚合（端口 3100）

## 🚀 快速開始

### 前置需求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 8GB RAM
- 至少 20GB 可用磁碟空間

### 步驟 1：配置環境變數

```bash
cd infrastructure/docker
cp .env.example .env
```

編輯 `.env` 檔案，至少修改以下內容：

```env
DB_PASSWORD=your_secure_database_password
JWT_SECRET=your_jwt_secret_key_min_32_chars
GRAFANA_PASSWORD=your_grafana_password
```

### 步驟 2：啟動所有服務

```bash
docker-compose -f docker-compose.unified.yml up -d
```

### 步驟 3：驗證部署

```bash
# 檢查所有服務狀態
docker-compose -f docker-compose.unified.yml ps

# 查看服務日誌
docker-compose -f docker-compose.unified.yml logs -f
```

### 步驟 4：訪問服務

- 前端 UI: http://localhost:3000
- Go 後端 API: http://localhost:3001
- Go 後端健康檢查: http://localhost:3001/health
- AI/量子服務: http://localhost:8000
- AI/量子 API 文件: http://localhost:8000/docs
- HexStrike AI: http://localhost:8888
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3002 (admin/admin)

## 📦 服務詳情

### Go 後端（backend）

**用途**：防禦面 API，管理掃描任務、安全事件、監控指標

**健康檢查**：
```bash
curl http://localhost:3001/health
```

**API 文件**：http://localhost:3001/swagger/index.html

### Python AI/量子（ai-quantum）

**用途**：AI 威脅偵測、行為分析、量子計算服務

**健康檢查**：
```bash
curl http://localhost:8000/health
```

**API 文件**：http://localhost:8000/docs

### Python HexStrike AI（hexstrike-ai）

**用途**：攻擊面滲透測試、安全工具集成

**健康檢查**：
```bash
curl http://localhost:8888/health
```

### Next.js 前端（frontend）

**用途**：統一 Web 儀表板

**環境變數**：
- `NEXT_PUBLIC_API_URL`：Go 後端 API URL
- `NEXT_PUBLIC_HEXSTRIKE_URL`：HexStrike AI URL
- `NEXT_PUBLIC_AI_QUANTUM_URL`：AI/量子服務 URL

## 🔧 常用指令

### 啟動服務

```bash
# 啟動所有服務
docker-compose -f docker-compose.unified.yml up -d

# 啟動特定服務
docker-compose -f docker-compose.unified.yml up -d backend

# 前台模式啟動（查看日誌）
docker-compose -f docker-compose.unified.yml up
```

### 停止服務

```bash
# 停止所有服務
docker-compose -f docker-compose.unified.yml down

# 停止並刪除資料卷（⚠️ 會刪除所有資料）
docker-compose -f docker-compose.unified.yml down -v
```

### 查看日誌

```bash
# 所有服務日誌
docker-compose -f docker-compose.unified.yml logs -f

# 特定服務日誌
docker-compose -f docker-compose.unified.yml logs -f backend

# 最近 100 行日誌
docker-compose -f docker-compose.unified.yml logs --tail=100 backend
```

### 重新建置映像

```bash
# 重新建置所有映像
docker-compose -f docker-compose.unified.yml build

# 重新建置特定服務
docker-compose -f docker-compose.unified.yml build backend

# 不使用快取建置
docker-compose -f docker-compose.unified.yml build --no-cache
```

### 進入容器

```bash
# 進入 backend 容器
docker-compose -f docker-compose.unified.yml exec backend sh

# 進入 postgres 容器
docker-compose -f docker-compose.unified.yml exec postgres psql -U sectools
```

## 📊 監控

### Prometheus

訪問 http://localhost:9090

查詢範例：
```promql
# 後端請求速率
rate(http_requests_total[5m])

# 資料庫連接數
pg_stat_database_numbackends

# CPU 使用率
container_cpu_usage_seconds_total
```

### Grafana

訪問 http://localhost:3002

預設帳號：`admin/admin`（首次登入會要求修改密碼）

預載儀表板：
- 統一安全平台總覽
- Go 後端監控
- AI/量子服務監控
- HexStrike AI 監控
- PostgreSQL 監控

## 🔐 安全性

### 密鑰管理

使用 Vault 管理所有敏感憑證：

```bash
# 取得 Vault token
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='root'

# 寫入密鑰
vault kv put secret/database password=mydbpassword

# 讀取密鑰
vault kv get secret/database
```

### 資料庫備份

```bash
# 備份資料庫
docker-compose -f docker-compose.unified.yml exec postgres \
  pg_dump -U sectools sectools > backup_$(date +%Y%m%d).sql

# 還原資料庫
cat backup_20250110.sql | \
  docker-compose -f docker-compose.unified.yml exec -T postgres \
  psql -U sectools sectools
```

## 🐛 故障排除

### 服務無法啟動

1. 檢查端口是否被佔用：
```bash
netstat -tuln | grep -E ':(3000|3001|3002|5432|6379|8000|8200|8888|9090)'
```

2. 檢查 Docker 資源限制

3. 查看服務日誌：
```bash
docker-compose -f docker-compose.unified.yml logs backend
```

### 資料庫連接失敗

1. 確認 PostgreSQL 容器正在運行
2. 檢查密碼是否正確
3. 等待資料庫完全啟動（健康檢查通過）

### 前端無法連接後端

1. 檢查 `.env` 中的 API URL 配置
2. 確認後端服務健康：`curl http://localhost:3001/health`
3. 檢查 CORS 設定

## 📝 開發建議

### 開發模式

對於開發環境，建議使用本地執行而非 Docker：

```bash
# Go 後端
cd src/backend
make dev

# Python AI/量子
cd src/ai-quantum
python -m uvicorn api.main:app --reload

# Next.js 前端
cd src/frontend
npm run dev
```

### 熱重載

修改 `docker-compose.unified.yml`，掛載源碼目錄並啟用熱重載：

```yaml
backend:
  volumes:
    - ../../src/backend:/app
  command: air  # Go hot reload
```

## 🔄 更新部署

```bash
# 拉取最新代碼
git pull

# 重新建置並啟動
docker-compose -f docker-compose.unified.yml up -d --build

# 查看變更
docker-compose -f docker-compose.unified.yml ps
```

## 📞 支援

如有問題，請：
1. 查看服務日誌
2. 檢查 [故障排除](../../docs/architecture/zh-TW/troubleshooting.md)
3. 提交 Issue

## 📄 授權

MIT License



