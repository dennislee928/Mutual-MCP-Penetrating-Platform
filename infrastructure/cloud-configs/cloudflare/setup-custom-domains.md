# 自定義域名配置指南

本文檔說明如何為三個 Workers 配置自定義域名。

## 所需域名

1. **HexStrike Worker (攻擊層)**
   - 域名: `hexstrike-self.dennisleehappy.org`
   - Worker: `unified-hexstrike`

2. **Backend Worker (防禦層)**
   - 域名: `unified-backend.dennisleehappy.org`
   - Worker: `unified-backend`

3. **AI Worker (ML 防禦層)**
   - 域名: `unified-ai-quantum.dennisleehappy.org`
   - Worker: `unified-ai-quantum`

## 方法 1: 使用 Cloudflare Dashboard（推薦）

### 步驟

1. **登入 Cloudflare Dashboard**
   - 訪問: https://dash.cloudflare.com/
   - 選擇域名: `dennisleehappy.org`

2. **為每個 Worker 添加自定義域名**

   對於每個 Worker，執行以下操作：

   a. 進入 **Workers & Pages**
   
   b. 選擇對應的 Worker（如 `unified-hexstrike`）
   
   c. 點擊 **Settings** > **Triggers**
   
   d. 在 **Custom Domains** 區域點擊 **Add Custom Domain**
   
   e. 輸入完整域名（如 `hexstrike-self.dennisleehappy.org`）
   
   f. 點擊 **Add Custom Domain**
   
   g. Cloudflare 會自動創建 DNS 記錄並配置 SSL

3. **驗證配置**

   等待幾分鐘後，測試每個域名：

   ```bash
   curl https://hexstrike-self.dennisleehappy.org/health
   curl https://unified-backend.dennisleehappy.org/health
   curl https://unified-ai-quantum.dennisleehappy.org/health
   ```

## 方法 2: 使用 Wrangler CLI

### 前提條件

確保已登入 Wrangler：
```bash
wrangler login
```

### 為每個 Worker 添加域名

1. **HexStrike Worker**
   ```bash
   wrangler domains add hexstrike-self.dennisleehappy.org --name unified-hexstrike
   ```

2. **Backend Worker**
   ```bash
   wrangler domains add unified-backend.dennisleehappy.org --name unified-backend
   ```

3. **AI Worker**
   ```bash
   wrangler domains add unified-ai-quantum.dennisleehappy.org --name unified-ai-quantum
   ```

### 驗證域名

```bash
wrangler domains list
```

## 方法 3: 使用 Terraform（自動化）

如果使用 Terraform，域名配置已包含在 `infrastructure/terraform/main.tf` 中。

執行以下命令：

```bash
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

## DNS 記錄

配置完成後，你的 DNS 記錄應該如下：

| 類型 | 名稱 | 內容 | Proxy |
|------|------|------|-------|
| CNAME | hexstrike-self | unified-hexstrike.workers.dev | ✅ |
| CNAME | unified-backend | unified-backend.workers.dev | ✅ |
| CNAME | unified-ai-quantum | unified-ai-quantum.workers.dev | ✅ |

> **注意**: 使用 Custom Domains 功能時，Cloudflare 會自動管理這些 DNS 記錄。

## SSL/TLS 配置

Cloudflare 自動為自定義域名配置 SSL/TLS：

- 自動頒發 SSL 證書
- 強制 HTTPS
- 支援 TLS 1.2+

## 測試端點

配置完成後，測試以下端點：

### HexStrike Worker
```bash
# Health check
curl https://hexstrike-self.dennisleehappy.org/health

# Dashboard
open https://hexstrike-self.dennisleehappy.org/dashboard

# 發起攻擊
curl "https://hexstrike-self.dennisleehappy.org/attack/auto?target=both&intensity=medium"
```

### Backend Worker
```bash
# Health check
curl https://unified-backend.dennisleehappy.org/health

# Dashboard
open https://unified-backend.dennisleehappy.org/dashboard

# 查看日誌
curl https://unified-backend.dennisleehappy.org/logs

# 統計數據
curl https://unified-backend.dennisleehappy.org/stats
```

### AI Worker
```bash
# Health check
curl https://unified-ai-quantum.dennisleehappy.org/health

# Dashboard
open https://unified-ai-quantum.dennisleehappy.org/dashboard

# 模型資訊
curl https://unified-ai-quantum.dennisleehappy.org/model-info

# 訓練模型
curl -X POST https://unified-ai-quantum.dennisleehappy.org/train-model
```

## 故障排除

### 域名無法訪問

1. 檢查 DNS 傳播狀態：
   ```bash
   dig hexstrike-self.dennisleehappy.org
   ```

2. 檢查 Worker 部署狀態：
   ```bash
   wrangler deployments list --name unified-hexstrike
   ```

3. 查看 Worker 日誌：
   ```bash
   wrangler tail unified-hexstrike
   ```

### SSL 證書問題

1. 確認 Cloudflare SSL/TLS 模式設為 **Full** 或 **Full (Strict)**
2. 等待證書頒發（通常需要 5-10 分鐘）
3. 檢查證書狀態：在 Dashboard 的 SSL/TLS > Edge Certificates

### 404 錯誤

1. 確認 Worker 已正確部署
2. 檢查 wrangler.toml 配置
3. 重新部署 Worker：
   ```bash
   wrangler deploy --config wrangler-hexstrike.toml
   ```

## 更新 wrangler.toml（可選）

如果要在 `wrangler.toml` 中明確指定域名路由，取消註釋以下行：

### wrangler-hexstrike.toml
```toml
routes = [
  { pattern = "hexstrike-self.dennisleehappy.org/*", zone_name = "dennisleehappy.org" }
]
```

### wrangler-backend.toml
```toml
routes = [
  { pattern = "unified-backend.dennisleehappy.org/*", zone_name = "dennisleehappy.org" }
]
```

### wrangler-ai.toml
```toml
routes = [
  { pattern = "unified-ai-quantum.dennisleehappy.org/*", zone_name = "dennisleehappy.org" }
]
```

然後重新部署：
```bash
wrangler deploy --config wrangler-hexstrike.toml
wrangler deploy --config wrangler-backend.toml
wrangler deploy --config wrangler-ai.toml
```

## 總結

- ✅ 使用 Cloudflare Dashboard 添加自定義域名是最簡單的方法
- ✅ Cloudflare 自動處理 DNS 和 SSL 配置
- ✅ 配置通常在 5-10 分鐘內生效
- ✅ 使用 `wrangler domains` 命令可以快速管理域名

