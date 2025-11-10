# Cloudflare Workers + Containers 部署指南

## 🎯 問題說明

### 為什麼容器沒有顯示在 Dashboard？

`wrangler containers push` 只是將映像推送到 Cloudflare Container Registry，但**不會自動創建可見的容器實例**。

要讓容器顯示並運行，需要：
1. ✅ 推送容器映像（已完成）
2. ❌ 創建 Worker 綁定容器（需要做）
3. ❌ 部署 Worker（需要做）

## 📊 當前狀態

### 已推送的映像
- ✅ `backend:latest` - Go Backend API
- ✅ `ai-quantum:latest` - AI/Quantum 威脅偵測
- ⏳ `hexstrike:latest` - HexStrike AI（修復後待部署）

### Dashboard 顯示
- `gentle-salad-9277` - 示範專案（完整的 Worker + Container）
- 其他容器映像存在於 registry，但沒有 Worker 綁定

## 🚀 部署步驟

### 步驟 1：完成容器映像推送

如果還沒有推送所有映像，執行：

```bash
cd /d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare
./deploy.sh
# 選擇選項 4（全部服務）或 3（HexStrike AI）
```

### 步驟 2：部署 Backend Worker

```bash
cd /d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare

# 部署 Backend Worker
wrangler deploy --config wrangler-backend.toml
```

### 步驟 3：部署 AI/Quantum Worker

```bash
# 部署 AI/Quantum Worker
wrangler deploy --config wrangler-ai.toml
```

### 步驟 4：部署 HexStrike Worker

```bash
# 部署 HexStrike Worker
wrangler deploy --config wrangler-hexstrike.toml
```

## 🧪 測試部署

部署完成後，測試各服務：

```bash
# Backend Service
curl https://unified-backend.your-subdomain.workers.dev/health

# AI/Quantum Service
curl https://unified-ai-quantum.your-subdomain.workers.dev/health

# HexStrike Service
curl https://unified-hexstrike.your-subdomain.workers.dev/health
```

預期響應：

```json
{
  "status": "ok",
  "service": "backend",
  "timestamp": "2025-11-10T08:30:00.000Z"
}
```

## 📋 查看部署狀態

### 在 Cloudflare Dashboard

1. 登入 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 選擇您的帳戶
3. 導航至 **Workers & Pages**
4. 您應該看到：
   - `unified-backend`
   - `unified-ai-quantum`
   - `unified-hexstrike`
   - `gentle-salad-9277`（示範）

### 使用 Wrangler CLI

```bash
# 列出所有 Workers
wrangler deployments list --name unified-backend
wrangler deployments list --name unified-ai-quantum
wrangler deployments list --name unified-hexstrike

# 查看容器映像
wrangler containers list
```

## 🔧 故障排除

### 錯誤：Container image not found

如果出現此錯誤，確認映像已推送：

```bash
# 重新推送映像
cd /d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare
./deploy.sh
```

### 錯誤：Worker deployment failed

檢查 wrangler.toml 配置：

```bash
# 驗證配置
wrangler deploy --config wrangler-backend.toml --dry-run
```

### 容器無法啟動

查看日誌：

```bash
# 實時日誌
wrangler tail unified-backend
wrangler tail unified-ai-quantum
wrangler tail unified-hexstrike
```

## 📖 配置說明

### Worker 配置檔案

- `wrangler-backend.toml` - Backend Service 配置
- `wrangler-ai.toml` - AI/Quantum Service 配置
- `wrangler-hexstrike.toml` - HexStrike Service 配置

### Worker 代碼

- `src/backend-worker.js` - Backend Worker（路由到容器）
- `src/ai-worker.js` - AI Worker（路由到容器）
- `src/hexstrike-worker.js` - HexStrike Worker（路由到容器）

### 容器綁定

每個 Worker 配置都包含容器綁定：

```toml
[[containers]]
name = "BACKEND_CONTAINER"
image = "backend:latest"
max_instances = 5
```

Worker 代碼通過 `env.BACKEND_CONTAINER.fetch()` 訪問容器。

## 🎉 完成

部署完成後，您將在 Cloudflare Dashboard 看到所有三個 Worker 和容器實例運行。

## 📚 參考資料

- [Cloudflare Containers 文檔](https://developers.cloudflare.com/workers/runtime-apis/bindings/containers/)
- [Wrangler 配置](https://developers.cloudflare.com/workers/wrangler/configuration/)
- [Workers 部署](https://developers.cloudflare.com/workers/get-started/guide/)

