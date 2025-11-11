# Cloudflare Container Module Outputs

output "image_url" {
  description = "Cloudflare container image URL"
  value       = data.external.container_info.result.image_url
}

output "image_name" {
  description = "Container image name"
  value       = var.image_name
}

output "registry_path" {
  description = "Full registry path"
  value       = "registry.cloudflare.com/${var.account_id}/${var.image_name}"
}

output "max_instances" {
  description = "Maximum container instances"
  value       = var.max_instances
}

output "instance_type" {
  description = "Container instance type"
  value       = var.instance_type
}

