#!/bin/bash
# 部署所有 Workers 到 Cloudflare
# 此腳本會部署 Worker 並綁定容器

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 部署 Cloudflare Workers + Containers${NC}"
echo "============================================================"

# 檢查 Wrangler
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ 未安裝 Wrangler CLI${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Wrangler CLI 已安裝${NC}"

# 檢查登入狀態
echo -e "\n${YELLOW}🔐 檢查 Cloudflare 登入狀態...${NC}"
if ! wrangler whoami &> /dev/null; then
    echo -e "${RED}❌ 未登入 Cloudflare${NC}"
    echo -e "${YELLOW}   執行: wrangler login${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 已登入 Cloudflare${NC}"

# 詢問要部署哪些服務
echo -e "\n${CYAN}📦 選擇要部署的 Worker：${NC}"
echo "1. Backend Worker（防禦面 API）"
echo "2. AI/Quantum Worker（AI 威脅偵測）"
echo "3. HexStrike Worker（攻擊面）"
echo "4. 全部 Workers"
echo ""

read -p "請輸入選項 (1-4): " choice

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

DEPLOY_SUCCESS=true

# 部署 Backend Worker
if [ "$DEPLOY_BACKEND" = true ]; then
    echo -e "\n${CYAN}📤 部署 Backend Worker...${NC}"
    if wrangler deploy --config wrangler-backend.toml; then
        echo -e "${GREEN}✅ Backend Worker 部署成功${NC}"
    else
        echo -e "${RED}❌ Backend Worker 部署失敗${NC}"
        DEPLOY_SUCCESS=false
    fi
fi

# 部署 AI/Quantum Worker
if [ "$DEPLOY_AI" = true ]; then
    echo -e "\n${CYAN}📤 部署 AI/Quantum Worker...${NC}"
    if wrangler deploy --config wrangler-ai.toml; then
        echo -e "${GREEN}✅ AI/Quantum Worker 部署成功${NC}"
    else
        echo -e "${RED}❌ AI/Quantum Worker 部署失敗${NC}"
        DEPLOY_SUCCESS=false
    fi
fi

# 部署 HexStrike Worker
if [ "$DEPLOY_HEXSTRIKE" = true ]; then
    echo -e "\n${CYAN}📤 部署 HexStrike Worker (使用 Docker Hub 映像)...${NC}"
    echo -e "${YELLOW}   映像: dennisleetw/hexstrike-ai:latest${NC}"
    if wrangler deploy --config wrangler-hexstrike-dockerhub.toml; then
        echo -e "${GREEN}✅ HexStrike Worker 部署成功${NC}"
    else
        echo -e "${RED}❌ HexStrike Worker 部署失敗${NC}"
        DEPLOY_SUCCESS=false
    fi
fi

# 總結
if [ "$DEPLOY_SUCCESS" = true ]; then
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 所有 Workers 部署成功！           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${CYAN}📊 部署摘要：${NC}"
    [ "$DEPLOY_BACKEND" = true ] && echo -e "   ${GREEN}✓${NC} Backend Worker"
    [ "$DEPLOY_AI" = true ] && echo -e "   ${GREEN}✓${NC} AI/Quantum Worker"
    [ "$DEPLOY_HEXSTRIKE" = true ] && echo -e "   ${GREEN}✓${NC} HexStrike Worker"
    
    echo -e "\n${CYAN}🔗 測試您的服務：${NC}"
    if [ "$DEPLOY_BACKEND" = true ]; then
        echo -e "   ${YELLOW}Backend:${NC}"
        echo -e "   curl https://unified-backend.<your-subdomain>.workers.dev/health"
    fi
    if [ "$DEPLOY_AI" = true ]; then
        echo -e "   ${YELLOW}AI/Quantum:${NC}"
        echo -e "   curl https://unified-ai-quantum.<your-subdomain>.workers.dev/health"
    fi
    if [ "$DEPLOY_HEXSTRIKE" = true ]; then
        echo -e "   ${YELLOW}HexStrike:${NC}"
        echo -e "   curl https://unified-hexstrike.<your-subdomain>.workers.dev/health"
    fi
    
    echo -e "\n${CYAN}📝 後續步驟：${NC}"
    echo -e "   1. 在 Cloudflare Dashboard 檢查 Workers 狀態"
    echo -e "   2. 查看容器實例：wrangler deployments list"
    echo -e "   3. 實時日誌：wrangler tail <worker-name>"
    echo -e "   4. 測試 API 端點"
else
    echo -e "\n${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ 部分 Workers 部署失敗             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}🔍 故障排除：${NC}"
    echo -e "   1. 確認容器映像已推送：./deploy.sh"
    echo -e "   2. 檢查 wrangler 配置：wrangler deploy --dry-run"
    echo -e "   3. 查看詳細錯誤日誌"
    echo -e "   4. 參考 DEPLOY_WORKERS.md"
    exit 1
fi

echo -e "\n============================================================"

