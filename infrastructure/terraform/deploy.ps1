# PowerShell Deployment Script for Terraform
# Windows 用戶的便捷部署腳本

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('init', 'plan', 'apply', 'destroy', 'output', 'health-check', 'help')]
    [string]$Action = 'apply',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment = 'production',
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove = $false
)

# 顏色輸出函數
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" 'Green'
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" 'Cyan'
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" 'Yellow'
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" 'Red'
}

function Show-Help {
    Write-ColorOutput "🚀 Terraform 部署腳本" 'Cyan'
    Write-Host ""
    Write-Host "使用方式:"
    Write-ColorOutput "  .\deploy.ps1 [-Action <action>] [-Environment <env>] [-AutoApprove]" 'Yellow'
    Write-Host ""
    Write-Host "參數:"
    Write-Host "  -Action        : 執行的動作 (init, plan, apply, destroy, output, health-check, help)"
    Write-Host "  -Environment   : 環境 (dev, staging, production)"
    Write-Host "  -AutoApprove   : 自動批准（不提示確認）"
    Write-Host ""
    Write-Host "範例:"
    Write-ColorOutput "  .\deploy.ps1                                    # 部署到 production" 'Cyan'
    Write-ColorOutput "  .\deploy.ps1 -Action plan                      # 查看執行計畫" 'Cyan'
    Write-ColorOutput "  .\deploy.ps1 -Action apply -Environment dev   # 部署到 dev 環境" 'Cyan'
    Write-ColorOutput "  .\deploy.ps1 -Action health-check             # 執行健康檢查" 'Cyan'
    Write-ColorOutput "  .\deploy.ps1 -Action destroy -AutoApprove     # 自動銷毀資源" 'Cyan'
}

# 檢查 Terraform 是否已安裝
function Test-Terraform {
    Write-Info "檢查 Terraform 安裝..."
    
    if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "未安裝 Terraform"
        Write-Host ""
        Write-Host "請安裝 Terraform:"
        Write-Host "  1. 使用 Chocolatey: choco install terraform"
        Write-Host "  2. 或從官網下載: https://www.terraform.io/downloads"
        exit 1
    }
    
    $version = (terraform version -json | ConvertFrom-Json).terraform_version
    Write-Success "Terraform 已安裝 (版本: $version)"
}

# 檢查配置檔案
function Test-Configuration {
    Write-Info "檢查配置檔案..."
    
    $tfvarsFile = "terraform.tfvars"
    $exampleFile = "terraform.tfvars.example"
    
    # 檢查環境特定配置
    if ($Environment -in @('dev', 'production')) {
        $envPath = "environments\$Environment"
        if (Test-Path $envPath) {
            Set-Location $envPath
            $tfvarsFile = "terraform.tfvars"
            $exampleFile = "terraform.tfvars.example"
        }
    }
    
    if (!(Test-Path $tfvarsFile)) {
        Write-Warning "找不到 $tfvarsFile"
        
        if (Test-Path $exampleFile) {
            Write-Info "發現範例檔案: $exampleFile"
            $copy = Read-Host "是否複製範例檔案？(Y/N)"
            
            if ($copy -eq 'Y' -or $copy -eq 'y') {
                Copy-Item $exampleFile $tfvarsFile
                Write-Success "已複製 $exampleFile 到 $tfvarsFile"
                Write-Warning "請編輯 $tfvarsFile 填入實際值，然後重新執行此腳本"
                
                # 開啟檔案編輯器
                Start-Process notepad $tfvarsFile
                exit 0
            }
        }
        
        Write-Error "需要 $tfvarsFile 檔案"
        Write-Host "請創建 $tfvarsFile 或從 $exampleFile 複製"
        exit 1
    }
    
    Write-Success "配置檔案存在"
}

# 執行 Terraform 命令
function Invoke-TerraformCommand {
    param(
        [string]$Command,
        [string[]]$Arguments = @()
    )
    
    Write-Info "執行: terraform $Command $($Arguments -join ' ')"
    
    & terraform $Command @Arguments
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "命令執行失敗 (退出代碼: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}

# 初始化
function Initialize-Terraform {
    Write-Info "初始化 Terraform..."
    Invoke-TerraformCommand 'init'
    Write-Success "初始化完成"
}

# 執行計畫
function Get-TerraformPlan {
    Write-Info "生成執行計畫..."
    Invoke-TerraformCommand 'plan'
}

# 部署
function Deploy-Infrastructure {
    Write-Info "部署基礎設施 (環境: $Environment)..."
    
    if ($AutoApprove) {
        Invoke-TerraformCommand 'apply' @('-auto-approve')
    } else {
        Invoke-TerraformCommand 'apply'
    }
    
    Write-Success "部署完成"
}

# 銷毀
function Remove-Infrastructure {
    Write-Warning "即將銷毀 $Environment 環境的所有資源"
    
    if (!$AutoApprove) {
        $confirm = Read-Host "確認要繼續嗎？(yes/no)"
        if ($confirm -ne 'yes') {
            Write-Info "已取消"
            exit 0
        }
    }
    
    Write-Info "銷毀資源..."
    
    if ($AutoApprove) {
        Invoke-TerraformCommand 'destroy' @('-auto-approve')
    } else {
        Invoke-TerraformCommand 'destroy'
    }
    
    Write-Success "資源已銷毀"
}

# 顯示輸出
function Show-Output {
    Write-Info "顯示 Terraform 輸出..."
    Invoke-TerraformCommand 'output'
}

# 健康檢查
function Test-Deployment {
    Write-Info "執行健康檢查..."
    
    # 獲取 Worker URL
    $workerUrl = (terraform output -raw hexstrike_worker_url 2>$null)
    
    if (!$workerUrl) {
        Write-Error "無法獲取 Worker URL"
        Write-Host "請確認部署已完成"
        exit 1
    }
    
    Write-Info "Worker URL: $workerUrl"
    Write-Info "測試 health check 端點..."
    
    try {
        $response = Invoke-RestMethod -Uri "$workerUrl/health" -Method Get -TimeoutSec 10
        
        if ($response.status -eq 'ok') {
            Write-Success "Health check 成功！"
            Write-Host ""
            Write-Host "回應:"
            $response | ConvertTo-Json | Write-Host
        } else {
            Write-Warning "Health check 回應異常"
            $response | ConvertTo-Json | Write-Host
        }
    } catch {
        Write-Error "Health check 失敗: $_"
        Write-Host ""
        Write-Host "請檢查："
        Write-Host "  1. Worker 是否已部署"
        Write-Host "  2. 容器是否已啟動（首次可能需要 30-60 秒）"
        Write-Host "  3. 查看 Worker 日誌: wrangler tail unified-hexstrike"
    }
}

# 主執行流程
function Main {
    # 顯示標題
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════" 'Cyan'
    Write-ColorOutput "  Terraform 部署腳本" 'Cyan'
    Write-ColorOutput "  環境: $Environment" 'Yellow'
    Write-ColorOutput "═══════════════════════════════════════" 'Cyan'
    Write-Host ""
    
    # 顯示幫助
    if ($Action -eq 'help') {
        Show-Help
        exit 0
    }
    
    # 檢查 Terraform
    Test-Terraform
    
    # 檢查配置
    if ($Action -ne 'help') {
        Test-Configuration
    }
    
    # 執行動作
    switch ($Action) {
        'init' {
            Initialize-Terraform
        }
        'plan' {
            Get-TerraformPlan
        }
        'apply' {
            Initialize-Terraform
            Deploy-Infrastructure
            Write-Host ""
            Show-Output
            Write-Host ""
            Write-Info "執行健康檢查..."
            Start-Sleep -Seconds 5
            Test-Deployment
        }
        'destroy' {
            Remove-Infrastructure
        }
        'output' {
            Show-Output
        }
        'health-check' {
            Test-Deployment
        }
    }
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════" 'Cyan'
    Write-Success "完成！"
    Write-ColorOutput "═══════════════════════════════════════" 'Cyan'
    Write-Host ""
}

# 執行主函數
Main

