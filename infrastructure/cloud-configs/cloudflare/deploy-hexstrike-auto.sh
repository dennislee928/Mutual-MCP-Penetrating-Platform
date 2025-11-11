#!/bin/bash
# 自動部署 HexStrike Worker 到 Cloudflare (使用 Docker Hub 映像)

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 自動部署 HexStrike Worker 到 Cloudflare${NC}"
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

# 顯示配置資訊
echo -e "\n${CYAN}📋 部署配置：${NC}"
echo -e "   Worker 名稱: unified-hexstrike"
echo -e "   配置檔案: wrangler-hexstrike-dockerhub.toml"
echo -e "   Docker 映像: dennisleetw/hexstrike-ai:latest"
echo -e "   最大實例數: 2"

# 部署 HexStrike Worker
echo -e "\n${CYAN}📤 部署 HexStrike Worker...${NC}"
echo -e "${YELLOW}   這可能需要幾分鐘時間...${NC}"

if wrangler deploy --config wrangler-hexstrike-dockerhub.toml; then
    echo -e "${GREEN}✅ HexStrike Worker 部署成功${NC}"
    
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 部署成功！                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${CYAN}🔗 測試您的服務：${NC}"
    echo -e "   ${YELLOW}Health Check:${NC}"
    echo -e "   curl https://unified-hexstrike.<your-subdomain>.workers.dev/health"
    
    echo -e "\n${CYAN}📝 後續步驟：${NC}"
    echo -e "   1. 在 Cloudflare Dashboard 檢查 Worker 狀態"
    echo -e "   2. 查看容器實例：wrangler deployments list"
    echo -e "   3. 實時日誌：wrangler tail unified-hexstrike"
    echo -e "   4. 測試 API 端點"
    
    echo -e "\n${CYAN}📊 容器資訊：${NC}"
    echo -e "   映像來源: Docker Hub"
    echo -e "   映像名稱: dennisleetw/hexstrike-ai:latest"
    echo -e "   映像大小: 7.93GB"
    echo -e "   端口: 8888"
    
else
    echo -e "${RED}❌ HexStrike Worker 部署失敗${NC}"
    
    echo -e "\n${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ 部署失敗                         ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}🔍 故障排除：${NC}"
    echo -e "   1. 確認 Docker Hub 映像可訪問："
    echo -e "      docker pull dennisleetw/hexstrike-ai:latest"
    echo -e "   2. 檢查 Cloudflare 帳號是否有 Workers 配額"
    echo -e "   3. 檢查 wrangler 配置："
    echo -e "      wrangler deploy --config wrangler-hexstrike-dockerhub.toml --dry-run"
    echo -e "   4. 查看詳細錯誤日誌："
    echo -e "      wrangler deploy --config wrangler-hexstrike-dockerhub.toml --verbose"
    echo -e "   5. 確認 Docker Hub 映像權限（可能需要設為 Public）"
    exit 1
fi

echo -e "\n============================================================"

