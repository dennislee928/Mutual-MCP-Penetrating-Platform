# 🔴 HexStrike AI - Docker Hub 部署指南

由於 HexStrike AI 的 Dockerfile 非常複雜（基於 Kali Linux，包含大量安全工具），直接在 Cloudflare 上建置會失敗或超時。因此，我們採用**預建映像**策略。

## 📋 部署流程

```
本地建置 → 推送到 Docker Hub → Cloudflare 引用外部映像
```

---

## 🚀 步驟 1：建置並推送映像到 Docker Hub

### 前置需求

1. **Docker Hub 帳號**
   - 註冊：https://hub.docker.com/signup
   - 記住您的用戶名

2. **Docker Desktop 運行中**
   - 確認：`docker ps`

3. **足夠的磁碟空間**
   - HexStrike 映像約 5-10 GB

### 執行建置腳本

```bash
cd /d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare

# 執行建置腳本
./build-and-push-hexstrike.sh
```

### 腳本會：

1. ✅ 檢查 Docker 環境
2. 🔐 提示您登入 Docker Hub
3. 🏗️ 建置 HexStrike 映像（**30-60 分鐘**）
4. 📤 推送到 Docker Hub（**5-10 分鐘**）
5. 📊 顯示映像資訊

### 預期輸出

```
🔴 HexStrike AI - 建置並推送到 Docker Hub
============================================================
✅ Docker 已安裝
✅ Docker daemon 運行中

📝 Docker Hub 配置
請輸入您的 Docker Hub 用戶名: your-username

🔐 登入 Docker Hub...
✅ 登入成功

🏗️  建置 HexStrike AI 映像...
[... 建置過程 30-60 分鐘 ...]
✅ 映像建置成功

📤 推送映像到 Docker Hub...
✅ 映像推送成功

╔════════════════════════════════════════╗
║   🎉 建置並推送成功！                 ║
╚════════════════════════════════════════╝

📊 映像資訊：
   Docker Hub: https://hub.docker.com/r/your-username/hexstrike-ai
   映像名稱: your-username/hexstrike-ai:latest
   大小: 8.5 GB
```

---

## 🔧 步驟 2：配置 Cloudflare Worker

### 更新 wrangler 配置

編輯 `wrangler-hexstrike-dockerhub.toml`：

```toml
[[containers]]
class_name = "HexStrikeContainer"
# 將下面這行改為您的 Docker Hub 映像
image = "your-dockerhub-username/hexstrike-ai:latest"
max_instances = 2
```

**實際範例**：
```toml
image = "pcleegood/hexstrike-ai:latest"
```

---

## 🚀 步驟 3：部署到 Cloudflare

### 選項 A：使用部署腳本（推薦）

```bash
cd /d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare

# 部署 HexStrike（使用 Docker Hub 映像）
wrangler deploy --config wrangler-hexstrike-dockerhub.toml
```

### 選項 B：手動部署

```bash
# 確認配置
wrangler deploy --config wrangler-hexstrike-dockerhub.toml --dry-run

# 執行部署
wrangler deploy --config wrangler-hexstrike-dockerhub.toml
```

### 預期輸出

```
⛅️ wrangler 4.46.0
───────────────────
Total Upload: 56.37 KiB / gzip: 13.96 KiB
Worker Startup Time: 12 ms

Uploaded unified-hexstrike (10.89 sec)
Pulling image from Docker Hub: your-username/hexstrike-ai:latest
Image pulled successfully

╭ Deploy a container application
│ Container application changes
├ NEW unified-hexstrike-hexstrikecontainer
│   SUCCESS  Created application unified-hexstrike-hexstrikecontainer
╰ Applied changes

Deployed unified-hexstrike triggers (1.16 sec)
  https://unified-hexstrike.pcleegood.workers.dev

✅ HexStrike Worker 部署成功
```

---

## 🧪 步驟 4：測試部署

### 健康檢查

```bash
curl https://unified-hexstrike.pcleegood.workers.dev/health
```

預期響應：
```json
{
  "status": "ok",
  "service": "hexstrike-ai",
  "timestamp": "2025-11-10T10:00:00.000Z"
}
```

### 查看容器狀態

```bash
# 查看部署狀態
wrangler deployments list --name unified-hexstrike

# 實時日誌
wrangler tail unified-hexstrike
```

---

## 🔐 Docker Hub 映像設定

### 公開 vs 私有映像

#### 如果映像是公開的
- Cloudflare 可以直接拉取
- 無需額外配置
- **推薦**用於測試

#### 如果映像是私有的
1. 需要在 Cloudflare 配置 Docker Hub 憑證
2. 參考：https://developers.cloudflare.com/workers/configuration/private-registries/

### 設定映像為公開

1. 登入 https://hub.docker.com
2. 進入您的映像倉庫
3. 點擊 **Settings**
4. 選擇 **Make Public**

---

## 📊 完整部署狀態

部署完成後，您將擁有：

```
✅ Backend Worker         → https://unified-backend.pcleegood.workers.dev
✅ AI/Quantum Worker      → https://unified-ai-quantum.pcleegood.workers.dev
✅ HexStrike Worker       → https://unified-hexstrike.pcleegood.workers.dev
```

在 Cloudflare Dashboard 的 **Containers** 頁面，您將看到：

```
┌─────────────────────────────────┬────────┬──────────────┐
│ Name                            │ Status │ Instances    │
├─────────────────────────────────┼────────┼──────────────┤
│ unified-backend-backendcontainer│ Ready  │ 0-5          │
│ unified-ai-quantum-aicontainer  │ Ready  │ 0-3          │
│ unified-hexstrike-hexstrikecontainer│ Ready  │ 0-2      │
└─────────────────────────────────┴────────┴──────────────┘
```

---

## 🔍 故障排除

### 問題：建置時間過長

**解決方案**：
- 這是正常的！HexStrike 包含大量工具
- 預計 30-60 分鐘
- 確保網路穩定
- 可以在後台運行

### 問題：推送到 Docker Hub 失敗

**可能原因**：
1. 未登入或憑證過期
2. 網路連線問題
3. Docker Hub 配額限制

**解決方案**：
```bash
# 重新登入
docker login

# 手動推送
docker push your-username/hexstrike-ai:latest

# 檢查映像
docker images | grep hexstrike
```

### 問題：Cloudflare 無法拉取映像

**檢查清單**：
1. ✅ 映像是否已推送到 Docker Hub？
2. ✅ 映像名稱是否正確？（包含用戶名）
3. ✅ 映像是公開的嗎？（或已配置私有憑證）
4. ✅ 標籤是否正確？（通常是 `latest`）

**驗證**：
```bash
# 在本地測試拉取
docker pull your-username/hexstrike-ai:latest

# 在瀏覽器訪問
# https://hub.docker.com/r/your-username/hexstrike-ai
```

### 問題：容器啟動失敗

**查看日誌**：
```bash
wrangler tail unified-hexstrike
```

**常見原因**：
- 端口配置錯誤（應為 8888）
- 環境變數缺失
- 容器內應用未啟動

---

## 💡 優化建議

### 1. 減小映像大小

編輯 `src/hexstrike-ai/Dockerfile`，移除不必要的工具：

```dockerfile
# 只保留核心工具
RUN /usr/local/bin/apt-retry install -y \
    python3 \
    python3-pip \
    nmap \
    curl \
    wget
```

### 2. 使用多階段構建

```dockerfile
FROM kalilinux/kali-rolling AS builder
# 安裝和構建...

FROM kalilinux/kali-rolling AS final
# 只複製必要的檔案
COPY --from=builder /app /app
```

### 3. 快取層級

將不常變動的安裝放在前面：

```dockerfile
# 系統工具（很少變動）
RUN apt-get update && apt-get install -y base-tools

# Python 依賴（偶爾變動）
COPY requirements.txt .
RUN pip install -r requirements.txt

# 應用代碼（經常變動）
COPY . .
```

---

## 📚 相關資源

- [Cloudflare Containers 文檔](https://developers.cloudflare.com/workers/runtime-apis/bindings/containers/)
- [Docker Hub 快速入門](https://docs.docker.com/docker-hub/)
- [優化 Docker 映像大小](https://docs.docker.com/develop/dev-best-practices/)

---

## ✅ 完成檢查清單

- [ ] 註冊 Docker Hub 帳號
- [ ] 執行 `build-and-push-hexstrike.sh`
- [ ] 映像成功推送到 Docker Hub
- [ ] 設定映像為公開（可選）
- [ ] 更新 `wrangler-hexstrike-dockerhub.toml` 中的映像名稱
- [ ] 執行 `wrangler deploy --config wrangler-hexstrike-dockerhub.toml`
- [ ] 測試健康檢查端點
- [ ] 在 Cloudflare Dashboard 確認容器運行

---

## 🎉 成功！

完成後，您將擁有三個完整部署的容器化服務，全部運行在 Cloudflare 的全球網路上！

