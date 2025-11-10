# 🚀 快速開始：HexStrike AI Docker Hub 部署

## ⏱️ 時間預估
- **建置時間**: 30-60 分鐘
- **推送時間**: 5-10 分鐘  
- **部署時間**: 2-3 分鐘
- **總計**: 約 45-75 分鐘

---

## 📋 三步驟部署

### 步驟 1：建置並推送到 Docker Hub（45-70 分鐘）

```bash
cd /d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare

# 執行建置腳本
./build-and-push-hexstrike.sh
```

**執行時會提示**：
1. 輸入 Docker Hub 用戶名
2. 輸入 Docker Hub 密碼
3. 等待建置完成（可以去喝杯咖啡 ☕）

---

### 步驟 2：更新配置（1 分鐘）

編輯 `wrangler-hexstrike-dockerhub.toml`：

```toml
# 找到這一行
image = "YOUR_DOCKERHUB_USERNAME/hexstrike-ai:latest"

# 改為您的用戶名
image = "pcleegood/hexstrike-ai:latest"  # 範例
```

---

### 步驟 3：部署到 Cloudflare（2-3 分鐘）

```bash
# 部署
wrangler deploy --config wrangler-hexstrike-dockerhub.toml
```

---

## ✅ 測試

```bash
# 健康檢查
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

---

## 🎯 一行命令（如果已有映像）

如果您已經有 Docker Hub 映像：

```bash
# 1. 更新配置中的映像名稱
# 2. 執行部署
wrangler deploy --config wrangler-hexstrike-dockerhub.toml
```

---

## 📊 完整狀態

部署完成後：

```
✅ Backend:    https://unified-backend.pcleegood.workers.dev
✅ AI/Quantum: https://unified-ai-quantum.pcleegood.workers.dev  
✅ HexStrike:  https://unified-hexstrike.pcleegood.workers.dev
```

---

## 🔗 詳細文檔

完整指南請參考：[HEXSTRIKE_DOCKERHUB_GUIDE.md](./HEXSTRIKE_DOCKERHUB_GUIDE.md)

---

## ❓ 需要幫助？

常見問題：
- 建置時間過長？→ 正常，需要 30-60 分鐘
- 推送失敗？→ 檢查 Docker Hub 登入狀態
- 部署失敗？→ 確認映像名稱和公開設定

完整故障排除請參考詳細指南。

