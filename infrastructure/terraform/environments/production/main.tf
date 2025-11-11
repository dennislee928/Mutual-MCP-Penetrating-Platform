# Production Environment Configuration

terraform {
  required_version = ">= 1.6.0"
  
  # 生產環境建議使用遠端狀態
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "cloudflare-workers/production/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# 使用主模組
module "infrastructure" {
  source = "../.."
  
  # Cloudflare 配置
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_zone_id    = var.cloudflare_zone_id
  
  # Docker Hub 配置
  dockerhub_username = var.dockerhub_username
  dockerhub_token    = var.dockerhub_token
  
  # 環境配置
  project_name = "unified-security-platform"
  environment  = "production"
  
  # Worker 環境變數
  worker_environment_vars = {
    SERVICE_NAME    = "hexstrike"
    ENVIRONMENT     = "production"
    LOG_LEVEL       = "info"
    API_VERSION     = "v1"
    MAX_CONCURRENCY = "10"
  }
  
  # 容器配置 - 生產環境使用較高規格
  hexstrike_max_instances = 2
  backend_max_instances   = 5
  ai_max_instances        = 3
  
  # Docker 映像
  hexstrike_image = "dennisleetw/hexstrike-ai:latest"
  backend_image   = "dennisleetw/backend:latest"
  ai_image        = "dennisleetw/ai-quantum:latest"
  
  # Feature flags
  enable_backend_worker  = false # 根據需求啟用
  enable_ai_worker       = false # 根據需求啟用
  enable_cloudflare_push = true
  
  # 進階配置
  workers_dev            = true
  preview_urls           = true
  observability_enabled  = true
  
  # 標籤
  tags = {
    Project     = "Unified Security Platform"
    ManagedBy   = "Terraform"
    Environment = "production"
    Team        = "Security"
    CostCenter  = "Engineering"
  }
}

# 輸出
output "hexstrike_worker_url" {
  description = "HexStrike Worker URL"
  value       = module.infrastructure.hexstrike_worker_url
}

output "deployment_summary" {
  description = "Deployment summary"
  value       = module.infrastructure.deployment_summary
}

