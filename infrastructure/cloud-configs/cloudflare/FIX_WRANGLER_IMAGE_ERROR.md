# 修復 Wrangler 映像路徑錯誤

## ❌ 錯誤訊息

```
[ERROR] Processing wrangler.toml configuration:
- The image "../../src/backend/Dockerfile" does not appear to be a valid path to a Dockerfile
```

---

## ✅ 解決方案

### 問題原因

Wrangler `image` 欄位需要：
- **目錄路徑**（包含 Dockerfile）
- **或** registry 路徑（例如 `docker.io/image:tag`）

**錯誤**：指向 Dockerfile 文件本身  
**正確**：指向包含 Dockerfile 的目錄

### 已修復

```toml
# ❌ 錯誤（指向文件）
[[containers]]
class_name = "GoBackend"
image = "../../src/backend/Dockerfile"

# ✅ 正確（指向目錄）
[[containers]]
class_name = "GoBackend"
image = "../../src/backend"
```

**所有三個容器配置已修復**：
- ✅ GoBackend: `../../src/backend`
- ✅ AIQuantum: `../../src/ai-quantum`
- ✅ HexStrikeAI: `../../src/hexstrike-ai`

---

## 🔄 現在可以部署了

### 驗證配置

```bash
cd infrastructure/cloud-configs/cloudflare

# 驗證配置（不會真正部署）
wrangler deploy --dry-run
```

### 推送映像

```bash
# 使用 npm scripts（推薦）
npm run push-all

# 或分別推送
npm run push-backend
npm run push-ai
npm run push-hexstrike
```

### 部署

```bash
# 方式 1：使用腳本
.\deploy.ps1  # Windows
./deploy.sh   # Linux/Mac

# 方式 2：直接部署
wrangler deploy
```

---

## 🎯 完整的正確流程

```bash
# 1. 確認在正確目錄
cd D:\GitHub\MCP---AGENTIC-\infrastructure\cloud-configs\cloudflare

# 2. 確認依賴已安裝
pnpm list
# 應該看到 @cloudflare/containers@0.0.30

# 3. 登入 Cloudflare
wrangler login

# 4. 驗證配置
wrangler deploy --dry-run
# 應該沒有錯誤

# 5. 推送映像（第一次部署需要）
npm run push-all

# 6. 設定 Secrets
wrangler secret put DB_PASSWORD
wrangler secret put JWT_SECRET
wrangler secret put HEXSTRIKE_API_KEYS

# 7. 部署
wrangler deploy

# 8. 驗證
wrangler deployments list
curl https://your-worker.workers.dev/health
```

---

## 📝 其他路徑相關錯誤

### 問題：相對路徑不work

**解決**：使用絕對路徑或相對於 wrangler.toml 的路徑

```toml
# ✅ 相對路徑（相對於 wrangler.toml）
image = "../../src/backend"

# ✅ 或使用 registry
image = "docker.io/username/unified-backend:latest"
```

### 問題：Dockerfile 不在預期位置

**解決**：確保 Dockerfile 存在於指定目錄

```bash
# 驗證文件存在
ls ../../src/backend/Dockerfile
ls ../../src/ai-quantum/Dockerfile
ls ../../src/hexstrike-ai/Dockerfile
```

---

## 🎉 修復完成

配置已修復！現在可以：

✅ **驗證配置**：`wrangler deploy --dry-run`  
✅ **推送映像**：`npm run push-all`  
✅ **部署服務**：`wrangler deploy`

**下一步**：執行部署！ 🚀


