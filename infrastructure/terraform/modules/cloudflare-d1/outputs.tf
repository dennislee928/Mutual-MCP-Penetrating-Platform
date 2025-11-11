# Cloudflare D1 Module Outputs

output "database_id" {
  description = "D1 database ID"
  value       = cloudflare_d1_database.security_platform.id
}

output "database_name" {
  description = "D1 database name"
  value       = cloudflare_d1_database.security_platform.name
}

output "d1_binding" {
  description = "D1 binding configuration for wrangler.toml"
  value       = local.d1_binding
}

output "binding_name" {
  description = "Binding name for Workers"
  value       = var.binding_name
}

