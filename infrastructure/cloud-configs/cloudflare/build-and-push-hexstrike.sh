#!/bin/bash
# 建置並推送 HexStrike AI 映像到 Docker Hub

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔴 HexStrike AI - 建置並推送到 Docker Hub${NC}"
echo "============================================================"

# Docker Hub 配置
DOCKER_USERNAME="${DOCKER_USERNAME:-your-dockerhub-username}"
IMAGE_NAME="hexstrike-ai"
TAG="latest"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

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

# 詢問 Docker Hub 用戶名
echo -e "\n${YELLOW}📝 Docker Hub 配置${NC}"
read -p "請輸入您的 Docker Hub 用戶名 (或按 Enter 使用 '$DOCKER_USERNAME'): " input_username
if [ -n "$input_username" ]; then
    DOCKER_USERNAME="$input_username"
    FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
fi

echo -e "${CYAN}映像名稱: ${FULL_IMAGE_NAME}${NC}"

# 登入 Docker Hub
echo -e "\n${YELLOW}🔐 登入 Docker Hub...${NC}"
echo "請輸入 Docker Hub 密碼："
if docker login -u "$DOCKER_USERNAME"; then
    echo -e "${GREEN}✅ 登入成功${NC}"
else
    echo -e "${RED}❌ 登入失敗${NC}"
    exit 1
fi

# 切換到 HexStrike 目錄
HEXSTRIKE_DIR="../../../src/hexstrike-ai"
if [ ! -d "$HEXSTRIKE_DIR" ]; then
    echo -e "${RED}❌ 找不到 HexStrike 目錄: $HEXSTRIKE_DIR${NC}"
    exit 1
fi

echo -e "\n${CYAN}🏗️  建置 HexStrike AI 映像...${NC}"
echo -e "${YELLOW}   警告：這可能需要 30-60 分鐘，請耐心等待${NC}"
echo -e "${YELLOW}   目錄: $(cd $HEXSTRIKE_DIR && pwd)${NC}"

cd "$HEXSTRIKE_DIR"

# 建置映像
if docker build -t "$FULL_IMAGE_NAME" .; then
    echo -e "${GREEN}✅ 映像建置成功${NC}"
else
    echo -e "${RED}❌ 映像建置失敗${NC}"
    exit 1
fi

# 推送映像
echo -e "\n${CYAN}📤 推送映像到 Docker Hub...${NC}"
echo -e "${YELLOW}   這可能需要幾分鐘時間...${NC}"

if docker push "$FULL_IMAGE_NAME"; then
    echo -e "${GREEN}✅ 映像推送成功${NC}"
else
    echo -e "${RED}❌ 映像推送失敗${NC}"
    exit 1
fi

# 顯示映像資訊
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 建置並推送成功！                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}📊 映像資訊：${NC}"
echo -e "   Docker Hub: https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
echo -e "   映像名稱: ${FULL_IMAGE_NAME}"
echo -e "   大小: $(docker images $FULL_IMAGE_NAME --format "{{.Size}}")"

echo -e "\n${CYAN}📝 下一步：${NC}"
echo -e "   1. 更新 Cloudflare wrangler 配置"
echo -e "   2. 將映像名稱設為: ${FULL_IMAGE_NAME}"
echo -e "   3. 執行 ./deploy-workers.sh 部署"

echo -e "\n${YELLOW}💡 提示：${NC}"
echo -e "   如果要設為公開映像："
echo -e "   1. 登入 https://hub.docker.com"
echo -e "   2. 進入 ${DOCKER_USERNAME}/${IMAGE_NAME}"
echo -e "   3. Settings → Make Public"

echo -e "\n============================================================"

