# Development Environment Configuration

terraform {
  required_version = ">= 1.6.0"
  
  # 開發環境可以使用本地狀態
  # 或使用遠端狀態以便團隊協作
}

# 使用主模組
module "infrastructure" {
  source = "../.."
  
  # Cloudflare 配置
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_api_token  = var.cloudflare_api_token
  
  # Docker Hub 配置
  dockerhub_username = var.dockerhub_username
  dockerhub_token    = var.dockerhub_token
  
  # 環境配置
  project_name = "unified-security-platform"
  environment  = "dev"
  
  # Worker 環境變數
  worker_environment_vars = {
    SERVICE_NAME    = "hexstrike"
    ENVIRONMENT     = "dev"
    LOG_LEVEL       = "debug" # 開發環境使用 debug
    API_VERSION     = "v1"
    MAX_CONCURRENCY = "5"
  }
  
  # 容器配置 - 開發環境使用較低規格
  hexstrike_max_instances = 1
  backend_max_instances   = 2
  ai_max_instances        = 1
  
  # Docker 映像 - 可以使用 dev tag
  hexstrike_image = "dennisleetw/hexstrike-ai:dev"
  # backend_image   = "dennisleetw/backend:dev"
  # ai_image        = "dennisleetw/ai-quantum:dev"
  
  # Feature flags
  enable_backend_worker  = false
  enable_ai_worker       = false
  enable_cloudflare_push = true
  
  # 進階配置
  workers_dev            = true
  preview_urls           = true
  observability_enabled  = true
  
  # 標籤
  tags = {
    Project     = "Unified Security Platform"
    ManagedBy   = "Terraform"
    Environment = "dev"
    Team        = "Development"
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

output "testing_commands" {
  description = "Testing commands"
  value       = module.infrastructure.testing_commands
}

