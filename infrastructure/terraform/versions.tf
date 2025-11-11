# Terraform Version Constraints

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

