# Main Terraform Configuration
# 統一安全平台 - Cloudflare Workers 部署

# ========================================
# Cloudflare D1 資料庫
# ========================================

module "d1_database" {
  source = "./modules/cloudflare-d1"
  
  account_id       = var.cloudflare_account_id
  api_token        = var.cloudflare_api_token
  database_name    = "security-platform-db"
  binding_name     = "DB"
  schema_file_path = "${path.module}/d1-schema.sql"
}

# ========================================
# HexStrike AI 容器和 Worker
# ========================================

# HexStrike 容器推送
module "hexstrike_container" {
  source = "./modules/cloudflare-container"
  
  account_id      = var.cloudflare_account_id
  api_token       = var.cloudflare_api_token
  image_name      = "hexstrike"
  dockerhub_image = var.hexstrike_image
  max_instances   = var.hexstrike_max_instances
  instance_type   = "lite"
  
  force_update = var.enable_cloudflare_push
}

# HexStrike Worker
module "hexstrike_worker" {
  source     = "./modules/cloudflare-worker"
  depends_on = [module.hexstrike_container]
  
  account_id = var.cloudflare_account_id
  name       = "unified-hexstrike"
  
  script_path = "${path.module}/../cloud-configs/cloudflare/src/hexstrike-worker.js"
  
  environment         = var.environment
  compatibility_date  = "2025-11-10"
  compatibility_flags = ["nodejs_compat"]
  
  environment_vars = merge(
    var.worker_environment_vars,
    {
      SERVICE_NAME = "hexstrike"
      ENVIRONMENT  = var.environment
    }
  )
  
  # Note: Durable Objects namespaces 需要在 Worker script 中定義
  # 然後通過 wrangler.toml 配置綁定
  # Terraform Cloudflare Provider 對 Durable Objects 的支援有限
  
  workers_dev_enabled = var.workers_dev
  custom_domain       = var.cloudflare_zone_id != "" ? "hexstrike-self.${data.cloudflare_zone.main[0].name}" : ""
  zone_id             = var.cloudflare_zone_id
  route_pattern       = var.cloudflare_zone_id != "" ? "hexstrike-self.${data.cloudflare_zone.main[0].name}/*" : "*"
}

# ========================================
# Backend Worker (防禦層 - 純 JS Worker)
# ========================================

module "backend_worker" {
  count      = var.enable_backend_worker ? 1 : 0
  source     = "./modules/cloudflare-worker"
  depends_on = [module.d1_database]
  
  account_id = var.cloudflare_account_id
  name       = "unified-backend"
  
  script_path = "${path.module}/../cloud-configs/cloudflare/src/backend-worker.js"
  
  environment         = var.environment
  compatibility_date  = "2025-11-10"
  compatibility_flags = ["nodejs_compat"]
  
  environment_vars = merge(
    var.worker_environment_vars,
    {
      SERVICE_NAME = "backend"
      ENVIRONMENT  = var.environment
      AI_WORKER_URL = "https://unified-ai-quantum.dennisleehappy.org"
    }
  )
  
  workers_dev_enabled = var.workers_dev
  custom_domain       = var.cloudflare_zone_id != "" ? "unified-backend.${data.cloudflare_zone.main[0].name}" : ""
  zone_id             = var.cloudflare_zone_id
  route_pattern       = var.cloudflare_zone_id != "" ? "unified-backend.${data.cloudflare_zone.main[0].name}/*" : "*"
  
  # D1 資料庫 binding 將在 wrangler.toml 中配置
}

# ========================================
# AI/Quantum Worker (ML 防禦層 - 純 JS Worker)
# ========================================

module "ai_worker" {
  count      = var.enable_ai_worker ? 1 : 0
  source     = "./modules/cloudflare-worker"
  depends_on = [module.d1_database]
  
  account_id = var.cloudflare_account_id
  name       = "unified-ai-quantum"
  
  script_path = "${path.module}/../cloud-configs/cloudflare/src/ai-worker.js"
  
  environment         = var.environment
  compatibility_date  = "2025-11-10"
  compatibility_flags = ["nodejs_compat"]
  
  environment_vars = merge(
    var.worker_environment_vars,
    {
      SERVICE_NAME    = "ai-quantum"
      ENVIRONMENT     = var.environment
      MODEL_VERSION   = "v1.0.0-baseline"
    }
  )
  
  workers_dev_enabled = var.workers_dev
  custom_domain       = var.cloudflare_zone_id != "" ? "unified-ai-quantum.${data.cloudflare_zone.main[0].name}" : ""
  zone_id             = var.cloudflare_zone_id
  route_pattern       = var.cloudflare_zone_id != "" ? "unified-ai-quantum.${data.cloudflare_zone.main[0].name}/*" : "*"
  
  # D1 資料庫 binding 將在 wrangler.toml 中配置
}

# ========================================
# DNS and Networking (Optional)
# ========================================

data "cloudflare_zone" "main" {
  count = var.cloudflare_zone_id != "" ? 1 : 0
  
  zone_id = var.cloudflare_zone_id
}

# ========================================
# Monitoring and Observability
# ========================================

# Worker Analytics (requires Cloudflare Pro plan)
# resource "cloudflare_worker_analytics" "hexstrike" {
#   count = var.observability_enabled ? 1 : 0
#   
#   account_id  = var.cloudflare_account_id
#   script_name = module.hexstrike_worker.worker_name
# }

# ========================================
# Outputs and Health Checks
# ========================================

# Health check script
resource "null_resource" "health_check" {
  depends_on = [
    module.hexstrike_worker
  ]
  
  triggers = {
    worker_url = module.hexstrike_worker.worker_url
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Worker to be ready..."
      sleep 10
      echo "Testing health check endpoint..."
      curl -f ${module.hexstrike_worker.worker_url}/health || echo "Health check failed"
    EOT
    
    interpreter = ["bash", "-c"]
  }
}

