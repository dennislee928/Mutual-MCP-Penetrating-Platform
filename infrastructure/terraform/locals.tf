# Local Values

locals {
  # 通用標籤
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      DeployedAt  = timestamp()
    }
  )
  
  # Worker 名稱前綴
  worker_prefix = "${var.project_name}-${var.environment}"
  
  # 容器配置
  container_registry = "registry.cloudflare.com/${var.cloudflare_account_id}"
  
  # Worker URLs
  hexstrike_url = "https://unified-hexstrike.${var.cloudflare_account_id}.workers.dev"
  backend_url   = var.enable_backend_worker ? "https://unified-backend.${var.cloudflare_account_id}.workers.dev" : ""
  ai_url        = var.enable_ai_worker ? "https://unified-ai-quantum.${var.cloudflare_account_id}.workers.dev" : ""
  
  # 環境特定配置
  env_config = {
    dev = {
      hexstrike_max_instances = 1
      backend_max_instances   = 2
      ai_max_instances        = 1
    }
    staging = {
      hexstrike_max_instances = 2
      backend_max_instances   = 3
      ai_max_instances        = 2
    }
    production = {
      hexstrike_max_instances = 2
      backend_max_instances   = 5
      ai_max_instances        = 3
    }
  }
}

