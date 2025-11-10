# ☁️ Cloudflare Containers 部署就緒

> 統一安全平台 - Cloudflare Containers 部署完整指南

**狀態**：✅ **配置完成，可立即部署**  
**平台**：Cloudflare Containers (Beta)  
**文檔**：https://developers.cloudflare.com/containers/

---

## 🎉 好消息

### ✅ npm EBUSY 錯誤已解決！

使用 **pnpm** 成功安裝所有依賴：

```bash
✅ @cloudflare/containers@0.0.30 已安裝
✅ wrangler@3.114.15 已安裝
✅ 59 個依賴包成功安裝
```

### ✅ 部署配置已完成！

所有必要的配置文件已建立：

```
infrastructure/cloud-configs/cloudflare/
├── wrangler.toml                    # ✅ Cloudflare 配置
├── src/worker.js                    # ✅ Worker 路由邏輯
├── package.json                     # ✅ 依賴定義（已修復版本）
├── deploy.sh                        # ✅ 部署腳本（Bash）
├── deploy.ps1                       # ✅ 部署腳本（PowerShell）
├── README.md                        # ✅ 詳細文檔
├── FIX_NPM_EBUSY.md                # ✅ 錯誤修復指南
├── DEPLOYMENT_CHECKLIST.md         # ✅ 部署檢查清單
├── QUICK_DEPLOY.md                 # ✅ 5 分鐘快速部署
└── node_modules/                    # ✅ 依賴已安裝
```

---

## 🚀 立即部署

### 最快方式（5 分鐘）

```bash
# 1. 進入 Cloudflare 配置目錄
cd infrastructure/cloud-configs/cloudflare

# 2. 登入 Cloudflare（如未登入）
wrangler login

# 3. 執行部署腳本
.\deploy.ps1  # Windows PowerShell
# 或
./deploy.sh   # Linux/Mac Bash

# 4. 選擇要部署的服務
# 輸入 4 部署全部（Go Backend + AI/Quantum + HexStrike AI）

# 5. 按提示設定 Secrets
```

### 手動部署步驟

#### Step 1: 建置並推送容器映像

```bash
# 推送 Go Backend
cd ../../../src/backend
docker build -t unified-backend:latest .
cd ../../infrastructure/cloud-configs/cloudflare
wrangler containers push backend ../../../src/backend/Dockerfile

# 推送 AI/Quantum
cd ../../../src/ai-quantum
docker build -t unified-ai-quantum:latest .
cd ../../infrastructure/cloud-configs/cloudflare
wrangler containers push ai-quantum ../../../src/ai-quantum/Dockerfile

# 推送 HexStrike AI
cd ../../../src/hexstrike-ai
docker build -t unified-hexstrike:latest .
cd ../../infrastructure/cloud-configs/cloudflare
wrangler containers push hexstrike ../../../src/hexstrike-ai/Dockerfile
```

#### Step 2: 設定 Secrets

```bash
# 必須設定
wrangler secret put DB_PASSWORD
# 輸入：強密碼（32+ 字元）

wrangler secret put JWT_SECRET
# 輸入：強密鑰（32+ 字元）

wrangler secret put HEXSTRIKE_API_KEYS
# 輸入：API Keys（逗號分隔）

# 可選設定
wrangler secret put IBM_QUANTUM_TOKEN
wrangler secret put REDIS_PASSWORD
```

#### Step 3: 建立資源

**KV Namespace（快取）**：
```bash
wrangler kv namespace create CACHE
# 複製輸出的 ID 到 wrangler.toml
```

**R2 Bucket（掃描結果）**：
```bash
wrangler r2 bucket create scan-results
```

#### Step 4: 部署

```bash
wrangler deploy
```

---

## 🌐 部署後訪問

### Worker URL

部署成功後會顯示 Worker URL：
```
https://unified-security-platform.your-subdomain.workers.dev
```

### 測試端點

```bash
# 設定 Worker URL
export WORKER_URL="https://your-worker.your-subdomain.workers.dev"

# 健康檢查
curl $WORKER_URL/health

# Go Backend API
curl $WORKER_URL/api/v1/scans

# AI/Quantum API
curl $WORKER_URL/api/ai/models/status
curl $WORKER_URL/api/quantum/status

# HexStrike AI（需要 API Key）
curl -H "X-API-Key: your-key" \
  $WORKER_URL/api/tools/nmap \
  -X POST \
  -d '{"target": "8.8.8.8", "scan_type": "quick"}'
```

---

## 📊 服務架構

### 在 Cloudflare 上的架構

```
                 Cloudflare Global Network
                   (330+ Edge Locations)
                           │
                ┌──────────▼──────────┐
                │  Worker Router      │
                │  (JavaScript)       │
                └──────────┬──────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼───────┐  ┌───────▼───────┐  ┌──────▼────────┐
│ Go Backend    │  │ AI/Quantum    │  │ HexStrike AI  │
│ Container     │  │ Container     │  │ Container     │
│ (Port 3001)   │  │ (Port 8000)   │  │ (Port 8888)   │
│ Max: 10 inst. │  │ Max: 5 inst.  │  │ Max: 10 inst. │
│ Mem: 512MB    │  │ Mem: 1GB      │  │ Mem: 2GB      │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
        └──────────────────┴──────────────────┘
                           │
                 ┌─────────▼──────────┐
                 │  External Services │
                 │  - Neon PostgreSQL │
                 │  - Upstash Redis   │
                 │  - Cloudflare KV   │
                 │  - Cloudflare R2   │
                 └────────────────────┘
```

### 路由邏輯

| 請求路徑 | 目標容器 | 實例策略 |
|---------|---------|---------|
| `/api/v1/*` | Go Backend | 固定實例 |
| `/api/ai/*` | AI/Quantum | 固定實例 |
| `/api/quantum/*` | AI/Quantum | 固定實例 |
| `/api/tools/*` | HexStrike AI | 基於 Session |
| `/api/intelligence/*` | HexStrike AI | 基於 Session |
| `/api/agents/*` | HexStrike AI | 基於 Session |
| `/health` | Worker 直接處理 | N/A |

---

## 💰 成本估算

### Cloudflare Containers 計費

**基礎**：Workers Paid Plan = **$5/月**

**容器運行時間**：
```
計算公式：
- CPU-ms：每百萬 CPU-ms = $0.02
- Requests：每百萬請求 = $0.50
- Durable Objects：讀取/寫入

範例（中小型使用）：
- 10K 請求/月
- 平均 100ms CPU 時間/請求
- = 1M CPU-ms
- = $0.02

總計：$5 + $0.02 + 其他 ≈ $6-10/月
```

**vs 傳統 VPS**：
- 4GB VPS Linode/DigitalOcean：$24-40/月
- ✅ **Cloudflare 便宜 70-80%**（低中流量）

**vs 其他 Serverless**：
- AWS Lambda：類似或稍貴
- Google Cloud Run：類似
- Azure Container Apps：類似或稍貴
- ✅ **Cloudflare 全球分佈更佳**

---

## 🔧 外部服務推薦

### PostgreSQL

#### 選項 1：Neon（最推薦）⭐⭐⭐⭐⭐

**網站**：https://neon.tech

**優點**：
- ✅ Serverless PostgreSQL
- ✅ 自動擴展
- ✅ 分支功能（開發/測試）
- ✅ 免費層：500MB 儲存，100 小時運算/月
- ✅ 與 Cloudflare 整合良好

**設定**：
```bash
# 1. 建立 Neon 專案
# 2. 取得連接字串
# 3. 設定 Secret
wrangler secret put DATABASE_URL
# postgresql://user:pass@host.neon.tech:5432/dbname?sslmode=require
```

**成本**：$0（免費層）或 $19/月起

#### 選項 2：Supabase⭐⭐⭐⭐

**網站**：https://supabase.com

**優點**：
- ✅ PostgreSQL + 額外功能（Auth, Storage）
- ✅ 免費層：500MB 資料庫
- ✅ 自動 API 生成

**成本**：$0（免費層）或 $25/月起

### Redis

#### Upstash Redis（最推薦）⭐⭐⭐⭐⭐

**網站**：https://upstash.com

**優點**：
- ✅ Serverless Redis
- ✅ Global 複製
- ✅ REST API（完美適配 Workers）
- ✅ 免費層：10K 命令/天

**設定**：
```bash
# 1. 建立 Upstash Redis（選 Global）
# 2. 取得 REST URL
# 3. 在 Go/Python 代碼中使用 REST API
```

**成本**：$0（免費層）或 $0.2 per 100K 命令

---

## 📋 完整部署檢查清單

### 前置準備 ✅

- [x] Cloudflare 帳號已建立
- [x] Workers Paid Plan 已啟用
- [x] Wrangler CLI 已安裝
- [x] Docker 已安裝
- [x] 專案重構已完成
- [x] 安全修復已完成
- [x] npm 依賴已安裝（pnpm）

### 容器映像 ⏳

- [ ] Go Backend 映像已建置
- [ ] AI/Quantum 映像已建置
- [ ] HexStrike AI 映像已建置
- [ ] 所有映像已推送到 Cloudflare

### 配置 ⏳

- [ ] wrangler.toml 已正確配置
- [ ] worker.js 路由邏輯已設定
- [ ] Secrets 已設定（DB_PASSWORD, JWT_SECRET 等）
- [ ] KV Namespace 已建立
- [ ] R2 Bucket 已建立

### 外部服務 ⏳

- [ ] PostgreSQL 已設置（Neon/Supabase）
- [ ] DATABASE_URL 已設定
- [ ] Redis 已設置（Upstash，可選）
- [ ] 資料庫 migrations 已執行

### 部署 ⏳

- [ ] `wrangler deploy` 執行成功
- [ ] Worker URL 已取得
- [ ] 健康檢查通過

### 驗證 ⏳

- [ ] 所有 API 端點可訪問
- [ ] 授權機制正常工作
- [ ] 容器可正常啟動
- [ ] 效能符合預期（冷啟動 <10秒）

---

## 🎯 現在可以做什麼

### 選項 1：立即部署（推薦）

```bash
cd infrastructure/cloud-configs/cloudflare
.\deploy.ps1  # Windows
```

執行互動式部署，按提示完成。

### 選項 2：閱讀完整文檔

依次閱讀：
1. [FIX_NPM_EBUSY.md](infrastructure/cloud-configs/cloudflare/FIX_NPM_EBUSY.md) - npm 錯誤修復
2. [QUICK_DEPLOY.md](infrastructure/cloud-configs/cloudflare/QUICK_DEPLOY.md) - 5 分鐘快速部署
3. [DEPLOYMENT_CHECKLIST.md](infrastructure/cloud-configs/cloudflare/DEPLOYMENT_CHECKLIST.md) - 完整檢查清單
4. [README.md](infrastructure/cloud-configs/cloudflare/README.md) - 詳細指南

### 選項 3：先設置外部服務

**建議順序**：

**1. 設置 PostgreSQL（Neon）**：
   - 訪問 https://neon.tech
   - 建立免費專案
   - 建立資料庫 `unified_security`
   - 取得連接字串
   - 執行 migrations：
     ```bash
     psql "postgresql://..." < src/backend/database/migrations/001_init_schema.sql
     ```

**2. 設置 Redis（Upstash，可選）**：
   - 訪問 https://upstash.com
   - 建立 Redis 資料庫（Global）
   - 取得 REST URL

**3. 設定 Cloudflare Secrets**：
   ```bash
   wrangler secret put DATABASE_URL
   wrangler secret put REDIS_URL
   wrangler secret put JWT_SECRET
   wrangler secret put HEXSTRIKE_API_KEYS
   ```

**4. 執行部署**

---

## 📖 詳細指令參考

### 建置映像

```bash
# Go Backend
cd src/backend
docker build -t unified-backend:latest .

# AI/Quantum
cd src/ai-quantum
docker build -t unified-ai-quantum:latest .

# HexStrike AI
cd src/hexstrike-ai
docker build -t unified-hexstrike:latest .
```

### 推送到 Cloudflare

```bash
cd infrastructure/cloud-configs/cloudflare

# 方式 1：使用 npm scripts
npm run push-backend
npm run push-ai
npm run push-hexstrike

# 方式 2：使用 wrangler 直接推送
wrangler containers push backend ../../../src/backend/Dockerfile
wrangler containers push ai-quantum ../../../src/ai-quantum/Dockerfile
wrangler containers push hexstrike ../../../src/hexstrike-ai/Dockerfile
```

### 部署

```bash
# 部署到生產
wrangler deploy

# 部署到預覽環境
wrangler deploy --env preview

# 查看部署狀態
wrangler deployments list
```

### 監控

```bash
# 即時日誌
wrangler tail

# 格式化日誌
wrangler tail --format=pretty

# 過濾錯誤
wrangler tail | grep ERROR
```

---

## 🔍 故障排除

### 問題 1：npm EBUSY

**解決**：已完全解決，使用 pnpm
```bash
pnpm install
```

**詳情**：[FIX_NPM_EBUSY.md](infrastructure/cloud-configs/cloudflare/FIX_NPM_EBUSY.md)

### 問題 2：容器建置失敗

**診斷**：
```bash
# 本地測試建置
docker build -t test .

# 查看日誌
docker build -t test . 2>&1 | tee build.log
```

**常見原因**：
- 映像太大（>500MB）
- 建置超時
- 依賴安裝失敗

### 問題 3：部署後無法訪問

**診斷**：
```bash
# 查看即時日誌
wrangler tail

# 測試本地
wrangler dev
```

**常見原因**：
- Secrets 未設定
- 容器端口不正確
- 路由配置錯誤

### 問題 4：冷啟動太慢

**優化**：
1. 減少映像大小
2. 優化啟動邏輯
3. 使用定期 ping 保持溫暖

---

## 🎓 最佳實踐

### 1. 映像優化

```dockerfile
# ✅ 使用 multi-stage build
FROM golang:1.24-alpine AS builder
RUN go build -o main .

FROM alpine:3.19
COPY --from=builder /app/main .
```

### 2. 健康檢查

```go
// 在所有服務中實作 /health
app.GET("/health", func(c *gin.Context) {
    c.JSON(200, gin.H{"status": "ok"})
})
```

### 3. 優雅關閉

```go
// 處理 SIGTERM
sigterm := make(chan os.Signal, 1)
signal.Notify(sigterm, syscall.SIGTERM)
<-sigterm
// 清理資源
```

### 4. 監控與日誌

```javascript
// 在 Worker 中記錄關鍵指標
console.log('Request to:', url.pathname);
console.log('Container instance:', instanceId);
console.log('Response time:', Date.now() - start);
```

---

## 🌟 Cloudflare Containers 優勢

### 為什麼選擇 Cloudflare

1. **全球分佈** 🌍
   - 330+ 個城市
   - 自動選擇最近的邊緣節點
   - 低延遲（<50ms）

2. **自動擴展** 📈
   - 0 → N 實例
   - 按需啟動
   - 無流量時休眠

3. **內建安全** 🔐
   - DDoS 防護
   - WAF（Web Application Firewall）
   - Rate Limiting
   - SSL/TLS 自動管理

4. **開發友善** 💻
   - 從 Dockerfile 直接建置
   - 本地開發（wrangler dev）
   - 即時日誌（wrangler tail）
   - Git 整合

5. **成本效益** 💰
   - 按用量付費
   - 無最低承諾
   - 免費 DDoS 防護
   - 免費 SSL 證書

---

## 📈 預期性能

### 冷啟動時間

| 服務 | 映像大小 | 冷啟動時間 |
|-----|---------|-----------|
| Go Backend | ~50MB | ~2-3 秒 |
| AI/Quantum | ~200MB | ~5-8 秒 |
| HexStrike AI | ~300MB | ~8-12 秒 |

### 溫啟動時間

- Go Backend：<100ms
- AI/Quantum：<200ms
- HexStrike AI：<300ms

### 擴展能力

- 最大實例數：10（可調整）
- 每實例處理：100-500 requests/秒
- 總吞吐量：1K-5K requests/秒

---

## 🔄 更新部署

### 更新代碼

```bash
# 1. 修改代碼
# 2. 重新建置映像
cd src/backend
docker build -t unified-backend:latest .

# 3. 重新推送
cd ../../infrastructure/cloud-configs/cloudflare
npm run push-backend

# 4. 重新部署
wrangler deploy
```

### 回滾

```bash
# 查看部署歷史
wrangler deployments list

# 回滾到前一版本
wrangler rollback <deployment-id>
```

---

## 🎉 成功！

您現在可以：

✅ **部署所有後端服務**到 Cloudflare Containers  
✅ **全球分佈**：330+ 個邊緣節點  
✅ **自動擴展**：根據流量自動調整  
✅ **安全加固**：已修復所有 P0/P1 漏洞  
✅ **成本優化**：按需付費，無閒置成本  

---

## 📞 支援

- 📖 **文檔**：[infrastructure/cloud-configs/cloudflare/README.md](infrastructure/cloud-configs/cloudflare/README.md)
- 💬 **Discord**：https://discord.gg/cloudflaredev
- 🐛 **Issues**：https://github.com/cloudflare/workers-sdk/issues
- 📧 **本專案**：提交 GitHub Issue

---

**準備好了嗎？執行部署腳本開始！** 🚀

```bash
cd infrastructure/cloud-configs/cloudflare
.\deploy.ps1  # Windows
```

**祝部署順利！** 🎊

