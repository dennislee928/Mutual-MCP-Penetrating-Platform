# Cloudflare Container Module Variables

variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "image_name" {
  description = "Container image name in Cloudflare"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "dockerhub_image" {
  description = "Source Docker Hub image"
  type        = string
}

variable "max_instances" {
  description = "Maximum container instances"
  type        = number
  default     = 2
  
  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 100
    error_message = "Max instances must be between 1 and 100."
  }
}

variable "instance_type" {
  description = "Container instance type (lite, standard, premium)"
  type        = string
  default     = "lite"
  
  validation {
    condition     = contains(["lite", "standard", "premium"], var.instance_type)
    error_message = "Instance type must be lite, standard, or premium."
  }
}

variable "force_update" {
  description = "Force container update even if image hasn't changed"
  type        = bool
  default     = false
}

variable "create_kv_namespace" {
  description = "Create KV namespace for container state"
  type        = bool
  default     = false
}

