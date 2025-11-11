# Terraform Providers Configuration

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
  }
}

# Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Docker Provider (用於本地建置)
provider "docker" {
  host = "npipe:////./pipe/docker_engine" # Windows
  # host = "unix:///var/run/docker.sock"  # Linux/macOS
  
  registry_auth {
    address  = "registry.hub.docker.com"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }
}

