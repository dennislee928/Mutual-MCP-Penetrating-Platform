# Cloudflare Worker Module

resource "cloudflare_worker_script" "worker" {
  account_id = var.account_id
  name       = var.name
  content    = file(var.script_path)
  
  # Compatibility settings
  compatibility_date  = var.compatibility_date
  compatibility_flags = var.compatibility_flags
  
  # Environment variables
  dynamic "plain_text_binding" {
    for_each = var.environment_vars
    content {
      name = plain_text_binding.key
      text = plain_text_binding.value
    }
  }
  
  # Durable Object bindings
  dynamic "durable_object_namespace_binding" {
    for_each = var.durable_object_namespaces
    content {
      name         = durable_object_namespace_binding.value.name
      namespace_id = durable_object_namespace_binding.value.namespace_id
      class_name   = durable_object_namespace_binding.value.class_name
    }
  }
  
  # Service bindings (for container)
  dynamic "service_binding" {
    for_each = var.service_bindings
    content {
      name        = service_binding.value.name
      service     = service_binding.value.service
      environment = lookup(service_binding.value, "environment", "production")
    }
  }
}

# Worker subdomain (workers.dev)
resource "cloudflare_worker_domain" "worker_domain" {
  count = var.workers_dev_enabled ? 1 : 0
  
  account_id  = var.account_id
  hostname    = "${var.name}.workers.dev"
  service     = cloudflare_worker_script.worker.name
  environment = var.environment
}

# Custom domain route (optional)
resource "cloudflare_worker_route" "custom_route" {
  count = var.custom_domain != "" ? 1 : 0
  
  zone_id     = var.zone_id
  pattern     = var.route_pattern
  script_name = cloudflare_worker_script.worker.name
}

