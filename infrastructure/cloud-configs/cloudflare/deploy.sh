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
echo -e "\n${YELLOW}📦 安裝 npm 依賴...${NC}"
npm install
echo -e "${GREEN}✅ 依賴安裝完成${NC}"

# 建置並推送容器映像
if [ "$DEPLOY_BACKEND" = true ]; then
    echo -e "\n${CYAN}🏗️  建置 Go Backend 容器映像...${NC}"
    cd ../../../src/backend
    docker build -t unified-backend:latest .
    if [ $? -eq 0 ]; then
        cd ../../infrastructure/cloud-configs/cloudflare
        wrangler containers push backend ../../../src/backend/Dockerfile
        echo -e "${GREEN}✅ Go Backend 映像已推送${NC}"
    else
        echo -e "${RED}❌ Go Backend 建置失敗${NC}"
    fi
fi

if [ "$DEPLOY_AI" = true ]; then
    echo -e "\n${CYAN}🤖 建置 AI/Quantum 容器映像...${NC}"
    cd ../../../src/ai-quantum
    docker build -t unified-ai-quantum:latest .
    if [ $? -eq 0 ]; then
        cd ../../infrastructure/cloud-configs/cloudflare
        wrangler containers push ai-quantum ../../../src/ai-quantum/Dockerfile
        echo -e "${GREEN}✅ AI/Quantum 映像已推送${NC}"
    else
        echo -e "${RED}❌ AI/Quantum 建置失敗${NC}"
    fi
fi

if [ "$DEPLOY_HEXSTRIKE" = true ]; then
    echo -e "\n${CYAN}🔴 建置 HexStrike AI 容器映像...${NC}"
    cd ../../../src/hexstrike-ai
    docker build -t unified-hexstrike:latest .
    if [ $? -eq 0 ]; then
        cd ../../infrastructure/cloud-configs/cloudflare
        wrangler containers push hexstrike ../../../src/hexstrike-ai/Dockerfile
        echo -e "${GREEN}✅ HexStrike AI 映像已推送${NC}"
    else
        echo -e "${RED}❌ HexStrike AI 建置失敗${NC}"
    fi
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
    wrangler secret put DB_PASSWORD
    wrangler secret put JWT_SECRET
    wrangler secret put HEXSTRIKE_API_KEYS
fi

# 部署
echo -e "\n${CYAN}🚀 部署到 Cloudflare...${NC}"
wrangler deploy

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 部署成功！${NC}"
    echo -e "\n${CYAN}訪問您的服務：${NC}"
    echo -e "   測試健康檢查:"
    echo -e "   ${CYAN}curl https://your-worker.your-subdomain.workers.dev/health${NC}"
else
    echo -e "\n${RED}❌ 部署失敗${NC}"
    echo -e "${YELLOW}   檢查錯誤訊息並參考 README.md${NC}"
fi

echo -e "\n============================================================"

