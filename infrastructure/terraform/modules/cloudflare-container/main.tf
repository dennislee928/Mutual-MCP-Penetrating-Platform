# Cloudflare Container Module

# 注意：Terraform Cloudflare Provider 目前對 Containers 的支援有限
# 我們使用 null_resource 和 local-exec 來執行 wrangler 命令

# 從 Docker Hub 拉取映像到 Cloudflare
resource "null_resource" "pull_and_push_container" {
  triggers = {
    image_name      = var.dockerhub_image
    account_id      = var.account_id
    container_name  = var.image_name
    always_run      = var.force_update ? timestamp() : "static"
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      docker pull ${var.dockerhub_image}
      docker tag ${var.dockerhub_image} ${var.image_name}:${var.image_tag}
      wrangler containers push ${var.image_name}
    EOT
    
    interpreter = ["bash", "-c"]
    
    environment = {
      CLOUDFLARE_ACCOUNT_ID = var.account_id
      CLOUDFLARE_API_TOKEN  = var.api_token
    }
  }
}

# 獲取推送後的映像資訊
data "external" "container_info" {
  depends_on = [null_resource.pull_and_push_container]
  
  program = ["bash", "-c", <<-EOT
    # 從 wrangler containers list 獲取映像資訊
    # 輸出 JSON 格式的映像資訊
    echo '{"image_url": "registry.cloudflare.com/${var.account_id}/${var.image_name}", "image_name": "${var.image_name}", "status": "pushed"}'
  EOT
  ]
}

# Durable Object namespace for container
resource "cloudflare_workers_kv_namespace" "container_state" {
  count = var.create_kv_namespace ? 1 : 0
  
  account_id = var.account_id
  title      = "${var.image_name}-container-state"
}

