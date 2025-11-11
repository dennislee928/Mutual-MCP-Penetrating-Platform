# 🚀 Terraform IaC 快速開始指南

只需 5 分鐘，將 HexStrike AI 部署到 Cloudflare Workers！

## ⚡ 超快速開始（3 步驟）

### 步驟 1: 配置憑證

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars

# 編輯 terraform.tfvars，填入：
# - cloudflare_account_id
# - cloudflare_api_token
# - dockerhub_username
# - dockerhub_token
```

### 步驟 2: 初始化 Terraform

```bash
terraform init
```

### 步驟 3: 部署！

```bash
terraform apply
```

就是這麼簡單！🎉

---

## 📋 詳細步驟

### 前置需求

1. **安裝 Terraform** (>= 1.6.0)
   
   **Windows** (PowerShell 以管理員運行):
   ```powershell
   # 使用 Chocolatey
   choco install terraform
   
   # 或下載並安裝
   # https://www.terraform.io/downloads
   ```
   
   **macOS**:
   ```bash
   brew install terraform
   ```
   
   **Linux**:
   ```bash
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **獲取 Cloudflare 憑證**
   
   - **Account ID**: 
     - 登入 https://dash.cloudflare.com
     - URL 中的字串: `https://dash.cloudflare.com/<account-id>`
   
   - **API Token**:
     - My Profile → API Tokens → Create Token
     - 選擇 "Edit Cloudflare Workers" 模板
     - 添加 "Containers" 權限
     - Create Token

3. **獲取 Docker Hub 憑證**
   
   - 登入 https://hub.docker.com
   - Account Settings → Security → New Access Token
   - 複製 token

### 使用方式

#### 方式 1: 使用 Makefile（推薦）

```bash
# 查看所有命令
make help

# 初始化
make init

# 查看執行計畫
make plan

# 部署
make apply

# 查看輸出
make output

# 健康檢查
make health-check
```

#### 方式 2: 直接使用 Terraform 命令

```bash
# 初始化
terraform init

# 查看計畫
terraform plan

# 部署
terraform apply

# 查看輸出
terraform output

# 銷毀
terraform destroy
```

#### 方式 3: 使用 PowerShell 腳本（Windows）

```powershell
# 初始化和部署
.\deploy.ps1

# 查看輸出
.\deploy.ps1 -Action output

# 健康檢查
.\deploy.ps1 -Action health-check
```

### 環境特定部署

```bash
# 開發環境
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars
terraform init
terraform apply

# 生產環境
cd environments/production
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars
terraform init
terraform apply
```

或使用 Makefile：

```bash
# 開發環境
make dev-init
make dev-apply

# 生產環境
make prod-init
make prod-apply
```

## 🧪 驗證部署

### 1. 查看輸出

```bash
terraform output
```

你將看到：
```
hexstrike_worker_url = "https://unified-hexstrike.your-account.workers.dev"
deployment_summary = {
  endpoints = {
    health_check = "https://unified-hexstrike.your-account.workers.dev/health"
  }
  ...
}
```

### 2. 測試 Health Check

```bash
# 使用輸出的 URL
curl https://unified-hexstrike.your-account.workers.dev/health

# 或使用 make
make health-check
```

預期回應：
```json
{
  "status": "ok",
  "service": "hexstrike-ai",
  "timestamp": "2025-11-11T03:00:00.000Z"
}
```

### 3. 查看 Worker 日誌

```bash
wrangler tail unified-hexstrike
```

### 4. 在 Cloudflare Dashboard 查看

1. 登入 https://dash.cloudflare.com
2. Workers & Pages → unified-hexstrike
3. 查看部署狀態和日誌

## 🔄 更新部署

### 更新 Docker 映像

1. 推送新映像到 Docker Hub
2. 更新 `terraform.tfvars` 中的映像標籤（或使用相同標籤）
3. 重新部署：

```bash
terraform apply
```

### 更新 Worker 代碼

1. 修改 Worker 腳本（`src/hexstrike-worker.js`）
2. 重新部署：

```bash
terraform apply
```

### 更新配置

1. 修改 `terraform.tfvars`
2. 重新部署：

```bash
terraform apply
```

## 🗑️ 清理資源

### 銷毀所有資源

```bash
terraform destroy
```

或使用 Makefile：

```bash
make destroy
```

### 只銷毀特定資源

```bash
# 只銷毀 HexStrike Worker
terraform destroy -target=module.hexstrike_worker

# 只銷毀容器
terraform destroy -target=module.hexstrike_container
```

## 🔧 故障排除

### 問題：Terraform 初始化失敗

```bash
# 清理並重新初始化
make clean
make init
```

### 問題：容器推送失敗

```bash
# 確認 Docker 運行
docker info

# 確認 wrangler 已安裝
wrangler --version

# 確認已登入 Cloudflare
wrangler whoami
```

### 問題：Worker 部署失敗

```bash
# 查看詳細錯誤
terraform apply -var-file=terraform.tfvars -target=module.hexstrike_worker

# 手動測試 wrangler 部署
cd ../../cloud-configs/cloudflare
wrangler deploy --config wrangler-hexstrike.toml
```

### 問題：Health Check 失敗

```bash
# 等待幾秒讓 Worker 啟動
sleep 10

# 再次測試
curl https://unified-hexstrike.your-account.workers.dev/health

# 查看 Worker 日誌
wrangler tail unified-hexstrike
```

## 📚 進階用法

### 使用變數覆蓋

```bash
terraform apply \
  -var="hexstrike_max_instances=5" \
  -var="environment=staging"
```

### 使用目標部署

```bash
# 只部署容器
terraform apply -target=module.hexstrike_container

# 只部署 Worker
terraform apply -target=module.hexstrike_worker
```

### 使用 Terraform Workspaces

```bash
# 創建 dev workspace
terraform workspace new dev
terraform apply

# 創建 prod workspace
terraform workspace new prod
terraform apply

# 切換 workspace
terraform workspace select dev
```

### 導出執行計畫

```bash
# 生成並保存計畫
terraform plan -out=tfplan

# 執行保存的計畫
terraform apply tfplan
```

## 🚀 CI/CD 整合

查看 `.github/workflows/terraform.yml` 了解 GitHub Actions 整合範例。

查看 `.gitlab-ci.yml` 了解 GitLab CI 整合範例。

## 💡 提示和技巧

1. **使用 Makefile**: 簡化命令執行
2. **使用環境配置**: 為不同環境維護獨立配置
3. **版本鎖定**: 使用 `.terraform.lock.hcl` 鎖定 provider 版本
4. **遠端狀態**: 生產環境使用 S3 或 Terraform Cloud
5. **Secrets 管理**: 不要提交 `terraform.tfvars` 到 Git
6. **定期備份**: 備份 `terraform.tfstate` 檔案

## 🎓 學習資源

- [Terraform 官方文檔](https://www.terraform.io/docs)
- [Cloudflare Provider 文檔](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform 最佳實踐](https://www.terraform-best-practices.com/)

---

**需要幫助？** 查看 [README.md](./README.md) 或創建 GitHub Issue。

