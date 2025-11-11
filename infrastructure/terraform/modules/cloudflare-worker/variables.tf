# Cloudflare Worker Module Variables

variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "name" {
  description = "Worker name"
  type        = string
}

variable "script_path" {
  description = "Path to Worker script file"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "compatibility_date" {
  description = "Compatibility date for Worker"
  type        = string
  default     = "2025-11-10"
}

variable "compatibility_flags" {
  description = "Compatibility flags for Worker"
  type        = list(string)
  default     = ["nodejs_compat"]
}

variable "environment_vars" {
  description = "Environment variables for Worker"
  type        = map(string)
  default     = {}
}

variable "durable_object_namespaces" {
  description = "Durable Object namespace bindings"
  type = list(object({
    name         = string
    namespace_id = string
    class_name   = string
  }))
  default = []
}

variable "service_bindings" {
  description = "Service bindings for Worker"
  type = list(object({
    name        = string
    service     = string
    environment = optional(string, "production")
  }))
  default = []
}

variable "workers_dev_enabled" {
  description = "Enable workers.dev subdomain"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Custom domain for Worker (optional)"
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "Cloudflare Zone ID for custom domain"
  type        = string
  default     = ""
}

variable "route_pattern" {
  description = "Route pattern for custom domain"
  type        = string
  default     = "*"
}

