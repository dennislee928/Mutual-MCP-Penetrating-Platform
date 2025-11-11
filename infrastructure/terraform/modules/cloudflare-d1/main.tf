# Cloudflare D1 Database Module

resource "cloudflare_d1_database" "security_platform" {
  account_id = var.account_id
  name       = var.database_name
}

# 使用 null_resource 執行 SQL schema 初始化
resource "null_resource" "init_schema" {
  depends_on = [cloudflare_d1_database.security_platform]
  
  triggers = {
    database_id = cloudflare_d1_database.security_platform.id
    schema_hash = filemd5(var.schema_file_path)
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      wrangler d1 execute ${cloudflare_d1_database.security_platform.name} \
        --file=${var.schema_file_path} \
        --remote
    EOT
    
    environment = {
      CLOUDFLARE_ACCOUNT_ID = var.account_id
      CLOUDFLARE_API_TOKEN  = var.api_token
    }
  }
}

# 輸出 D1 binding 配置供 wrangler.toml 使用
locals {
  d1_binding = {
    binding     = var.binding_name
    database_id = cloudflare_d1_database.security_platform.id
    database_name = cloudflare_d1_database.security_platform.name
  }
}

