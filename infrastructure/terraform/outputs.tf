# Terraform Outputs

# HexStrike Worker Outputs
output "hexstrike_worker_url" {
  description = "HexStrike Worker URL"
  value       = module.hexstrike_worker.worker_url
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
  value       = try(module.backend_worker[0].worker_url, "Not deployed")
}

# AI Worker Outputs (如果啟用)
output "ai_worker_url" {
  description = "AI/Quantum Worker URL"
  value       = try(module.ai_worker[0].worker_url, "Not deployed")
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary with all important information"
  value = {
    environment = var.environment
    project     = var.project_name
    
    hexstrike = {
      worker_url     = module.hexstrike_worker.worker_url
      container_name = "hexstrike"
      max_instances  = var.hexstrike_max_instances
    }
    
    endpoints = {
      health_check = "${module.hexstrike_worker.worker_url}/health"
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
    health_check = "curl ${module.hexstrike_worker.worker_url}/health"
    view_logs    = "wrangler tail unified-hexstrike"
    deployments  = "wrangler deployments list --name unified-hexstrike"
  }
}

