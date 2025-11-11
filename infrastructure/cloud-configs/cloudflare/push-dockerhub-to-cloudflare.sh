#!/bin/bash
# 從 Docker Hub 拉取映像並推送到 Cloudflare 容器註冊表

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔄 從 Docker Hub 推送映像到 Cloudflare${NC}"
echo "============================================================"

# Docker Hub 映像資訊
DOCKERHUB_IMAGE="dennisleetw/hexstrike-ai:latest"
CLOUDFLARE_TAG="hexstrike:latest"

# 檢查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 未安裝 Docker${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker 已安裝${NC}"

# 檢查 Docker daemon
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon 未運行${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker daemon 運行中${NC}"

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

# 步驟 1：從 Docker Hub 拉取映像
echo -e "\n${CYAN}📥 步驟 1/3: 從 Docker Hub 拉取映像...${NC}"
echo -e "${YELLOW}   映像: ${DOCKERHUB_IMAGE}${NC}"
echo -e "${YELLOW}   警告: 映像大小約 7.93GB，拉取可能需要幾分鐘...${NC}"

if docker pull "$DOCKERHUB_IMAGE"; then
    echo -e "${GREEN}✅ 映像拉取成功${NC}"
else
    echo -e "${RED}❌ 映像拉取失敗${NC}"
    echo -e "${YELLOW}   請確認：${NC}"
    echo -e "${YELLOW}   1. Docker Hub 映像是否存在${NC}"
    echo -e "${YELLOW}   2. 映像是否為 Public（或已登入 Docker Hub）${NC}"
    echo -e "${YELLOW}   3. 網路連線是否正常${NC}"
    exit 1
fi

# 步驟 2：重新 tag 給 Cloudflare
echo -e "\n${CYAN}🏷️  步驟 2/3: 重新 tag 映像...${NC}"
echo -e "${YELLOW}   從: ${DOCKERHUB_IMAGE}${NC}"
echo -e "${YELLOW}   到: ${CLOUDFLARE_TAG}${NC}"

if docker tag "$DOCKERHUB_IMAGE" "$CLOUDFLARE_TAG"; then
    echo -e "${GREEN}✅ Tag 成功${NC}"
else
    echo -e "${RED}❌ Tag 失敗${NC}"
    exit 1
fi

# 步驟 3：推送到 Cloudflare 容器註冊表
echo -e "\n${CYAN}📤 步驟 3/3: 推送到 Cloudflare 容器註冊表...${NC}"
echo -e "${YELLOW}   這可能需要幾分鐘時間，請耐心等待...${NC}"

if wrangler containers push hexstrike; then
    echo -e "${GREEN}✅ 映像已成功推送到 Cloudflare${NC}"
else
    echo -e "${RED}❌ 推送到 Cloudflare 失敗${NC}"
    echo -e "${YELLOW}   故障排除：${NC}"
    echo -e "${YELLOW}   1. 確認您的 Cloudflare 帳號有 Workers 權限${NC}"
    echo -e "${YELLOW}   2. 檢查 wrangler 版本: wrangler --version${NC}"
    echo -e "${YELLOW}   3. 嘗試重新登入: wrangler logout && wrangler login${NC}"
    echo -e "${YELLOW}   4. 查看詳細日誌${NC}"
    exit 1
fi

# 總結
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 映像推送成功！                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}📊 映像資訊：${NC}"
echo -e "   來源: ${DOCKERHUB_IMAGE}"
echo -e "   Cloudflare: hexstrike:latest"
echo -e "   大小: ~7.93GB"

echo -e "\n${CYAN}📝 下一步：${NC}"
echo -e "   1. 部署 Worker:"
echo -e "      ${YELLOW}bash ./deploy-hexstrike-cloudflare.sh${NC}"
echo -e ""
echo -e "   2. 或手動部署:"
echo -e "      ${YELLOW}wrangler deploy --config wrangler-hexstrike.toml${NC}"
echo -e ""
echo -e "   3. 查看容器狀態:"
echo -e "      ${YELLOW}wrangler deployments list${NC}"

echo -e "\n============================================================"

