# Global Variables

# Cloudflare Configuration
variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID (optional, for custom domains)"
  type        = string
  default     = ""
}

# Docker Hub Configuration
variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub access token"
  type        = string
  sensitive   = true
}

# Project Configuration
variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "unified-security-platform"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# Worker Configuration
variable "worker_environment_vars" {
  description = "Environment variables for Workers"
  type        = map(string)
  default = {
    SERVICE_NAME = "hexstrike"
    ENVIRONMENT  = "production"
  }
}

# Container Configuration
variable "hexstrike_max_instances" {
  description = "Maximum container instances for HexStrike"
  type        = number
  default     = 2
  
  validation {
    condition     = var.hexstrike_max_instances >= 1 && var.hexstrike_max_instances <= 10
    error_message = "Max instances must be between 1 and 10."
  }
}

variable "backend_max_instances" {
  description = "Maximum container instances for Backend"
  type        = number
  default     = 5
}

variable "ai_max_instances" {
  description = "Maximum container instances for AI/Quantum"
  type        = number
  default     = 3
}

# Docker Image Configuration
variable "hexstrike_image" {
  description = "HexStrike Docker image"
  type        = string
  default     = "dennisleetw/hexstrike-ai:latest"
}

variable "backend_image" {
  description = "Backend Docker image"
  type        = string
  default     = "dennisleetw/backend:latest"
}

variable "ai_image" {
  description = "AI/Quantum Docker image"
  type        = string
  default     = "dennisleetw/ai-quantum:latest"
}

# Feature Flags
variable "enable_backend_worker" {
  description = "Enable Backend Worker deployment"
  type        = bool
  default     = false
}

variable "enable_ai_worker" {
  description = "Enable AI/Quantum Worker deployment"
  type        = bool
  default     = false
}

variable "enable_docker_build" {
  description = "Enable Docker image building (requires Docker daemon)"
  type        = bool
  default     = false
}

variable "enable_cloudflare_push" {
  description = "Enable pushing to Cloudflare container registry"
  type        = bool
  default     = true
}

# Advanced Configuration
variable "workers_dev" {
  description = "Enable workers.dev subdomain"
  type        = bool
  default     = true
}

variable "preview_urls" {
  description = "Enable preview URLs"
  type        = bool
  default     = true
}

variable "observability_enabled" {
  description = "Enable observability features"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Unified Security Platform"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
