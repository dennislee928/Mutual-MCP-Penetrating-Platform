# 🚀 Terraform IaC 快速參考

一頁式命令參考，快速查找所有常用命令。

---

## ⚡ 快速開始（3 步驟）

```bash
# 1. 配置
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # 填入實際值

# 2. 初始化
terraform init

# 3. 部署
terraform apply
```

---

## 📋 常用命令

### Terraform 基本命令

```bash
terraform init          # 初始化
terraform plan          # 查看執行計畫
terraform apply         # 執行部署
terraform apply -auto-approve  # 自動批准部署
terraform destroy       # 銷毀資源
terraform output        # 顯示輸出
terraform fmt           # 格式化程式碼
terraform validate      # 驗證配置
terraform state list    # 列出資源
terraform show          # 顯示狀態
```

### Makefile 命令（Linux/macOS）

```bash
make help           # 顯示幫助
make init           # 初始化
make plan           # 執行計畫
make apply          # 部署
make destroy        # 銷毀
make fmt            # 格式化
make validate       # 驗證
make output         # 顯示輸出
make health-check   # 健康檢查
make clean          # 清理檔案

# 環境特定
make dev-init       # 初始化 dev
make dev-plan       # dev 計畫
make dev-apply      # 部署到 dev
make prod-init      # 初始化 production
make prod-plan      # production 計畫
make prod-apply     # 部署到 production
```

### PowerShell 命令（Windows）

```powershell
.\deploy.ps1                              # 部署到 production
.\deploy.ps1 -Action init                 # 初始化
.\deploy.ps1 -Action plan                 # 執行計畫
.\deploy.ps1 -Action apply                # 部署
.\deploy.ps1 -Action destroy              # 銷毀
.\deploy.ps1 -Action output               # 顯示輸出
.\deploy.ps1 -Action health-check         # 健康檢查
.\deploy.ps1 -Action help                 # 顯示幫助

# 環境特定
.\deploy.ps1 -Action apply -Environment dev        # 部署到 dev
.\deploy.ps1 -Action apply -Environment production # 部署到 production

# 自動批准
.\deploy.ps1 -Action apply -AutoApprove            # 自動部署
```

---

## 🔧 配置文件

### terraform.tfvars 範例

```hcl
# Cloudflare 配置
cloudflare_account_id = "your-account-id"
cloudflare_api_token  = "your-api-token"

# Docker Hub 配置
dockerhub_username = "dennisleetw"
dockerhub_token    = "your-dockerhub-token"

# 專案配置
project_name = "unified-security-platform"
environment  = "production"

# 容器配置
hexstrike_max_instances = 2
hexstrike_image         = "dennisleetw/hexstrike-ai:latest"
```

---

## 📊 目錄結構

```
terraform/
├── main.tf                    # 主配置
├── variables.tf               # 變數
├── outputs.tf                 # 輸出
├── terraform.tfvars          # 配置值（不提交）
├── Makefile                  # Make 命令
├── deploy.ps1                # PowerShell 腳本
├── modules/                  # 模組
│   ├── cloudflare-worker/
│   └── cloudflare-container/
└── environments/             # 環境
    ├── dev/
    └── production/
```

---

## 🎯 常見任務

### 部署到開發環境

```bash
cd environments/dev
terraform init
terraform apply
```

或使用 Makefile:
```bash
make dev-apply
```

### 部署到生產環境

```bash
cd environments/production
terraform init
terraform apply
```

或使用 Makefile:
```bash
make prod-apply
```

### 更新 Docker 映像

```bash
# 1. 更新 terraform.tfvars
hexstrike_image = "dennisleetw/hexstrike-ai:v2"

# 2. 重新部署
terraform apply
```

### 查看部署狀態

```bash
terraform output
terraform state list
terraform show
```

### 健康檢查

```bash
# 使用 make
make health-check

# 手動測試
curl https://unified-hexstrike.your-account.workers.dev/health
```

### 回滾部署

```bash
# 使用狀態備份
terraform apply -backup=terraform.tfstate.backup
```

### 銷毀資源

```bash
terraform destroy

# 只銷毀特定資源
terraform destroy -target=module.hexstrike_worker
```

---

## 🐛 故障排除

### 初始化失敗

```bash
make clean
make init
```

### 容器推送失敗

```bash
# 檢查 Docker
docker info

# 檢查 Wrangler
wrangler whoami

# 手動推送
docker pull dennisleetw/hexstrike-ai:latest
docker tag dennisleetw/hexstrike-ai:latest hexstrike:latest
wrangler containers push hexstrike
```

### Worker 部署失敗

```bash
# 查看詳細錯誤
terraform apply -target=module.hexstrike_worker -var-file=terraform.tfvars

# 查看 Worker 日誌
wrangler tail unified-hexstrike
```

### 配置錯誤

```bash
# 驗證配置
terraform validate

# 格式化配置
terraform fmt -recursive
```

---

## 🔑 環境變數

### Linux/macOS

```bash
export TF_VAR_cloudflare_api_token="your-token"
export TF_VAR_dockerhub_token="your-token"
```

### Windows PowerShell

```powershell
$env:TF_VAR_cloudflare_api_token="your-token"
$env:TF_VAR_dockerhub_token="your-token"
```

### Windows CMD

```cmd
set TF_VAR_cloudflare_api_token=your-token
set TF_VAR_dockerhub_token=your-token
```

---

## 📝 輸出變數

```bash
# 所有輸出
terraform output

# 特定輸出
terraform output hexstrike_worker_url
terraform output -raw hexstrike_worker_url  # 純文本
terraform output -json deployment_summary   # JSON 格式
```

---

## 🔗 重要 URL

### Cloudflare Dashboard
```
https://dash.cloudflare.com
Workers & Pages → unified-hexstrike
```

### Docker Hub
```
https://hub.docker.com/r/dennisleetw/hexstrike-ai
```

### Worker URL（範例）
```
https://unified-hexstrike.your-account.workers.dev
https://unified-hexstrike.your-account.workers.dev/health
```

---

## 📞 獲取幫助

### 文檔
- `README.md` - 主文檔
- `QUICKSTART.md` - 快速開始
- `TERRAFORM_COMPLETE.md` - 完整指南

### 命令
```bash
make help               # Makefile 幫助
.\deploy.ps1 -Action help  # PowerShell 幫助
terraform --help        # Terraform 幫助
```

### 在線資源
- [Terraform 文檔](https://www.terraform.io/docs)
- [Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)

---

## ⚡ 快速參考表

| 任務 | 命令 | 時間 |
|------|------|------|
| 初始化 | `terraform init` | 30s |
| 執行計畫 | `terraform plan` | 10s |
| 部署 | `terraform apply` | 5-10min |
| 更新 | `terraform apply` | 3-5min |
| 銷毀 | `terraform destroy` | 2-3min |
| 健康檢查 | `make health-check` | 5s |

---

## 🚨 重要提醒

1. ⚠️ **不要提交** `terraform.tfvars` 到 Git
2. ⚠️ **定期備份** `terraform.tfstate`
3. ⚠️ **生產環境** 使用遠端狀態
4. ⚠️ **部署前** 執行 `terraform plan`
5. ⚠️ **Secrets** 使用環境變數或 Vault

---

## 🎯 一鍵部署

### Linux/macOS
```bash
make init && make apply && make health-check
```

### Windows PowerShell
```powershell
.\deploy.ps1
```

---

**保存此頁面以便快速參考！** 📌

*最後更新: 2025-11-11*

