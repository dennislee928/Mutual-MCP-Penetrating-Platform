# Cloudflare Containers 部署腳本（PowerShell）
# 統一安全平台 - 後端服務部署

Write-Host "🚀 統一安全平台 - Cloudflare Containers 部署" -ForegroundColor Cyan
Write-Host "=" * 60

# 檢查前置需求
Write-Host "`n📋 檢查前置需求..." -ForegroundColor Yellow

# 檢查 Wrangler
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 未安裝 Wrangler CLI" -ForegroundColor Red
    Write-Host "   執行: npm install -g wrangler" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Wrangler CLI 已安裝" -ForegroundColor Green

# 檢查 Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 未安裝 Docker" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker 已安裝" -ForegroundColor Green

# 檢查登入狀態
Write-Host "`n🔐 檢查 Cloudflare 登入狀態..." -ForegroundColor Yellow
$loginCheck = wrangler whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 未登入 Cloudflare" -ForegroundColor Red
    Write-Host "   執行: wrangler login" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ 已登入 Cloudflare" -ForegroundColor Green

# 詢問要部署哪些服務
Write-Host "`n📦 選擇要部署的服務：" -ForegroundColor Cyan
Write-Host "1. Go Backend（防禦面 API）"
Write-Host "2. AI/Quantum（AI 威脅偵測）"
Write-Host "3. HexStrike AI（攻擊面）"
Write-Host "4. 全部服務"
Write-Host ""

$choice = Read-Host "請輸入選項 (1-4)"

# 設定要部署的服務
$deployBackend = $false
$deployAI = $false
$deployHexStrike = $false

switch ($choice) {
    "1" { $deployBackend = $true }
    "2" { $deployAI = $true }
    "3" { $deployHexStrike = $true }
    "4" { 
        $deployBackend = $true
        $deployAI = $true
        $deployHexStrike = $true
    }
    default {
        Write-Host "❌ 無效選項" -ForegroundColor Red
        exit 1
    }
}

# 安裝依賴
Write-Host "`n📦 安裝 npm 依賴..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm install 失敗" -ForegroundColor Red
    Write-Host "   嘗試：" -ForegroundColor Yellow
    Write-Host "   1. 關閉所有 IDE" -ForegroundColor Yellow
    Write-Host "   2. 暫停防毒軟件" -ForegroundColor Yellow
    Write-Host "   3. 使用管理員權限執行" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ 依賴安裝完成" -ForegroundColor Green

# 建置並推送容器映像
if ($deployBackend) {
    Write-Host "`n🏗️  建置 Go Backend 容器映像..." -ForegroundColor Cyan
    Set-Location -Path "..\..\..\src\backend"
    docker build -t unified-backend:latest .
    if ($LASTEXITCODE -eq 0) {
        Set-Location -Path "..\..\infrastructure\cloud-configs\cloudflare"
        wrangler containers push backend ../../../src/backend/Dockerfile
        Write-Host "✅ Go Backend 映像已推送" -ForegroundColor Green
    } else {
        Write-Host "❌ Go Backend 建置失敗" -ForegroundColor Red
    }
}

if ($deployAI) {
    Write-Host "`n🤖 建置 AI/Quantum 容器映像..." -ForegroundColor Cyan
    Set-Location -Path "..\..\..\src\ai-quantum"
    docker build -t unified-ai-quantum:latest .
    if ($LASTEXITCODE -eq 0) {
        Set-Location -Path "..\..\infrastructure\cloud-configs\cloudflare"
        wrangler containers push ai-quantum ../../../src/ai-quantum/Dockerfile
        Write-Host "✅ AI/Quantum 映像已推送" -ForegroundColor Green
    } else {
        Write-Host "❌ AI/Quantum 建置失敗" -ForegroundColor Red
    }
}

if ($deployHexStrike) {
    Write-Host "`n🔴 建置 HexStrike AI 容器映像..." -ForegroundColor Cyan
    Set-Location -Path "..\..\..\src\hexstrike-ai"
    docker build -t unified-hexstrike:latest .
    if ($LASTEXITCODE -eq 0) {
        Set-Location -Path "..\..\infrastructure\cloud-configs\cloudflare"
        wrangler containers push hexstrike ../../../src/hexstrike-ai/Dockerfile
        Write-Host "✅ HexStrike AI 映像已推送" -ForegroundColor Green
    } else {
        Write-Host "❌ HexStrike AI 建置失敗" -ForegroundColor Red
    }
}

# 設定 Secrets
Write-Host "`n🔐 設定環境變數 Secrets..." -ForegroundColor Yellow
Write-Host "請依提示輸入敏感資料（會加密儲存）`n"

$secrets = @("DB_PASSWORD", "JWT_SECRET", "HEXSTRIKE_API_KEYS")

foreach ($secret in $secrets) {
    Write-Host "設定 $secret ..." -ForegroundColor Cyan
    # wrangler secret put $secret
    # 註：需要互動式輸入，暫時跳過
}

Write-Host "`n⚠️  請手動設定 Secrets：" -ForegroundColor Yellow
Write-Host "   wrangler secret put DB_PASSWORD" -ForegroundColor White
Write-Host "   wrangler secret put JWT_SECRET" -ForegroundColor White
Write-Host "   wrangler secret put HEXSTRIKE_API_KEYS" -ForegroundColor White

# 部署
Write-Host "`n🚀 部署到 Cloudflare..." -ForegroundColor Cyan
wrangler deploy

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n🎉 部署成功！" -ForegroundColor Green
    Write-Host "`n訪問您的服務：" -ForegroundColor Cyan
    $deployments = wrangler deployments list --json | ConvertFrom-Json
    if ($deployments) {
        Write-Host "   Worker URL: $($deployments[0].url)" -ForegroundColor White
    }
    Write-Host "`n測試健康檢查：" -ForegroundColor Cyan
    Write-Host "   curl https://your-worker.your-subdomain.workers.dev/health" -ForegroundColor White
} else {
    Write-Host "`n❌ 部署失敗" -ForegroundColor Red
    Write-Host "   檢查錯誤訊息並參考 README.md" -ForegroundColor Yellow
}

Write-Host "`n" + ("=" * 60)

