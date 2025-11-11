# Cloudflare Containers 部署檢查清單

## 📋 部署前準備

### 1. Cloudflare 帳號設置

- [ ] 已註冊 Cloudflare 帳號
- [ ] 已升級到 Workers Paid Plan（$5/月）
- [ ] 已驗證電子郵件
- [ ] 已添加付款方式

### 2. 本地環境準備

- [ ] 已安裝 Node.js 18+
- [ ] 已安裝 Docker
- [ ] 已安裝 Git
- [ ] 已安裝 Wrangler CLI（`npm install -g wrangler`）
- [ ] 已登入 Wrangler（`wrangler login`）

### 3. 專案準備

- [ ] 已完成專案重構
- [ ] 已完成安全修復
- [ ] 所有 Dockerfile 都可成功建置
- [ ] 本地測試通過

---

## 🏗️ 建置與推送

### 4. 容器映像建置

#### Go Backend

```bash
cd src/backend
docker build -t unified-backend:latest .
# ✅ 建置成功：映像大小 ~50MB
```

- [ ] Go Backend 建置成功
- [ ] 映像大小合理（<100MB）
- [ ] 本地可運行測試

#### AI/Quantum

```bash
cd src/ai-quantum  
docker build -t unified-ai-quantum:latest .
# ✅ 建置成功：映像大小 ~200MB
```

- [ ] AI/Quantum 建置成功
- [ ] 映像大小合理（<500MB）
- [ ] 本地可運行測試

#### HexStrike AI

```bash
cd src/hexstrike-ai
docker build -t unified-hexstrike:latest .
# ✅ 建置成功：映像大小 ~300MB
```

- [ ] HexStrike AI 建置成功
- [ ] 映像大小合理（<500MB）
- [ ] 本地可運行測試

### 5. 推送到 Cloudflare

```bash
cd infrastructure/cloud-configs/cloudflare

# 推送所有映像
npm run push-all

# 或分別推送
npm run push-backend
npm run push-ai
npm run push-hexstrike
```

- [ ] Go Backend 映像已推送
- [ ] AI/Quantum 映像已推送
- [ ] HexStrike AI 映像已推送

---

## 🔐 安全配置

### 6. 設定 Secrets

```bash
# 必須設定的 Secrets
wrangler secret put DB_PASSWORD
wrangler secret put JWT_SECRET
wrangler secret put HEXSTRIKE_API_KEYS

# 可選的 Secrets
wrangler secret put IBM_QUANTUM_TOKEN
wrangler secret put REDIS_PASSWORD
```

- [ ] DB_PASSWORD 已設定（建議 32+ 字元）
- [ ] JWT_SECRET 已設定（必須 32+ 字元）
- [ ] HEXSTRIKE_API_KEYS 已設定（逗號分隔）
- [ ] IBM_QUANTUM_TOKEN 已設定（如使用）

### 7. KV Namespace（快取）

```bash
# 建立 KV namespace
wrangler kv namespace create CACHE

# 複製輸出的 ID，更新 wrangler.toml
# id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

- [ ] KV Namespace 已建立
- [ ] ID 已更新到 wrangler.toml

### 8. R2 Bucket（掃描結果）

```bash
# 建立 R2 bucket
wrangler r2 bucket create scan-results

# 確認建立成功
wrangler r2 bucket list
```

- [ ] R2 Bucket 已建立
- [ ] 名稱已更新到 wrangler.toml

---

## 🗄️ 外部服務設置

### 9. PostgreSQL（推薦 Neon）

**選項 A：Neon（推薦）**

1. 註冊：https://neon.tech
2. 建立專案
3. 建立資料庫
4. 取得連接字串

```bash
wrangler secret put DATABASE_URL
# 輸入：postgresql://user:pass@host.neon.tech:5432/dbname?sslmode=require
```

- [ ] Neon 帳號已建立
- [ ] 資料庫已建立
- [ ] DATABASE_URL 已設定
- [ ] 連接測試成功

**選項 B：Supabase**

1. 註冊：https://supabase.com
2. 建立專案
3. 取得資料庫連接字串（在 Settings > Database）

- [ ] Supabase 專案已建立
- [ ] DATABASE_URL 已設定

**選項 C：Cloudflare D1**

```bash
# 建立 D1 資料庫
wrangler d1 create unified-security-db

# 執行 migrations
wrangler d1 execute unified-security-db --file=../../src/backend/database/migrations/001_init_schema.sql
```

- [ ] D1 資料庫已建立
- [ ] Migrations 已執行
- [ ] ⚠️ 注意：D1 是 SQLite，語法可能需調整

### 10. Redis（推薦 Upstash）

1. 註冊：https://upstash.com
2. 建立 Redis 資料庫（選 Global）
3. 取得 REST API URL

```bash
wrangler secret put REDIS_URL
```

- [ ] Upstash 帳號已建立
- [ ] Redis 資料庫已建立（Global 模式）
- [ ] REDIS_URL 已設定

---

## 🚀 部署執行

### 11. 配置文件檢查

- [ ] `wrangler.toml` 已正確配置
- [ ] `worker.js` 路由邏輯正確
- [ ] `package.json` 依賴完整
- [ ] 所有 secret 名稱一致

### 12. 部署

```bash
cd infrastructure/cloud-configs/cloudflare

# 方式 1：使用腳本（推薦）
./deploy.sh          # Linux/Mac
.\deploy.ps1         # Windows PowerShell

# 方式 2：手動部署
wrangler deploy
```

- [ ] 部署命令執行成功
- [ ] 取得 Worker URL
- [ ] 無錯誤訊息

---

## ✅ 部署後驗證

### 13. 健康檢查

```bash
# 設定 Worker URL
export WORKER_URL="https://your-worker.your-subdomain.workers.dev"

# 測試 Worker 健康檢查
curl $WORKER_URL/health

# 應該返回
{
  "status": "ok",
  "service": "unified-security-platform",
  "platform": "cloudflare-containers",
  "timestamp": "2025-11-10T..."
}
```

- [ ] Worker 健康檢查成功
- [ ] 返回正確的 JSON

### 14. 測試各服務

#### Go Backend

```bash
# 取得掃描列表
curl $WORKER_URL/api/v1/scans

# 建立測試掃描
curl -X POST $WORKER_URL/api/v1/scans \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com", "scan_type": "nuclei"}'
```

- [ ] Go Backend API 可訪問
- [ ] API 回應正確

#### AI/Quantum

```bash
# AI 模型狀態
curl $WORKER_URL/api/ai/models/status

# 量子服務狀態  
curl $WORKER_URL/api/quantum/status

# 生成量子隨機數
curl $WORKER_URL/api/quantum/random/256
```

- [ ] AI/Quantum API 可訪問
- [ ] API 回應正確

#### HexStrike AI

```bash
# 需要 API Key
export API_KEY="your-api-key"

# 測試工具端點
curl -H "X-API-Key: $API_KEY" \
  $WORKER_URL/api/tools/nmap \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"target": "8.8.8.8", "scan_type": "quick"}'
```

- [ ] HexStrike AI 可訪問
- [ ] API 授權正常工作
- [ ] 工具可執行

### 15. 性能測試

```bash
# 測試回應時間
time curl $WORKER_URL/health

# 測試並發
ab -n 100 -c 10 $WORKER_URL/health

# 或使用 wrk
wrk -t4 -c100 -d30s $WORKER_URL/health
```

- [ ] 首次請求延遲 <10秒（冷啟動）
- [ ] 後續請求延遲 <1秒
- [ ] 並發處理正常

---

## 📊 監控設置

### 16. Cloudflare Dashboard

訪問：https://dash.cloudflare.com/

- [ ] 可查看 Worker 統計
- [ ] 可查看 Container 實例數
- [ ] 可查看錯誤日誌

### 17. 告警設置（可選）

在 Cloudflare Dashboard 設定：
- [ ] 錯誤率告警（>5%）
- [ ] CPU 使用告警（>80%）
- [ ] 成本告警（超過預算）

---

## 🔄 自訂域名（可選）

### 18. 綁定自訂域名

```bash
# 添加自訂域名
wrangler publish --route "api.yourdomain.com/*"

# 或在 wrangler.toml 中設定
# routes = [
#   { pattern = "api.yourdomain.com/*", zone_name = "yourdomain.com" }
# ]
```

- [ ] 域名 DNS 已設定到 Cloudflare
- [ ] Worker 路由已配置
- [ ] SSL 證書自動生成
- [ ] 自訂域名可訪問

---

## 🎉 完成！

### 所有項目已完成

如果上述所有項目都勾選✅，恭喜！您已成功部署到 Cloudflare Containers。

### 下一步

- 📊 監控 Cloudflare Dashboard
- 📝 查看日誌：`wrangler tail`
- 🧪 執行壓力測試
- 📖 閱讀 [Cloudflare Containers 文檔](https://developers.cloudflare.com/containers/)
- 💬 加入 [Cloudflare Discord](https://discord.gg/cloudflaredev)

---

## 🐛 常見問題

### Q: 容器啟動慢

A: 優化 Dockerfile，減少映像大小

### Q: 資料庫連接失敗

A: 檢查 DATABASE_URL 是否正確，防火牆是否允許

### Q: 成本高於預期

A: 檢查 `sleepAfter` 設定，減少閒置實例

### Q: 部署失敗

A: 執行 `wrangler tail` 查看即時日誌

---

**祝部署順利！** 🚀




