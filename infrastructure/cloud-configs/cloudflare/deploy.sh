#!/bin/bash
# Cloudflare Containers 部署腳本（Bash）
# 統一安全平台 - 後端服務部署

set -e

echo "🚀 統一安全平台 - Cloudflare Containers 部署"
echo "============================================================"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 檢查前置需求
echo -e "\n${YELLOW}📋 檢查前置需求...${NC}"

# 檢查 Node.js 和 npm
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 未安裝 Node.js${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js 已安裝 ($(node --version))${NC}"

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ 未安裝 npm${NC}"
    exit 1
fi
NPM_VERSION=$(npm --version)
echo -e "${GREEN}✅ npm 已安裝 (v${NPM_VERSION})${NC}"

# 檢查 Wrangler
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ 未安裝 Wrangler CLI${NC}"
    echo -e "${YELLOW}   執行: npm install -g wrangler${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Wrangler CLI 已安裝${NC}"

# 檢查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 未安裝 Docker${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker 已安裝${NC}"

# 檢查 Docker daemon 是否運行
echo -e "${YELLOW}   檢查 Docker daemon...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon 未運行${NC}"
    echo -e "${YELLOW}   請啟動 Docker Desktop 並等待其完全啟動後重試${NC}"
    echo -e "${YELLOW}   在 Windows 上：${NC}"
    echo -e "${YELLOW}   1. 開啟 Docker Desktop${NC}"
    echo -e "${YELLOW}   2. 等待系統托盤圖示變為穩定狀態${NC}"
    echo -e "${YELLOW}   3. 確認可以執行: docker ps${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker daemon 運行中${NC}"

# 檢查登入狀態
echo -e "\n${YELLOW}🔐 檢查 Cloudflare 登入狀態...${NC}"
if ! wrangler whoami &> /dev/null; then
    echo -e "${RED}❌ 未登入 Cloudflare${NC}"
    echo -e "${YELLOW}   執行: wrangler login${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 已登入 Cloudflare${NC}"

# 詢問要部署哪些服務
echo -e "\n${CYAN}📦 選擇要部署的服務：${NC}"
echo "1. Go Backend（防禦面 API）"
echo "2. AI/Quantum（AI 威脅偵測）"
echo "3. HexStrike AI（攻擊面）"
echo "4. 全部服務"
echo ""

read -p "請輸入選項 (1-4): " choice

# 設定要部署的服務
DEPLOY_BACKEND=false
DEPLOY_AI=false
DEPLOY_HEXSTRIKE=false

case $choice in
    1) DEPLOY_BACKEND=true ;;
    2) DEPLOY_AI=true ;;
    3) DEPLOY_HEXSTRIKE=true ;;
    4) 
        DEPLOY_BACKEND=true
        DEPLOY_AI=true
        DEPLOY_HEXSTRIKE=true
        ;;
    *)
        echo -e "${RED}❌ 無效選項${NC}"
        exit 1
        ;;
esac

# 安裝依賴
echo -e "\n${YELLOW}📦 準備安裝 npm 依賴...${NC}"

# 清理快取以避免 Windows 下的快取錯誤
echo -e "${YELLOW}   清理 npm 快取...${NC}"
npm cache clean --force 2>/dev/null || true

# 檢查是否存在 node_modules
if [ -d "node_modules" ]; then
    echo -e "${YELLOW}   偵測到現有 node_modules，清理中...${NC}"
    rm -rf node_modules
fi

# 刪除舊的 package-lock.json 以避免版本衝突
if [ -f "package-lock.json" ]; then
    echo -e "${YELLOW}   移除舊的 package-lock.json...${NC}"
    rm -f package-lock.json
fi

# 安裝依賴
echo -e "${YELLOW}   執行 npm install...${NC}"
if npm install --loglevel=error; then
    echo -e "${GREEN}✅ 依賴安裝完成${NC}"
else
    echo -e "${RED}❌ npm install 失敗${NC}"
    echo -e "${YELLOW}   嘗試診斷：${NC}"
    echo -e "${YELLOW}   1. 請確認您的 npm 版本 >= 8.0${NC}"
    echo -e "${YELLOW}   2. 嘗試手動執行: npm install -g npm@latest${NC}"
    echo -e "${YELLOW}   3. 檢查網路連線是否正常${NC}"
    echo -e "${YELLOW}   4. 查看詳細錯誤日誌: ~/.npm/_logs/${NC}"
    exit 1
fi

# 儲存當前目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# 建置並推送容器映像
DEPLOY_SUCCESS=true

if [ "$DEPLOY_BACKEND" = true ]; then
    echo -e "\n${CYAN}🏗️  建置 Go Backend 容器映像...${NC}"
    BACKEND_DIR="${PROJECT_ROOT}/src/backend"
    
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${RED}❌ 找不到 Backend 目錄: $BACKEND_DIR${NC}"
        DEPLOY_SUCCESS=false
    else
        cd "$BACKEND_DIR"
        echo -e "${YELLOW}   當前目錄: $(pwd)${NC}"
        
        if docker build -t unified-backend:latest .; then
            cd "$SCRIPT_DIR"
            # Tag image for Cloudflare Container Registry
            docker tag unified-backend:latest backend:latest
            if wrangler containers push backend; then
                echo -e "${GREEN}✅ Go Backend 映像已推送${NC}"
            else
                echo -e "${RED}❌ Go Backend 推送失敗${NC}"
                DEPLOY_SUCCESS=false
            fi
        else
            echo -e "${RED}❌ Go Backend 建置失敗${NC}"
            DEPLOY_SUCCESS=false
        fi
        cd "$SCRIPT_DIR"
    fi
fi

if [ "$DEPLOY_AI" = true ]; then
    echo -e "\n${CYAN}🤖 建置 AI/Quantum 容器映像...${NC}"
    AI_DIR="${PROJECT_ROOT}/src/ai-quantum"
    
    if [ ! -d "$AI_DIR" ]; then
        echo -e "${RED}❌ 找不到 AI/Quantum 目錄: $AI_DIR${NC}"
        DEPLOY_SUCCESS=false
    else
        cd "$AI_DIR"
        echo -e "${YELLOW}   當前目錄: $(pwd)${NC}"
        
        if docker build -t unified-ai-quantum:latest .; then
            cd "$SCRIPT_DIR"
            # Tag image for Cloudflare Container Registry
            docker tag unified-ai-quantum:latest ai-quantum:latest
            if wrangler containers push ai-quantum; then
                echo -e "${GREEN}✅ AI/Quantum 映像已推送${NC}"
            else
                echo -e "${RED}❌ AI/Quantum 推送失敗${NC}"
                DEPLOY_SUCCESS=false
            fi
        else
            echo -e "${RED}❌ AI/Quantum 建置失敗${NC}"
            DEPLOY_SUCCESS=false
        fi
        cd "$SCRIPT_DIR"
    fi
fi

if [ "$DEPLOY_HEXSTRIKE" = true ]; then
    echo -e "\n${CYAN}🔴 建置 HexStrike AI 容器映像...${NC}"
    HEXSTRIKE_DIR="${PROJECT_ROOT}/src/hexstrike-ai"
    
    if [ ! -d "$HEXSTRIKE_DIR" ]; then
        echo -e "${RED}❌ 找不到 HexStrike AI 目錄: $HEXSTRIKE_DIR${NC}"
        DEPLOY_SUCCESS=false
    else
        cd "$HEXSTRIKE_DIR"
        echo -e "${YELLOW}   當前目錄: $(pwd)${NC}"
        
        if docker build -t unified-hexstrike:latest .; then
            cd "$SCRIPT_DIR"
            # Tag image for Cloudflare Container Registry
            docker tag unified-hexstrike:latest hexstrike:latest
            if wrangler containers push hexstrike; then
                echo -e "${GREEN}✅ HexStrike AI 映像已推送${NC}"
            else
                echo -e "${RED}❌ HexStrike AI 推送失敗${NC}"
                DEPLOY_SUCCESS=false
            fi
        else
            echo -e "${RED}❌ HexStrike AI 建置失敗${NC}"
            DEPLOY_SUCCESS=false
        fi
        cd "$SCRIPT_DIR"
    fi
fi

# 檢查是否有建置失敗
if [ "$DEPLOY_SUCCESS" = false ]; then
    echo -e "\n${RED}❌ 部分服務建置失敗，請檢查上方錯誤訊息${NC}"
    echo -e "${YELLOW}   提示：${NC}"
    echo -e "${YELLOW}   - 確認 Dockerfile 存在於各服務目錄${NC}"
    echo -e "${YELLOW}   - 檢查 Docker daemon 是否運行${NC}"
    echo -e "${YELLOW}   - 查看 Docker 建置日誌以取得詳細錯誤${NC}"
    exit 1
fi

# 提示設定 Secrets
echo -e "\n${YELLOW}🔐 請設定環境變數 Secrets：${NC}"
echo -e "${CYAN}   wrangler secret put DB_PASSWORD${NC}"
echo -e "${CYAN}   wrangler secret put JWT_SECRET${NC}"
echo -e "${CYAN}   wrangler secret put HEXSTRIKE_API_KEYS${NC}"
echo -e "${CYAN}   wrangler secret put IBM_QUANTUM_TOKEN${NC}"
echo ""
read -p "是否現在設定 Secrets？(y/n) " setup_secrets

if [ "$setup_secrets" = "y" ]; then
    cd "$SCRIPT_DIR"
    echo -e "${YELLOW}設定 DB_PASSWORD...${NC}"
    wrangler secret put DB_PASSWORD || echo -e "${RED}❌ 設定失敗${NC}"
    
    echo -e "${YELLOW}設定 JWT_SECRET...${NC}"
    wrangler secret put JWT_SECRET || echo -e "${RED}❌ 設定失敗${NC}"
    
    echo -e "${YELLOW}設定 HEXSTRIKE_API_KEYS...${NC}"
    wrangler secret put HEXSTRIKE_API_KEYS || echo -e "${RED}❌ 設定失敗${NC}"
    
    echo -e "${GREEN}✅ Secrets 設定完成${NC}"
fi

# 部署
echo -e "\n${CYAN}🚀 部署到 Cloudflare...${NC}"
cd "$SCRIPT_DIR"

if wrangler deploy; then
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      🎉 部署成功！                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}📊 部署摘要：${NC}"
    [ "$DEPLOY_BACKEND" = true ] && echo -e "   ${GREEN}✓${NC} Go Backend"
    [ "$DEPLOY_AI" = true ] && echo -e "   ${GREEN}✓${NC} AI/Quantum"
    [ "$DEPLOY_HEXSTRIKE" = true ] && echo -e "   ${GREEN}✓${NC} HexStrike AI"
    echo -e "\n${CYAN}🔗 訪問您的服務：${NC}"
    echo -e "   測試健康檢查:"
    echo -e "   ${CYAN}curl https://your-worker.your-subdomain.workers.dev/health${NC}"
    echo -e "\n${CYAN}📝 後續步驟：${NC}"
    echo -e "   1. 在 Cloudflare Dashboard 檢查部署狀態"
    echo -e "   2. 設定自訂網域（如需要）"
    echo -e "   3. 配置 DNS 記錄"
    echo -e "   4. 測試 API 端點"
else
    echo -e "\n${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║      ❌ 部署失敗                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}🔍 故障排除步驟：${NC}"
    echo -e "   1. 檢查 wrangler.toml 配置是否正確"
    echo -e "   2. 確認 Cloudflare 帳戶權限"
    echo -e "   3. 查看詳細錯誤訊息"
    echo -e "   4. 參考 README.md 中的部署指南"
    echo -e "   5. 執行: wrangler tail 查看即時日誌"
    exit 1
fi

echo -e "\n============================================================"

