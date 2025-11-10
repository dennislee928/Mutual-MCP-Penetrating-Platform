# 統一安全平台 - 快速開始指南

> 5 分鐘快速部署完整的統一安全平台

## 📋 前置需求

- Docker 20.10+
- Docker Compose 2.0+
- Git
- 8GB+ RAM
- 20GB+ 可用磁碟空間

## 🚀 一鍵部署

### 步驟 1：克隆專案

```bash
git clone <your-repo-url>
cd MCP---AGENTIC-
```

### 步驟 2：配置環境變數

```bash
cd infrastructure/docker
cp .env.example .env
```

**重要**：編輯 `.env` 檔案，修改以下內容：

```env
# 必須修改的配置
DB_PASSWORD=your_secure_password_here
JWT_SECRET=your_jwt_secret_min_32_characters
GRAFANA_PASSWORD=your_grafana_password

# 可選配置
IBM_QUANTUM_TOKEN=your_ibm_quantum_token  # 如需使用 IBM Quantum
```

### 步驟 3：啟動所有服務

```bash
docker-compose -f docker-compose.unified.yml up -d
```

等待約 2-3 分鐘讓所有服務完全啟動。

### 步驟 4：驗證部署

```bash
# 檢查所有服務狀態
docker-compose -f docker-compose.unified.yml ps

# 應該看到所有服務都是 "Up" 狀態
```

### 步驟 5：訪問服務

開啟瀏覽器，訪問以下網址：

| 服務 | URL | 說明 |
|------|-----|------|
| 🌐 **前端 UI** | http://localhost:3000 | 統一儀表板 |
| 🔵 **Go 後端 API** | http://localhost:3001/health | 防禦面 API |
| 🟣 **AI/量子服務** | http://localhost:8000/docs | AI 威脅偵測 |
| 🔴 **HexStrike AI** | http://localhost:8888/health | 攻擊面測試 |
| 📊 **Prometheus** | http://localhost:9090 | 指標監控 |
| 📈 **Grafana** | http://localhost:3002 | 監控儀表板 |

Grafana 預設帳號：`admin` / 你在 .env 設定的密碼

## 🎯 快速測試

### 測試 Go 後端

```bash
# 健康檢查
curl http://localhost:3001/health

# 取得掃描列表
curl http://localhost:3001/api/v1/scans

# 建立測試掃描
curl -X POST http://localhost:3001/api/v1/scans \
  -H "Content-Type: application/json" \
  -d '{
    "target": "https://example.com",
    "scan_type": "nuclei"
  }'
```

### 測試 AI/量子服務

```bash
# 健康檢查
curl http://localhost:8000/health

# AI 模型狀態
curl http://localhost:8000/api/ai/models/status

# 量子服務狀態
curl http://localhost:8000/api/quantum/status

# 生成量子隨機數
curl http://localhost:8000/api/quantum/random/256
```

### 測試 HexStrike AI

```bash
# 健康檢查
curl http://localhost:8888/health
```

## 📊 監控平台

### Grafana 儀表板

1. 訪問 http://localhost:3002
2. 使用 `admin` 和你設定的密碼登入
3. 瀏覽預載儀表板

### Prometheus 查詢

訪問 http://localhost:9090，執行查詢：

```promql
# 後端 API 請求速率
rate(http_requests_total[5m])

# 服務健康狀態
up{job=~"backend|ai-quantum|hexstrike"}
```

## 🛑 停止服務

```bash
cd infrastructure/docker

# 停止所有服務
docker-compose -f docker-compose.unified.yml down

# 停止並刪除資料卷（⚠️ 會刪除所有資料）
docker-compose -f docker-compose.unified.yml down -v
```

## 🔧 故障排除

### 服務無法啟動

1. **檢查端口佔用**：
```bash
netstat -tuln | grep -E ':(3000|3001|3002|5432|6379|8000|8200|8888)'
```

2. **查看服務日誌**：
```bash
docker-compose -f docker-compose.unified.yml logs backend
```

3. **重啟服務**：
```bash
docker-compose -f docker-compose.unified.yml restart backend
```

### 資料庫連接失敗

等待 PostgreSQL 完全啟動（約 30 秒）：

```bash
docker-compose -f docker-compose.unified.yml logs postgres
# 應該看到 "database system is ready to accept connections"
```

### 記憶體不足

如果系統記憶體不足，可以只啟動核心服務：

```bash
docker-compose -f docker-compose.unified.yml up -d postgres redis backend frontend
```

## 📚 下一步

### 開發者

- 查看 [Go 後端開發指南](src/backend/README.md)
- 查看 [AI/量子模組開發指南](src/ai-quantum/README.md)
- 查看 [前端開發指南](src/frontend/README.md)

### 運維人員

- 查看 [部署指南](infrastructure/docker/README.md)
- 查看 [Kubernetes 部署](infrastructure/kubernetes/README.md)
- 查看 [監控配置](docs/architecture/zh-TW/deployment.md)

### 安全人員

- 查看 [安全最佳實踐](docs/architecture/zh-TW/security.md)
- 查看 [工具使用指南](src/hexstrike-ai/README.md)

## 🤝 需要幫助？

- 📖 完整文檔：`docs/`
- 🐛 問題回報：GitHub Issues
- 💬 討論區：GitHub Discussions

## 🎉 完成！

恭喜！你已成功部署統一安全平台。

現在可以：
- 🔍 執行安全掃描
- 🤖 使用 AI 威脅偵測
- 🔬 探索量子計算功能
- 📊 查看監控儀表板

祝使用愉快！🚀


