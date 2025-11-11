# Cloudflare Worker Module Outputs

output "worker_id" {
  description = "Worker ID"
  value       = cloudflare_worker_script.worker.id
}

output "worker_name" {
  description = "Worker name"
  value       = cloudflare_worker_script.worker.name
}

output "worker_url" {
  description = "Worker URL"
  value       = var.workers_dev_enabled ? "https://${var.name}.${var.account_id}.workers.dev" : var.custom_domain
}

output "worker_script_id" {
  description = "Worker script ID"
  value       = cloudflare_worker_script.worker.id
}

