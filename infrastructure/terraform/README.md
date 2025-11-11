# Terraform Infrastructure as Code (IaC)

統一安全平台 - Cloudflare Workers 與容器自動化部署

## 📁 目錄結構

```
terraform/
├── README.md                      # 本文件
├── main.tf                        # 主配置入口
├── variables.tf                   # 全局變數定義
├── outputs.tf                     # 輸出配置
├── providers.tf                   # Provider 配置
├── terraform.tfvars.example       # 變數範例檔案
│
├── modules/                       # 可重用模組
│   ├── cloudflare-worker/        # Cloudflare Worker 模組
│   ├── cloudflare-container/     # Cloudflare Container 模組
│   └── docker-build-push/        # Docker 建置推送模組
│
└── environments/                  # 環境配置
    ├── dev/                      # 開發環境
    ├── staging/                  # 測試環境
    └── production/               # 生產環境
```

## 🚀 快速開始

### 前置需求

1. **Terraform** (>= 1.6.0)
   ```bash
   # Windows (Chocolatey)
   choco install terraform
   
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Cloudflare 帳號**
   - Account ID
   - API Token (需要 Workers 和 Containers 權限)

3. **Docker Hub 帳號**
   - Username
   - Access Token

### 初始化配置

1. **複製變數範例檔案**
   ```bash
   cd infrastructure/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **編輯 terraform.tfvars**
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
   ```

3. **初始化 Terraform**
   ```bash
   terraform init
   ```

### 部署步驟

#### 方案 1：完整部署（推薦）

```bash
# 1. 檢查執行計畫
terraform plan

# 2. 執行部署
terraform apply

# 3. 查看輸出
terraform output
```

#### 方案 2：分階段部署

```bash
# 階段 1: 只建置 Docker 映像
terraform apply -target=module.docker_hexstrike

# 階段 2: 推送到 Cloudflare
terraform apply -target=module.cloudflare_hexstrike_container

# 階段 3: 部署 Worker
terraform apply -target=module.cloudflare_hexstrike_worker
```

#### 方案 3: 特定環境部署

```bash
# 部署到開發環境
cd environments/dev
terraform init
terraform apply

# 部署到生產環境
cd environments/production
terraform init
terraform apply
```

## 📦 模組說明

### 1. cloudflare-worker 模組

部署 Cloudflare Worker 並配置綁定。

**輸入變數**:
- `name`: Worker 名稱
- `account_id`: Cloudflare Account ID
- `script_path`: Worker 腳本路徑
- `container_image`: 容器映像 URL
- `environment_vars`: 環境變數 map

**輸出**:
- `worker_url`: Worker 的公開 URL
- `worker_id`: Worker ID

**使用範例**:
```hcl
module "hexstrike_worker" {
  source = "./modules/cloudflare-worker"
  
  name       = "unified-hexstrike"
  account_id = var.cloudflare_account_id
  
  script_path = "${path.module}/../../cloud-configs/cloudflare/src/hexstrike-worker.js"
  
  container_image = module.hexstrike_container.image_url
  
  environment_vars = {
    SERVICE_NAME = "hexstrike"
    ENVIRONMENT  = "production"
  }
}
```

### 2. cloudflare-container 模組

管理 Cloudflare 容器註冊表和映像。

**輸入變數**:
- `account_id`: Cloudflare Account ID
- `image_name`: 映像名稱
- `dockerhub_image`: Docker Hub 映像來源
- `max_instances`: 最大實例數

**輸出**:
- `image_url`: Cloudflare 容器映像 URL
- `image_digest`: 映像 digest

**使用範例**:
```hcl
module "hexstrike_container" {
  source = "./modules/cloudflare-container"
  
  account_id      = var.cloudflare_account_id
  image_name      = "hexstrike"
  dockerhub_image = "dennisleetw/hexstrike-ai:latest"
  max_instances   = 2
}
```

### 3. docker-build-push 模組

自動化 Docker 映像建置和推送。

**輸入變數**:
- `image_name`: 映像名稱
- `image_tag`: 映像標籤
- `dockerfile_path`: Dockerfile 路徑
- `build_context`: 建置上下文路徑
- `dockerhub_username`: Docker Hub 用戶名
- `registry_push`: 是否推送到註冊表

**輸出**:
- `image_full_name`: 完整映像名稱
- `image_digest`: 映像 digest

**使用範例**:
```hcl
module "docker_hexstrike" {
  source = "./modules/docker-build-push"
  
  image_name         = "dennisleetw/hexstrike-ai"
  image_tag          = "latest"
  dockerfile_path    = "${path.module}/../../src/hexstrike-ai/Dockerfile"
  build_context      = "${path.module}/../../src/hexstrike-ai"
  dockerhub_username = var.dockerhub_username
  registry_push      = true
}
```

## 🔧 進階配置

### 自訂環境變數

在 `terraform.tfvars` 中添加：

```hcl
worker_environment_vars = {
  SERVICE_NAME    = "hexstrike-ai"
  ENVIRONMENT     = "production"
  LOG_LEVEL       = "info"
  API_VERSION     = "v1"
  MAX_CONCURRENCY = "10"
}
```

### 配置多個 Worker

```hcl
# Backend Worker
module "backend_worker" {
  source = "./modules/cloudflare-worker"
  # ... 配置
}

# AI Worker
module "ai_worker" {
  source = "./modules/cloudflare-worker"
  # ... 配置
}

# HexStrike Worker
module "hexstrike_worker" {
  source = "./modules/cloudflare-worker"
  # ... 配置
}
```

### 配置 Secrets

```hcl
resource "cloudflare_workers_secret" "db_password" {
  account_id  = var.cloudflare_account_id
  script_name = module.backend_worker.worker_name
  name        = "DB_PASSWORD"
  secret_text = var.db_password
}
```

### 配置自訂網域

```hcl
resource "cloudflare_worker_route" "hexstrike_route" {
  zone_id     = var.cloudflare_zone_id
  pattern     = "api.hexstrike.example.com/*"
  script_name = module.hexstrike_worker.worker_name
}
```

## 📊 狀態管理

### 本地狀態（開發）

預設使用本地 `terraform.tfstate` 檔案。

### 遠端狀態（生產）

建議使用 S3 或 Terraform Cloud：

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "cloudflare-workers/terraform.tfstate"
    region = "us-east-1"
  }
}
```

或使用 Terraform Cloud：

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "cloudflare-workers-prod"
    }
  }
}
```

## 🧪 測試

### 驗證配置

```bash
# 檢查語法
terraform fmt -check

# 驗證配置
terraform validate

# 檢查執行計畫
terraform plan
```

### 測試部署

```bash
# 部署到開發環境
cd environments/dev
terraform apply

# 測試 Worker
curl https://unified-hexstrike-dev.your-subdomain.workers.dev/health
```

## 🔄 CI/CD 整合

### GitHub Actions 範例

```yaml
name: Deploy to Cloudflare

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Init
        working-directory: infrastructure/terraform
        run: terraform init
        env:
          TF_VAR_cloudflare_api_token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      
      - name: Terraform Plan
        working-directory: infrastructure/terraform
        run: terraform plan
      
      - name: Terraform Apply
        working-directory: infrastructure/terraform
        run: terraform apply -auto-approve
        env:
          TF_VAR_cloudflare_api_token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          TF_VAR_dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
```

## 🛠️ 維護

### 更新映像

```bash
# 1. 更新 Docker Hub 映像
# 手動或透過 CI/CD 推送新版本

# 2. 更新 Terraform 配置
# 修改 terraform.tfvars 中的映像標籤

# 3. 重新部署
terraform apply
```

### 回滾部署

```bash
# 查看歷史狀態
terraform state list

# 回滾到先前狀態（需要備份）
terraform apply -auto-approve -backup=terraform.tfstate.backup

# 或使用 Terraform Cloud 的版本控制
```

### 刪除資源

```bash
# 刪除特定 Worker
terraform destroy -target=module.hexstrike_worker

# 刪除所有資源
terraform destroy
```

## 📚 資源

### 官方文檔
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare Workers 文檔](https://developers.cloudflare.com/workers/)
- [Cloudflare Containers 文檔](https://developers.cloudflare.com/containers/)

### 範例專案
- [Cloudflare Terraform Examples](https://github.com/cloudflare/terraform-cloudflare-examples)

## 🐛 故障排除

### 常見問題

**Q: Terraform 無法推送 Docker 映像**
```
解決方案：
1. 確認 Docker daemon 運行中
2. 先手動建置並推送映像
3. 使用 null_resource 執行外部腳本
```

**Q: Worker 部署失敗 - "Invalid image tag"**
```
解決方案：
1. 確認使用 digest 而非 latest tag
2. 檢查映像已推送到 Cloudflare
```

**Q: Terraform state 衝突**
```
解決方案：
1. 使用 terraform state 命令檢查
2. 考慮使用遠端狀態管理
3. 在團隊中協調部署時間
```

## 💡 最佳實踐

1. **使用模組**: 保持配置 DRY (Don't Repeat Yourself)
2. **環境隔離**: 為 dev/staging/prod 使用不同的狀態檔案
3. **版本鎖定**: 在 `versions.tf` 中鎖定 provider 版本
4. **Secrets 管理**: 使用環境變數或 Vault，不要提交到 Git
5. **計畫審查**: 總是先執行 `terraform plan`
6. **狀態備份**: 定期備份 `terraform.tfstate`
7. **文檔更新**: 保持文檔與程式碼同步

## 📝 變更日誌

### v1.0.0 (2025-11-11)
- ✅ 初始版本
- ✅ HexStrike AI Worker 模組
- ✅ Cloudflare Container 支援
- ✅ Docker 建置整合
- ✅ 多環境配置

---

**需要幫助？** 查看 [故障排除](#故障排除) 或創建 GitHub Issue。

