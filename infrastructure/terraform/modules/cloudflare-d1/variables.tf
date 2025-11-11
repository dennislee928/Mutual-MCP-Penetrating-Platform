# Cloudflare D1 Module Variables

variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "D1 database name"
  type        = string
}

variable "binding_name" {
  description = "Binding name for Workers to access D1"
  type        = string
  default     = "DB"
}

variable "schema_file_path" {
  description = "Path to SQL schema file"
  type        = string
}

