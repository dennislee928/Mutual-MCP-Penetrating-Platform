#!/bin/bash
# 部署 HexStrike Worker 到 Cloudflare (使用 Cloudflare 容器註冊表)

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 部署 HexStrike Worker 到 Cloudflare${NC}"
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
echo -e "   配置檔案: wrangler-hexstrike.toml"
echo -e "   容器映像: hexstrike:latest"
echo -e "   最大實例數: 2"

# 驗證配置（dry-run）
echo -e "\n${YELLOW}🔍 驗證配置...${NC}"
if wrangler deploy --config wrangler-hexstrike.toml --dry-run; then
    echo -e "${GREEN}✅ 配置驗證通過${NC}"
else
    echo -e "${RED}❌ 配置驗證失敗${NC}"
    echo -e "${YELLOW}   請檢查 wrangler-hexstrike.toml 配置${NC}"
    exit 1
fi

# 部署 HexStrike Worker
echo -e "\n${CYAN}📤 部署 HexStrike Worker...${NC}"
echo -e "${YELLOW}   這可能需要幾分鐘時間...${NC}"

if wrangler deploy --config wrangler-hexstrike.toml; then
    echo -e "${GREEN}✅ HexStrike Worker 部署成功${NC}"
    
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 部署成功！                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    
    # 獲取部署資訊
    echo -e "\n${CYAN}📊 部署資訊：${NC}"
    echo -e "${YELLOW}   獲取部署詳情...${NC}"
    wrangler deployments list --name unified-hexstrike || echo -e "${YELLOW}   (執行 'wrangler deployments list --name unified-hexstrike' 查看詳情)${NC}"
    
    echo -e "\n${CYAN}🔗 測試您的服務：${NC}"
    echo -e "   ${YELLOW}Health Check:${NC}"
    echo -e "   curl https://unified-hexstrike.<your-subdomain>.workers.dev/health"
    echo -e ""
    echo -e "   ${YELLOW}查找實際 URL:${NC}"
    echo -e "   1. 登入 Cloudflare Dashboard"
    echo -e "   2. 進入 Workers & Pages"
    echo -e "   3. 找到 'unified-hexstrike'"
    echo -e "   4. 複製 URL"
    
    echo -e "\n${CYAN}📝 後續步驟：${NC}"
    echo -e "   1. 在 Cloudflare Dashboard 檢查 Worker 狀態"
    echo -e "   2. 實時日誌："
    echo -e "      ${YELLOW}wrangler tail unified-hexstrike${NC}"
    echo -e "   3. 查看容器實例："
    echo -e "      ${YELLOW}wrangler deployments list --name unified-hexstrike${NC}"
    echo -e "   4. 測試 API 端點"
    
    echo -e "\n${CYAN}💡 提示：${NC}"
    echo -e "   • 容器會在首次請求時啟動（冷啟動）"
    echo -e "   • 容器閒置 10 分鐘後會自動停止"
    echo -e "   • 最多可運行 2 個並發實例"
    echo -e "   • 查看容器日誌: wrangler tail unified-hexstrike"
    
else
    echo -e "${RED}❌ HexStrike Worker 部署失敗${NC}"
    
    echo -e "\n${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ 部署失敗                         ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}🔍 故障排除：${NC}"
    echo -e "   1. 確認容器映像已推送："
    echo -e "      ${YELLOW}bash ./push-dockerhub-to-cloudflare.sh${NC}"
    echo -e ""
    echo -e "   2. 檢查 Cloudflare 帳號權限："
    echo -e "      - Workers 權限"
    echo -e "      - Containers (Beta) 權限"
    echo -e ""
    echo -e "   3. 驗證配置："
    echo -e "      ${YELLOW}wrangler deploy --config wrangler-hexstrike.toml --dry-run --verbose${NC}"
    echo -e ""
    echo -e "   4. 查看詳細錯誤："
    echo -e "      ${YELLOW}wrangler deploy --config wrangler-hexstrike.toml --verbose${NC}"
    echo -e ""
    echo -e "   5. 檢查 Wrangler 版本："
    echo -e "      ${YELLOW}wrangler --version${NC}"
    echo -e "      (需要 >= 3.x 才支援 Containers)"
    exit 1
fi

echo -e "\n============================================================"

