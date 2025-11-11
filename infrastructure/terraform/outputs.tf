# Terraform Outputs

# D1 Database Outputs
output "d1_database_id" {
  description = "D1 Database ID"
  value       = module.d1_database.database_id
}

output "d1_database_name" {
  description = "D1 Database Name"
  value       = module.d1_database.database_name
}

# HexStrike Worker Outputs
output "hexstrike_worker_url" {
  description = "HexStrike Worker URL"
  value       = module.hexstrike_worker.worker_url
}

output "hexstrike_custom_domain" {
  description = "HexStrike Custom Domain"
  value       = var.cloudflare_zone_id != "" ? "https://hexstrike-self.${data.cloudflare_zone.main[0].name}" : "Use workers.dev domain"
}

output "hexstrike_worker_id" {
  description = "HexStrike Worker ID"
  value       = module.hexstrike_worker.worker_id
}

output "hexstrike_container_image" {
  description = "HexStrike Container Image URL"
  value       = module.hexstrike_container.image_url
}

# Backend Worker Outputs (如果啟用)
output "backend_worker_url" {
  description = "Backend Worker URL"
  value       = var.enable_backend_worker ? module.backend_worker[0].worker_url : "Not deployed"
}

output "backend_custom_domain" {
  description = "Backend Custom Domain"
  value       = var.enable_backend_worker && var.cloudflare_zone_id != "" ? "https://unified-backend.${data.cloudflare_zone.main[0].name}" : "Not configured"
}

# AI Worker Outputs (如果啟用)
output "ai_worker_url" {
  description = "AI/Quantum Worker URL"
  value       = var.enable_ai_worker ? module.ai_worker[0].worker_url : "Not deployed"
}

output "ai_custom_domain" {
  description = "AI/Quantum Custom Domain"
  value       = var.enable_ai_worker && var.cloudflare_zone_id != "" ? "https://unified-ai-quantum.${data.cloudflare_zone.main[0].name}" : "Not configured"
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary with all important information"
  value = {
    environment = var.environment
    project     = var.project_name
    
    database = {
      d1_database_id   = module.d1_database.database_id
      d1_database_name = module.d1_database.database_name
      binding_name     = module.d1_database.binding_name
    }
    
    hexstrike = {
      worker_url     = module.hexstrike_worker.worker_url
      custom_domain  = var.cloudflare_zone_id != "" ? "https://hexstrike-self.${data.cloudflare_zone.main[0].name}" : "Not configured"
      container_name = "hexstrike"
      max_instances  = var.hexstrike_max_instances
    }
    
    backend = var.enable_backend_worker ? {
      worker_url    = module.backend_worker[0].worker_url
      custom_domain = var.cloudflare_zone_id != "" ? "https://unified-backend.${data.cloudflare_zone.main[0].name}" : "Not configured"
    } : "Not deployed"
    
    ai = var.enable_ai_worker ? {
      worker_url    = module.ai_worker[0].worker_url
      custom_domain = var.cloudflare_zone_id != "" ? "https://unified-ai-quantum.${data.cloudflare_zone.main[0].name}" : "Not configured"
    } : "Not deployed"
    
    endpoints = {
      hexstrike_health  = "${module.hexstrike_worker.worker_url}/health"
      hexstrike_attack  = "${module.hexstrike_worker.worker_url}/attack/auto?target=both&intensity=medium"
      backend_health    = var.enable_backend_worker ? "${module.backend_worker[0].worker_url}/health" : "Not deployed"
      backend_dashboard = var.enable_backend_worker ? "${module.backend_worker[0].worker_url}/dashboard" : "Not deployed"
      ai_health         = var.enable_ai_worker ? "${module.ai_worker[0].worker_url}/health" : "Not deployed"
      ai_dashboard      = var.enable_ai_worker ? "${module.ai_worker[0].worker_url}/dashboard" : "Not deployed"
    }
    
    deployed_at = timestamp()
  }
}

# Container Registry Information
output "cloudflare_registry" {
  description = "Cloudflare container registry information"
  value = {
    registry_url = "registry.cloudflare.com/${var.cloudflare_account_id}"
    images = {
      hexstrike = module.hexstrike_container.image_name
    }
  }
}

# Testing Commands
output "testing_commands" {
  description = "Commands to test the deployment"
  value = {
    # HexStrike
    hexstrike_health    = "curl ${module.hexstrike_worker.worker_url}/health"
    hexstrike_attack    = "curl '${module.hexstrike_worker.worker_url}/attack/auto?target=both&intensity=medium'"
    hexstrike_dashboard = "open ${module.hexstrike_worker.worker_url}/dashboard"
    hexstrike_logs      = "wrangler tail unified-hexstrike"
    
    # Backend (if enabled)
    backend_health    = var.enable_backend_worker ? "curl ${module.backend_worker[0].worker_url}/health" : "Not deployed"
    backend_stats     = var.enable_backend_worker ? "curl ${module.backend_worker[0].worker_url}/stats" : "Not deployed"
    backend_dashboard = var.enable_backend_worker ? "open ${module.backend_worker[0].worker_url}/dashboard" : "Not deployed"
    backend_logs      = var.enable_backend_worker ? "wrangler tail unified-backend" : "Not deployed"
    
    # AI (if enabled)
    ai_health     = var.enable_ai_worker ? "curl ${module.ai_worker[0].worker_url}/health" : "Not deployed"
    ai_model_info = var.enable_ai_worker ? "curl ${module.ai_worker[0].worker_url}/model-info" : "Not deployed"
    ai_train      = var.enable_ai_worker ? "curl -X POST ${module.ai_worker[0].worker_url}/train-model" : "Not deployed"
    ai_dashboard  = var.enable_ai_worker ? "open ${module.ai_worker[0].worker_url}/dashboard" : "Not deployed"
    ai_logs       = var.enable_ai_worker ? "wrangler tail unified-ai-quantum" : "Not deployed"
    
    # D1 Database
    d1_query = "wrangler d1 execute ${module.d1_database.database_name} --command 'SELECT COUNT(*) FROM attack_logs'"
    d1_list  = "wrangler d1 list"
  }
}

