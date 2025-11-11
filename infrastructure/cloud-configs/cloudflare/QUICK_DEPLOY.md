# Cloudflare Containers 快速部署（5 分鐘）

> 最快速度部署後端服務到 Cloudflare

---

## ⚡ 超快速部署（TL;DR）

```bash
# 1. 進入目錄
cd infrastructure/cloud-configs/cloudflare

# 2. 安裝依賴（避免 EBUSY 錯誤）
pnpm install

# 3. 登入 Cloudflare
wrangler login

# 4. 部署（使用腳本）
./deploy.sh  # 或 .\deploy.ps1（Windows）
```

**就這樣！** 🎉

---

## 📋 5 分鐘部署步驟

### Step 1: 清理環境（30 秒）

```powershell
# Windows PowerShell
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
npm cache clean --force
Remove-Item -Recurse -Force balck-white -ErrorAction SilentlyContinue
```

```bash
# Linux/Mac
killall node 2>/dev/null || true
npm cache clean --force
rm -rf balck-white
```

### Step 2: 安裝 Wrangler（如未安裝）（1 分鐘）

```bash
npm install -g wrangler
wrangler --version
```

### Step 3: 登入 Cloudflare（30 秒）

```bash
wrangler login
# 會開啟瀏覽器，點擊 "Allow" 授權
```

### Step 4: 安裝專案依賴（1 分鐘）

```bash
cd infrastructure/cloud-configs/cloudflare
pnpm install  # 使用 pnpm 避免 Windows 鎖定問題
```

### Step 5: 執行部署（2-3 分鐘）

**Windows PowerShell**：
```powershell
.\deploy.ps1
```

**Linux/Mac Bash**：
```bash
chmod +x deploy.sh
./deploy.sh
```

**或手動執行**：
```bash
# 推送容器映像
npm run push-all

# 設定 Secrets（互動式）
wrangler secret put DB_PASSWORD
wrangler secret put JWT_SECRET  
wrangler secret put HEXSTRIKE_API_KEYS

# 部署
wrangler deploy
```

### Step 6: 驗證部署（30 秒）

```bash
# 取得 Worker URL
wrangler deployments list

# 測試健康檢查
curl https://your-worker.your-subdomain.workers.dev/health

# 應該返回
{
  "status": "ok",
  "service": "unified-security-platform",
  "platform": "cloudflare-containers"
}
```

---

## 🎯 完成！

總時間：**約 5-7 分鐘**

您的服務現在運行在：
- 🌍 **全球 330+ 個城市**的 Cloudflare 邊緣網路
- 🚀 **自動擴展**：根據流量自動增減實例
- 💰 **按需付費**：無流量時自動休眠

---

## 🔧 遇到問題？

### npm EBUSY 錯誤

**快速修復**：
```powershell
# 關閉干擾程序
Get-Process node | Stop-Process -Force
Get-Process code | Stop-Process -Force

# 使用 pnpm
npm install -g pnpm
pnpm install
```

**詳細解決方案**：參見 [FIX_NPM_EBUSY.md](FIX_NPM_EBUSY.md)

### Wrangler 錯誤

**常見問題**：

1. **未登入**：執行 `wrangler login`
2. **未付費**：升級到 Workers Paid Plan
3. **權限不足**：檢查 Cloudflare 帳號權限
4. **映像太大**：優化 Dockerfile

### 部署失敗

```bash
# 查看即時日誌
wrangler tail --format=pretty

# 查看部署歷史
wrangler deployments list

# 重新部署
wrangler deploy --force
```

---

## 📊 部署後

### 監控

訪問 Cloudflare Dashboard：
https://dash.cloudflare.com/

**可查看**：
- 請求統計
- 錯誤率
- CPU/Memory 使用
- 成本統計

### 日誌

```bash
# 即時日誌
wrangler tail

# 過濾錯誤
wrangler tail --format=pretty | grep ERROR
```

### 測試

```bash
# 設定 Worker URL
export WORKER_URL="https://your-worker.your-subdomain.workers.dev"

# 測試各服務
curl $WORKER_URL/api/v1/scans                     # Go Backend
curl $WORKER_URL/api/ai/models/status             # AI/Quantum
curl -H "X-API-Key: key" $WORKER_URL/api/tools/nmap  # HexStrike
```

---

## 💡 優化建議

### 冷啟動優化

1. **減少映像大小**：
   ```dockerfile
   # 使用 alpine base
   FROM alpine:3.19
   
   # 清理不必要文件
   RUN rm -rf /tmp/* /var/cache/*
   ```

2. **快速啟動**：
   - 延遲載入非關鍵模組
   - 使用輕量級依賴

3. **保持溫暖**：
   ```bash
   # 定期發送請求保持實例活躍
   */5 * * * * curl $WORKER_URL/health
   ```

### 成本優化

```javascript
// 在 wrangler.toml 設定
sleepAfter = "10m"  // 10 分鐘無請求後休眠
max_instances = 5    // 限制最大實例數
```

---

## 🌟 優勢總結

| 特性 | Cloudflare Containers | 傳統 VPS |
|-----|----------------------|----------|
| **全球分佈** | ✅ 330+ 城市 | ❌ 單一區域 |
| **自動擴展** | ✅ 0-N 實例 | ❌ 固定資源 |
| **冷啟動** | ~5-8 秒 | N/A |
| **按需付費** | ✅ 用多少付多少 | ❌ 固定月費 |
| **維護** | ✅ 全託管 | ❌ 需自行維護 |
| **SSL** | ✅ 自動 | ⚠️ 需配置 |
| **DDoS 防護** | ✅ 內建 | ⚠️ 需額外購買 |
| **起始成本** | $5/月 | $10-40/月 |

**適合**：中小型應用、全球用戶、流量不穩定

**不適合**：長時間運行任務、大量本地儲存

---

## 🎉 恭喜！

您已成功將統一安全平台部署到 Cloudflare Containers！

**下一步**：
1. 🧪 執行安全測試
2. 📊 設定監控告警  
3. 🌐 綁定自訂域名（可選）
4. 📈 監控成本與性能

**需要幫助**？查看 [README.md](README.md) 或加入 [Cloudflare Discord](https://discord.gg/cloudflaredev)




