# 修復 npm EBUSY 錯誤

## 問題

```
npm error EBUSY: resource busy or locked
```

這是 Windows 特有的文件鎖定問題。

---

## 🔧 解決方案（按順序嘗試）

### 方案 1：關閉干擾程序（最有效）

```powershell
# 1. 關閉所有 VSCode/Cursor 視窗
# 2. 關閉檔案總管中的專案目錄
# 3. 結束相關 Node 進程

# 查看 Node 進程
Get-Process node

# 結束所有 Node 進程
Get-Process node | Stop-Process -Force

# 重新安裝
cd infrastructure\cloud-configs\cloudflare
npm install
```

### 方案 2：暫時關閉防毒

```powershell
# Windows Defender 即時保護
# 1. 開啟 Windows 安全性
# 2. 病毒與威脅防護 > 管理設定
# 3. 暫時關閉「即時保護」
# 4. 執行 npm install
# 5. 重新開啟保護

cd infrastructure\cloud-configs\cloudflare
npm install
```

### 方案 3：清除快取重試

```powershell
# 清除 npm 快取
npm cache clean --force

# 刪除 node_modules
Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue

# 重新安裝
npm install
```

### 方案 4：使用管理員權限

```powershell
# 1. 以「系統管理員身分執行」開啟 PowerShell
# 2. 進入目錄
cd D:\GitHub\MCP---AGENTIC-\infrastructure\cloud-configs\cloudflare

# 3. 安裝
npm install --force
```

### 方案 5：使用 pnpm 或 yarn

```powershell
# 安裝 pnpm
npm install -g pnpm

# 使用 pnpm 安裝
cd infrastructure\cloud-configs\cloudflare
pnpm install
```

或使用 yarn：

```powershell
# 安裝 yarn
npm install -g yarn

# 使用 yarn 安裝
cd infrastructure\cloud-configs\cloudflare
yarn install
```

### 方案 6：排除目錄（永久解決）

將 `node_modules` 加入防毒軟件排除清單：

**Windows Defender**：
1. 開啟 Windows 安全性
2. 病毒與威脅防護 > 管理設定
3. 排除項目 > 新增或移除排除項目
4. 新增資料夾：`D:\GitHub\MCP---AGENTIC-\node_modules`

---

## 🚀 完整流程（避免錯誤）

### 推薦流程

```powershell
# 1. 關閉所有 IDE 和檔案總管
# 2. 清除舊資料
cd D:\GitHub\MCP---AGENTIC-
Remove-Item -Recurse -Force balck-white -ErrorAction SilentlyContinue

# 3. 進入正確目錄
cd infrastructure\cloud-configs\cloudflare

# 4. 使用 pnpm（較少文件鎖定問題）
npm install -g pnpm
pnpm install

# 5. 驗證安裝
pnpm list

# 6. 測試 Wrangler
wrangler --version
```

---

## 🎯 快速修復腳本

### PowerShell 一鍵修復

```powershell
# 建立並執行修復腳本
$fixScript = @"
Write-Host '🔧 修復 npm EBUSY 錯誤...' -ForegroundColor Cyan

# 1. 結束 Node 進程
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host '✅ Node 進程已清理' -ForegroundColor Green

# 2. 清除快取
npm cache clean --force
Write-Host '✅ npm 快取已清除' -ForegroundColor Green

# 3. 清除舊目錄
Remove-Item -Recurse -Force 'balck-white' -ErrorAction SilentlyContinue
Write-Host '✅ 舊目錄已清除' -ForegroundColor Green

# 4. 進入正確目錄
cd infrastructure\cloud-configs\cloudflare

# 5. 安裝依賴
Write-Host '📦 安裝依賴（使用 pnpm）...' -ForegroundColor Yellow
pnpm install

if ($LASTEXITCODE -eq 0) {
    Write-Host '🎉 修復完成！' -ForegroundColor Green
} else {
    Write-Host '⚠️  pnpm 失敗，嘗試 npm...' -ForegroundColor Yellow
    npm install --force
}
"@

Invoke-Expression $fixScript
```

### Bash 一鍵修復

```bash
#!/bin/bash
echo "🔧 修復 npm EBUSY 錯誤..."

# 清除快取
npm cache clean --force
echo "✅ npm 快取已清除"

# 清除舊目錄
rm -rf balck-white
echo "✅ 舊目錄已清除"

# 進入正確目錄
cd infrastructure/cloud-configs/cloudflare

# 安裝依賴
echo "📦 安裝依賴..."
npm install

echo "🎉 修復完成！"
```

---

## 🔍 進階診斷

### 找出鎖定文件的進程

```powershell
# 安裝 Handle 工具（SysInternals）
# https://learn.microsoft.com/en-us/sysinternals/downloads/handle

# 使用 Handle 查找
handle.exe ufo

# 或使用 Resource Monitor
# 開啟 Resource Monitor > CPU > 關聯的模組 > 搜尋 "ufo"
```

### 檢查權限

```powershell
# 檢查目錄權限
Get-Acl "D:\GitHub\MCP---AGENTIC-" | Format-List

# 取得完整控制權
$acl = Get-Acl "D:\GitHub\MCP---AGENTIC-"
$permission = "Everyone","FullControl","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "D:\GitHub\MCP---AGENTIC-" $acl
```

---

## ✅ 驗證修復

```powershell
# 測試安裝
cd infrastructure\cloud-configs\cloudflare
npm install

# 應該看到
# ✅ 無錯誤訊息
# ✅ node_modules 目錄建立成功
# ✅ package-lock.json 生成

# 驗證 Wrangler
wrangler --version
# 應該顯示版本號（例如：3.78.0）
```

---

## 🆘 仍然失敗？

### 最後手段

```powershell
# 1. 重啟電腦（清除所有文件鎖定）
# 2. 使用 WSL2（Linux 環境，無 EBUSY 問題）

# 在 WSL2 中
cd /mnt/d/GitHub/MCP---AGENTIC-/infrastructure/cloud-configs/cloudflare
npm install
```

### 或使用 Docker 安裝

```powershell
# 在 Docker 容器中安裝依賴
docker run --rm -v ${PWD}:/app -w /app node:18-alpine npm install
```

---

## 📞 需要幫助？

如果以上方案都無效：

1. 提供完整錯誤日誌：
   ```powershell
   npm install > npm-debug.log 2>&1
   ```

2. 檢查系統資訊：
   ```powershell
   systeminfo
   npm --version
   node --version
   ```

3. 提交 Issue 或尋求社群支援

---

**通常方案 1 或方案 5 就能解決！** 💪


