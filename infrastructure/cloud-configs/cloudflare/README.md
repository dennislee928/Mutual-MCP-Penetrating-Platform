# Cloudflare Containers 部署指南

> 將統一安全平台部署到 Cloudflare Containers（Beta）

**文檔參考**：[Cloudflare Containers Documentation](https://developers.cloudflare.com/containers/)

---

## 📋 概述

Cloudflare Containers 是新的容器服務，特點：

- ✅ **無伺服器容器**：自動擴展，按需啟動
- ✅ **全球邊緣**：部署到 Region:Earth
- ✅ **Durable Objects**：狀態管理與路由
- ✅ **任何語言**：支援 Go、Python 等
- ✅ **從 Dockerfile 建置**：相容現有配置

---

## 🚀 快速部署

### 前置需求

- Cloudflare Workers Paid Plan（$5/月起）
- Wrangler CLI 3.0+
- Docker
- 已驗證的 Cloudflare 帳號

### 步驟 1：安裝 Wrangler

```bash
npm install -g wrangler

# 登入 Cloudflare
wrangler login
```

### 步驟 2：安裝依賴

```bash
cd infrastructure/cloud-configs/cloudflare
npm install
```

### 步驟 3：建置並推送容器映像

```bash
# 建置所有容器映像
npm run push-all

# 或分別建置
npm run push-backend      # Go 後端
npm run push-ai           # AI/量子
npm run push-hexstrike    # HexStrike AI
```

### 步驟 4：設定 Secrets

```bash
# 設定敏感環境變數
wrangler secret put DB_PASSWORD
wrangler secret put JWT_SECRET
wrangler secret put HEXSTRIKE_API_KEYS
wrangler secret put IBM_QUANTUM_TOKEN
```

### 步驟 5：建立 KV Namespace（快取）

```bash
# 建立 KV namespace
wrangler kv namespace create CACHE

# 更新 wrangler.toml 中的 namespace ID
```

### 步驟 6：建立 R2 Bucket（掃描結果儲存）

```bash
# 建立 R2 bucket
wrangler r2 bucket create scan-results

# 更新 wrangler.toml
```

### 步驟 7：部署

```bash
# 部署到 Cloudflare
npm run deploy

# 或使用 wrangler
wrangler deploy
```

---

## 🏗️ 架構說明

### 架構圖

```
                    Cloudflare Edge Network
                              │
                    ┌─────────▼─────────┐
                    │   Worker Router   │
                    │  (worker.js)      │
                    └─────────┬─────────┘
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │ GoBackend   │   │ AIQuantum   │   │HexStrikeAI  │
    │ Container   │   │ Container   │   │ Container   │
    │ (Port 3001) │   │ (Port 8000) │   │ (Port 8888) │
    └─────────────┘   └─────────────┘   └─────────────┘
         │                   │                   │
         └───────────────────┴───────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  External Services│
                    │  (PostgreSQL等)   │
                    └───────────────────┘
```

### 路由規則

| 路徑 | 目標容器 | 服務 |
|-----|---------|------|
| `/api/v1/*` | GoBackend | 防禦面 API |
| `/api/ai/*` | AIQuantum | AI 威脅偵測 |
| `/api/quantum/*` | AIQuantum | 量子計算 |
| `/api/tools/*` | HexStrikeAI | 安全工具 |
| `/api/intelligence/*` | HexStrikeAI | AI 決策引擎 |
| `/api/agents/*` | HexStrikeAI | AI Agents |
| `/health` | Worker | 健康檢查 |

---

## 🔧 配置說明

### 容器實例管理

每個容器類配置：

```javascript
export class GoBackend extends Container {
  defaultPort = 3001;         // 容器監聽端口
  sleepAfter = "15m";         // 無請求後休眠時間
}
```

### 實例選擇策略

**選項 1：固定實例**（適合無狀態服務）
```javascript
const instance = getContainer(env.GO_BACKEND, 'backend-main');
```

**選項 2：基於 Session**（適合有狀態服務）
```javascript
const sessionId = request.headers.get('Session-ID');
const instance = getContainer(env.HEXSTRIKE_AI, sessionId);
```

**選項 3：基於用戶**（多租戶）
```javascript
const userId = await getUserId(request);
const instance = getContainer(env.GO_BACKEND, userId);
```

### 資源限制

| 容器 | Memory | CPU | Max Instances |
|-----|--------|-----|---------------|
| Go Backend | 512MB | 1 core | 10 |
| AI/Quantum | 1GB | 2 cores | 5 |
| HexStrike AI | 2GB | 2 cores | 10 |

可在 `wrangler.toml` 中調整。

---

## 🗄️ 資料庫選項

### 選項 1：外部 PostgreSQL（推薦）

使用 Neon、Supabase 或其他 PostgreSQL SaaS：

```bash
# 在容器環境變數中設定
wrangler secret put DATABASE_URL
# postgresql://user:pass@host:5432/dbname
```

### 選項 2：Cloudflare D1（限制多）

Cloudflare 的 SQLite 資料庫（功能受限）：

```bash
# 建立 D1 資料庫
wrangler d1 create unified-security-db

# 執行 migrations
wrangler d1 execute unified-security-db --file=../../src/backend/database/migrations/001_init_schema.sql
```

**限制**：
- SQLite 語法（不完全相容 PostgreSQL）
- 單一區域（非分散式）
- 查詢限制

### 選項 3：混合方案

```
Cloudflare Containers (運算)
    ↓
Neon PostgreSQL (資料庫，serverless)
    ↓
Cloudflare R2 (物件儲存)
```

---

## 🚦 流量與擴展

### 自動擴展

Cloudflare Containers 自動擴展：

```
低流量 → 1-2 個實例
中流量 → 3-5 個實例
高流量 → 達到 max_instances
無流量 → 自動休眠（sleepAfter）
```

### 冷啟動

首次請求會有冷啟動延遲：
- Go Backend：~2-3 秒
- Python 服務：~5-8 秒

**優化建議**：
- 使用 health check 保持溫暖
- 實施預熱機制
- 優化容器映像大小

---

## 💰 成本估算

### Cloudflare Workers Paid Plan

**基礎費用**：$5/月

**包含**：
- 10M requests/月
- 無限 Workers
- Container 運行時間

**超額費用**：
- Requests：$0.50 per million
- CPU time：$0.02 per million CPU-ms
- Durable Objects：$0.15 per million reads

### 範例估算

**場景**：中小型部署

```
預估流量：
- API 請求：100K/月
- 掃描任務：1K/月
- 儀表板訪問：10K/月

預估成本：
- Workers Plan：$5/月（基礎）
- 容器運行時間：$2-5/月
- Durable Objects：$1-2/月
- R2 儲存：$0.5/月

總計：~$8.5-12.5/月
```

**vs VPS**：
- 4GB VPS：$20-40/月
- ✅ Cloudflare 更便宜（低流量時）

---

## 🔐 安全配置

### 1. 環境變數安全

```bash
# ✅ 使用 Secrets（不用 vars）
wrangler secret put DB_PASSWORD
wrangler secret put JWT_SECRET
wrangler secret put HEXSTRIKE_API_KEYS

# ❌ 不要在 wrangler.toml 中明文設定
```

### 2. API 授權

```javascript
// Worker 中驗證 API Key
const apiKey = request.headers.get('X-API-Key');
if (!isValidApiKey(apiKey)) {
  return new Response('Unauthorized', { status: 401 });
}
```

### 3. Rate Limiting

```javascript
// 使用 Cloudflare Rate Limiting 或 Durable Objects
// 已在 SecurityMiddleware 中實作
```

---

## 📊 監控與日誌

### Cloudflare Dashboard

訪問：https://dash.cloudflare.com/

**可查看**：
- 請求統計
- 錯誤率
- CPU 使用
- Memory 使用
- Container 實例數量

### Wrangler Tail

即時查看日誌：

```bash
wrangler tail
```

### 整合 Grafana

將 Cloudflare 日誌推送到 Grafana：

```javascript
// 在 Worker 中添加
await env.METRICS.put('request_count', count);
```

---

## 🐛 故障排除

### 容器無法啟動

**問題**：容器映像建置失敗

**解決**：
```bash
# 本地測試建置
cd ../../src/backend
docker build -t test-backend .

# 檢查日誌
wrangler tail --format=pretty
```

### 資料庫連接失敗

**問題**：容器無法連接外部 PostgreSQL

**解決**：
1. 確認 DATABASE_URL secret 已設定
2. 檢查防火牆規則（允許 Cloudflare IP）
3. 使用 connection pooling（如 PgBouncer）

### 冷啟動太慢

**問題**：首次請求延遲高

**解決**：
- 優化 Dockerfile（multi-stage build）
- 減少映像大小
- 使用 health check endpoint 保持溫暖
- 實施預熱 Worker

---

## 🔄 更新部署

### 更新容器映像

```bash
# 1. 重新建置並推送映像
npm run push-backend

# 2. 部署新版本
wrangler deploy

# 3. 驗證部署
curl https://your-worker.your-subdomain.workers.dev/health
```

### 金絲雀部署

```javascript
// 在 Worker 中實施金絲雀部署
const useCanary = Math.random() < 0.1; // 10% 流量到 canary

if (useCanary) {
  return getContainer(env.GO_BACKEND_CANARY, instanceId);
} else {
  return getContainer(env.GO_BACKEND, instanceId);
}
```

---

## 📝 最佳實踐

### 1. 容器設計

✅ **好的做法**：
- 無狀態設計（儘可能）
- 快速啟動（<5 秒）
- 小映像大小（<500MB）
- 優雅關閉處理

❌ **避免**：
- 大量本地儲存
- 長時間運行任務
- 過大的映像

### 2. 成本優化

- 使用 `sleepAfter` 自動休眠
- 實施請求批處理
- 使用 KV 快取頻繁讀取
- 監控 CPU/Memory 使用

### 3. 可靠性

- 實施 health checks
- 設定合理的 timeout
- 使用 Durable Objects 管理狀態
- 實施重試邏輯

---

## 🆚 Cloudflare vs 其他平台

| 特性 | Cloudflare | Railway | Fly.io | Render |
|-----|-----------|---------|--------|--------|
| 容器支援 | ✅ Beta | ✅ 穩定 | ✅ 穩定 | ✅ 穩定 |
| 全球邊緣 | ✅✅✅ | ❌ | ✅✅ | ❌ |
| 自動休眠 | ✅ | ⚠️ | ✅ | ⚠️ |
| PostgreSQL | ⚠️ 外部 | ✅ 內建 | ✅ 內建 | ✅ 內建 |
| 免費層 | ❌ | ✅ | ✅ | ✅ |
| 價格 | $5+ | $5+ | $0+ | $0+ |
| 成熟度 | ⚠️ Beta | ✅ | ✅ | ✅ |

**建議**：
- 🌟 **高流量/全球用戶**：Cloudflare
- 🌟 **快速開始**：Railway 或 Render
- 🌟 **高性能需求**：Fly.io

---

## ⚠️ Beta 階段注意事項

Cloudflare Containers 目前處於 **Beta** 階段：

**可能的問題**：
- ⚠️ API 可能變更
- ⚠️ 某些功能尚未穩定
- ⚠️ 文檔可能不完整
- ⚠️ 限制可能調整

**建議**：
- 先在非關鍵環境測試
- 準備備用部署方案
- 關注 Cloudflare 更新公告
- 加入 [Cloudflare Discord](https://discord.gg/cloudflaredev)

---

## 🔗 外部服務連接

### PostgreSQL（推薦 Neon）

```bash
# 1. 註冊 Neon (https://neon.tech)
# 2. 建立資料庫
# 3. 取得連接字串

# 4. 設定 secret
wrangler secret put DATABASE_URL
# 輸入：postgresql://user:pass@host.neon.tech:5432/dbname?sslmode=require
```

### Redis（推薦 Upstash）

```bash
# 1. 註冊 Upstash (https://upstash.com)
# 2. 建立 Redis 資料庫（選 Global）
# 3. 取得 REST API URL

# 4. 設定 secret
wrangler secret put REDIS_URL
```

---

## 📊 監控儀表板

### Cloudflare Analytics

訪問：https://dash.cloudflare.com/

**可查看**：
- ✅ 請求數量與速率
- ✅ 錯誤率（4xx, 5xx）
- ✅ CPU 時間使用
- ✅ Memory 使用
- ✅ 容器實例數量
- ✅ 冷啟動次數

### 整合 Prometheus

```javascript
// 在 Worker 中暴露 metrics endpoint
if (url.pathname === '/metrics') {
  const metrics = await getMetrics(env);
  return new Response(metrics, {
    headers: { 'Content-Type': 'text/plain' }
  });
}
```

---

## 🧪 測試部署

### 本地測試

```bash
# 使用 Wrangler Dev 模式
wrangler dev

# 訪問
curl http://localhost:8787/health
curl http://localhost:8787/api/v1/scans
```

### 預覽部署

```bash
# 部署到預覽環境
wrangler deploy --env preview

# 取得預覽 URL
wrangler deployments list
```

---

## 💡 優化建議

### 1. 映像優化

```dockerfile
# 使用 multi-stage build
FROM golang:1.24-alpine AS builder
# ... build

FROM alpine:3.19
# ... 只複製必要文件
```

**目標**：
- Go Backend：<50MB
- Python 服務：<200MB

### 2. 啟動優化

- 延遲初始化非關鍵組件
- 使用健康檢查端點
- 預載常用資料

### 3. 快取策略

```javascript
// 使用 KV 快取 API 回應
const cacheKey = `api:${url.pathname}`;
let response = await env.CACHE.get(cacheKey);

if (!response) {
  response = await container.fetch(request);
  await env.CACHE.put(cacheKey, response, { expirationTtl: 300 });
}
```

---

## 🚀 進階功能

### 1. 區域放置（即將推出）

```javascript
// 指定容器運行區域
const container = getContainer(env.GO_BACKEND, instanceId, {
  region: 'asia-pacific'  // 亞太區域
});
```

### 2. GPU 支援（規劃中）

未來可能支援 GPU 容器（用於 AI 模型）

### 3. Cron Container

定期任務：

```javascript
export default {
  async scheduled(event, env, ctx) {
    const container = getContainer(env.HEXSTRIKE_AI, 'cron');
    await container.fetch(new Request('http://localhost:8888/api/cron/scan'));
  }
};
```

---

## 📞 支援

- 📖 官方文檔：https://developers.cloudflare.com/containers/
- 💬 Discord：https://discord.gg/cloudflaredev
- 🐛 問題回報：https://github.com/cloudflare/workers-sdk/issues
- 📧 企業支援：https://www.cloudflare.com/plans/enterprise/

---

## 🎉 部署檢查清單

部署前確認：

- [ ] 已升級到 Workers Paid Plan
- [ ] Wrangler 已安裝並登入
- [ ] 容器映像已建置並推送
- [ ] Secrets 已設定（DB_PASSWORD, JWT_SECRET 等）
- [ ] KV Namespace 已建立
- [ ] R2 Bucket 已建立
- [ ] 外部資料庫已準備（Neon/Supabase）
- [ ] 已在本地測試（wrangler dev）
- [ ] 已更新 wrangler.toml 的 IDs
- [ ] 已設定自訂域名（可選）

---

**準備好了嗎？執行 `npm run deploy` 開始部署！** 🚀

**如遇問題**：參考 [Cloudflare Containers FAQ](https://developers.cloudflare.com/containers/faq/)




