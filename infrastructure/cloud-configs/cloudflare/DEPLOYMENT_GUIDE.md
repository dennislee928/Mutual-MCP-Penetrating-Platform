# 統一安全平台 - 完整部署指南

## 系統架構概覽

本系統實作了一個三層 ML 自主防禦架構：

- **攻擊層**: HexStrike Worker (`hexstrike-self.dennisleehappy.org`)
- **防禦層**: Backend Worker (`unified-backend.dennisleehappy.org`)
- **學習層**: AI/Quantum Worker (`unified-ai-quantum.dennisleehappy.org`)
- **儲存層**: Cloudflare D1 資料庫

## 部署前準備

### 1. 安裝必要工具

```bash
# 安裝 Wrangler CLI
npm install -g wrangler

# 安裝 Terraform (optional)
# 參考: https://www.terraform.io/downloads
```

### 2. Cloudflare 認證

```bash
# 登入 Cloudflare
wrangler login

# 驗證登入狀態
wrangler whoami
```

### 3. 獲取必要資訊

- **Account ID**: 在 Cloudflare Dashboard 右側查看
- **Zone ID** (如果要使用自定義域名): 在域名概覽頁面查看
- **API Token**: 在 My Profile > API Tokens 創建

## 部署方式選擇

### 方式 A: 使用自動化腳本（推薦）

#### 步驟 1: 執行完整部署腳本

```bash
cd infrastructure/cloud-configs/cloudflare
chmod +x deploy-all-workers.sh
bash deploy-all-workers.sh
```

這個腳本會：
1. 創建 D1 資料庫
2. 執行 SQL Schema
3. 更新 wrangler 配置文件
4. 部署 Backend Worker
5. 部署 AI Worker
6. 部署 HexStrike Worker

#### 步驟 2: 測試部署

```bash
chmod +x test-all-workers.sh
bash test-all-workers.sh
```

### 方式 B: 手動部署

#### 步驟 1: 創建 D1 資料庫

```bash
# 創建資料庫
wrangler d1 create security-platform-db

# 記下返回的 database_id
# 範例輸出：
# ✅ Successfully created DB 'security-platform-db' (12345678-1234-1234-1234-123456789012)
```

#### 步驟 2: 執行 Schema

```bash
cd infrastructure/terraform
wrangler d1 execute security-platform-db --file=d1-schema.sql --remote
```

#### 步驟 3: 更新 Wrangler 配置

編輯以下文件，將 `database_id` 替換為實際 ID：

- `infrastructure/cloud-configs/cloudflare/wrangler-backend.toml`
- `infrastructure/cloud-configs/cloudflare/wrangler-ai.toml`

```toml
[[d1_databases]]
binding = "DB"
database_name = "security-platform-db"
database_id = "12345678-1234-1234-1234-123456789012"  # 替換為實際 ID
```

#### 步驟 4: 部署 Workers

```bash
cd infrastructure/cloud-configs/cloudflare

# 部署 Backend Worker
wrangler deploy --config wrangler-backend.toml

# 部署 AI Worker
wrangler deploy --config wrangler-ai.toml

# 部署 HexStrike Worker
wrangler deploy --config wrangler-hexstrike.toml
```

### 方式 C: 使用 Terraform（進階）

#### 步驟 1: 準備配置

```bash
cd infrastructure/terraform

# 複製範例配置
cp terraform.tfvars.example terraform.tfvars

# 編輯 terraform.tfvars
nano terraform.tfvars
```

#### 步驟 2: 初始化和部署

```bash
# 初始化 Terraform
terraform init

# 查看計劃
terraform plan

# 執行部署
terraform apply
```

## 配置自定義域名

### 方式 1: Cloudflare Dashboard（最簡單）

1. 登入 Cloudflare Dashboard
2. 進入 **Workers & Pages**
3. 對每個 Worker：
   - 選擇 Worker
   - 進入 **Settings** > **Triggers**
   - 在 **Custom Domains** 點擊 **Add Custom Domain**
   - 輸入域名並保存

需要配置的域名：
- `hexstrike-self.dennisleehappy.org` → `unified-hexstrike`
- `unified-backend.dennisleehappy.org` → `unified-backend`
- `unified-ai-quantum.dennisleehappy.org` → `unified-ai-quantum`

### 方式 2: Wrangler CLI

```bash
# HexStrike Worker
wrangler domains add hexstrike-self.dennisleehappy.org --name unified-hexstrike

# Backend Worker
wrangler domains add unified-backend.dennisleehappy.org --name unified-backend

# AI Worker
wrangler domains add unified-ai-quantum.dennisleehappy.org --name unified-ai-quantum
```

## 部署驗證

### 1. Health Checks

```bash
# Backend
curl https://unified-backend.dennisleehappy.org/health

# AI
curl https://unified-ai-quantum.dennisleehappy.org/health

# HexStrike
curl https://hexstrike-self.dennisleehappy.org/health
```

預期輸出：
```json
{
  "status": "ok",
  "service": "backend-defense",
  "timestamp": "2025-11-11T...",
  "db_status": "connected"
}
```

### 2. Dashboard 訪問

在瀏覽器中打開：

- Backend: https://unified-backend.dennisleehappy.org/dashboard
- AI: https://unified-ai-quantum.dennisleehappy.org/dashboard
- HexStrike: https://hexstrike-self.dennisleehappy.org/dashboard

### 3. 功能測試

#### 測試 AI 模型資訊
```bash
curl https://unified-ai-quantum.dennisleehappy.org/model-info
```

#### 測試攻擊模擬
```bash
curl "https://hexstrike-self.dennisleehappy.org/attack/sql-injection?target=backend&count=2"
```

#### 查看攻擊日誌
```bash
curl https://unified-backend.dennisleehappy.org/logs
```

#### 查看統計數據
```bash
curl https://unified-backend.dennisleehappy.org/stats
```

## 完整測試流程

### 1. 發起自動化攻擊

```bash
curl "https://hexstrike-self.dennisleehappy.org/attack/auto?target=both&intensity=medium"
```

這會對 Backend 和 AI Workers 發起多種攻擊：
- SQL Injection
- XSS
- DoS
- Path Traversal

### 2. 檢查防禦響應

```bash
# 查看日誌
curl https://unified-backend.dennisleehappy.org/logs?limit=20

# 查看統計
curl https://unified-backend.dennisleehappy.org/stats
```

### 3. 訓練 ML 模型

```bash
curl -X POST https://unified-ai-quantum.dennisleehappy.org/train-model
```

預期輸出：
```json
{
  "status": "success",
  "model_version": "v1.20251111.1234",
  "training_metrics": {
    "accuracy": 0.9123,
    "precision": 0.8845,
    "recall": 0.9234,
    "f1_score": 0.9032
  },
  "training_samples": 156
}
```

### 4. 再次攻擊，觀察防禦提升

```bash
curl "https://hexstrike-self.dennisleehappy.org/attack/auto?target=backend&intensity=high"
```

### 5. 比較統計數據

```bash
curl https://unified-backend.dennisleehappy.org/stats
```

觀察阻擋率是否提升。

## 實時監控

### 查看 Worker 日誌

```bash
# Backend Worker 日誌
wrangler tail unified-backend

# AI Worker 日誌
wrangler tail unified-ai-quantum

# HexStrike Worker 日誌
wrangler tail unified-hexstrike
```

### 查看 D1 資料庫

```bash
# 查詢總攻擊數
wrangler d1 execute security-platform-db \
  --command "SELECT COUNT(*) FROM attack_logs"

# 查詢最近攻擊
wrangler d1 execute security-platform-db \
  --command "SELECT * FROM attack_logs ORDER BY timestamp DESC LIMIT 10"

# 查詢防禦統計
wrangler d1 execute security-platform-db \
  --command "SELECT attack_type, COUNT(*) as count FROM attack_logs GROUP BY attack_type"
```

## 故障排除

### Worker 無法訪問

1. 檢查部署狀態：
   ```bash
   wrangler deployments list --name unified-backend
   ```

2. 查看錯誤日誌：
   ```bash
   wrangler tail unified-backend
   ```

3. 重新部署：
   ```bash
   wrangler deploy --config wrangler-backend.toml
   ```

### D1 連接失敗

1. 檢查資料庫是否存在：
   ```bash
   wrangler d1 list
   ```

2. 確認 database_id 正確配置在 wrangler.toml

3. 重新執行 schema：
   ```bash
   wrangler d1 execute security-platform-db --file=d1-schema.sql --remote
   ```

### 攻擊無法記錄

1. 檢查 Backend Worker 日誌：
   ```bash
   wrangler tail unified-backend
   ```

2. 測試直接寫入：
   ```bash
   wrangler d1 execute security-platform-db \
     --command "INSERT INTO attack_logs (source, target, attack_type, method, path) VALUES ('test', 'backend', 'test', 'GET', '/test')"
   ```

3. 查詢確認：
   ```bash
   wrangler d1 execute security-platform-db \
     --command "SELECT * FROM attack_logs ORDER BY timestamp DESC LIMIT 5"
   ```

### 自定義域名無法訪問

1. 檢查 DNS 傳播：
   ```bash
   dig hexstrike-self.dennisleehappy.org
   ```

2. 檢查 SSL 證書狀態（在 Cloudflare Dashboard）

3. 等待 5-10 分鐘讓 DNS 和 SSL 配置生效

## 性能優化

### 調整容器實例數

編輯 `wrangler-hexstrike.toml`：
```toml
[[containers]]
max_instances = 5  # 增加並發實例數
```

### 調整攻擊強度

```bash
# 低強度測試
curl "https://hexstrike-self.dennisleehappy.org/attack/auto?intensity=low"

# 高強度測試
curl "https://hexstrike-self.dennisleehappy.org/attack/auto?intensity=high"
```

### 定期模型訓練

設置 cron job 定期訓練模型：
```bash
# 每小時訓練一次
0 * * * * curl -X POST https://unified-ai-quantum.dennisleehappy.org/train-model
```

## 清理資源

### 刪除 Workers

```bash
wrangler delete unified-backend
wrangler delete unified-ai-quantum
wrangler delete unified-hexstrike
```

### 刪除 D1 資料庫

```bash
wrangler d1 delete security-platform-db
```

### 使用 Terraform 清理

```bash
cd infrastructure/terraform
terraform destroy
```

## 下一步

1. **監控設置**：配置 Cloudflare Analytics 和 Alerts
2. **擴展攻擊類型**：添加更多攻擊模式到 HexStrike
3. **改進 ML 模型**：實作更複雜的機器學習算法
4. **整合通知**：添加 Slack/Discord 通知
5. **API 認證**：為敏感端點添加認證機制

## 支援和貢獻

- 遇到問題？查看 [故障排除](#故障排除) 章節
- 有建議？提交 Issue 或 Pull Request
- 查看更多文檔：`setup-custom-domains.md`

## 總結檢查清單

- [ ] Wrangler CLI 已安裝並登入
- [ ] D1 資料庫已創建並初始化
- [ ] 三個 Workers 已成功部署
- [ ] Health checks 全部通過
- [ ] 自定義域名已配置（可選）
- [ ] Dashboards 可正常訪問
- [ ] 攻擊模擬功能正常
- [ ] 日誌記錄正常工作
- [ ] AI 模型訓練成功
- [ ] 防禦響應機制運作正常

---

**恭喜！** 你的統一安全平台已成功部署並運行！🎉

