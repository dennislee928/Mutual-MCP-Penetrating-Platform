#!/bin/bash
# 部署所有 Workers 到 Cloudflare 的完整腳本

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 統一安全平台 - 完整部署腳本${NC}"
echo "============================================================"

# 檢查 Wrangler
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ 未安裝 Wrangler CLI${NC}"
    echo -e "${YELLOW}   執行: npm install -g wrangler${NC}"
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

# ========================================
# 步驟 1: 創建 D1 資料庫
# ========================================

echo -e "\n${CYAN}📦 步驟 1/5: 創建 D1 資料庫${NC}"
echo "============================================================"

DB_NAME="security-platform-db"

# 檢查資料庫是否已存在
if wrangler d1 list | grep -q "$DB_NAME"; then
    echo -e "${YELLOW}⚠️  資料庫 '$DB_NAME' 已存在${NC}"
    echo -e "${YELLOW}   繼續使用現有資料庫${NC}"
else
    echo -e "${CYAN}   創建新資料庫: $DB_NAME${NC}"
    wrangler d1 create "$DB_NAME"
fi

# 獲取資料庫 ID
DB_ID=$(wrangler d1 list | grep "$DB_NAME" | awk '{print $2}')
echo -e "${GREEN}✅ 資料庫 ID: $DB_ID${NC}"

# 執行 Schema 初始化
echo -e "\n${CYAN}   執行 SQL Schema...${NC}"
if [ -f "../../terraform/d1-schema.sql" ]; then
    wrangler d1 execute "$DB_NAME" --file=../../terraform/d1-schema.sql --remote || true
    echo -e "${GREEN}✅ Schema 執行完成${NC}"
else
    echo -e "${YELLOW}⚠️  未找到 schema 文件，跳過${NC}"
fi

# ========================================
# 步驟 2: 更新 Wrangler 配置文件
# ========================================

echo -e "\n${CYAN}📝 步驟 2/5: 更新 Wrangler 配置文件${NC}"
echo "============================================================"

# 更新 backend wrangler.toml
if [ -f "wrangler-backend.toml" ]; then
    echo -e "${CYAN}   更新 wrangler-backend.toml${NC}"
    sed -i.bak "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler-backend.toml || \
        sed -i '' "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler-backend.toml
    echo -e "${GREEN}✅ Backend config 已更新${NC}"
fi

# 更新 ai wrangler.toml
if [ -f "wrangler-ai.toml" ]; then
    echo -e "${CYAN}   更新 wrangler-ai.toml${NC}"
    sed -i.bak "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler-ai.toml || \
        sed -i '' "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler-ai.toml
    echo -e "${GREEN}✅ AI config 已更新${NC}"
fi

# ========================================
# 步驟 3: 部署 Backend Worker
# ========================================

echo -e "\n${CYAN}📤 步驟 3/5: 部署 Backend Worker${NC}"
echo "============================================================"

if [ -f "wrangler-backend.toml" ] && [ -f "src/backend-worker.js" ]; then
    echo -e "${YELLOW}   部署中...${NC}"
    if wrangler deploy --config wrangler-backend.toml; then
        echo -e "${GREEN}✅ Backend Worker 部署成功${NC}"
    else
        echo -e "${RED}❌ Backend Worker 部署失敗${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Backend Worker 配置或代碼文件未找到${NC}"
    exit 1
fi

# ========================================
# 步驟 4: 部署 AI Worker
# ========================================

echo -e "\n${CYAN}📤 步驟 4/5: 部署 AI Worker${NC}"
echo "============================================================"

if [ -f "wrangler-ai.toml" ] && [ -f "src/ai-worker.js" ]; then
    echo -e "${YELLOW}   部署中...${NC}"
    if wrangler deploy --config wrangler-ai.toml; then
        echo -e "${GREEN}✅ AI Worker 部署成功${NC}"
    else
        echo -e "${RED}❌ AI Worker 部署失敗${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ AI Worker 配置或代碼文件未找到${NC}"
    exit 1
fi

# ========================================
# 步驟 5: 部署 HexStrike Worker
# ========================================

echo -e "\n${CYAN}📤 步驟 5/5: 部署 HexStrike Worker${NC}"
echo "============================================================"

if [ -f "wrangler-hexstrike.toml" ] && [ -f "src/hexstrike-worker.js" ]; then
    echo -e "${YELLOW}   部署中...${NC}"
    if wrangler deploy --config wrangler-hexstrike.toml; then
        echo -e "${GREEN}✅ HexStrike Worker 部署成功${NC}"
    else
        echo -e "${RED}❌ HexStrike Worker 部署失敗${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ HexStrike Worker 配置或代碼文件未找到${NC}"
    exit 1
fi

# ========================================
# 部署完成
# ========================================

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 所有 Workers 部署成功！         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}📊 部署資訊：${NC}"
echo -e "   1. Backend Worker: https://unified-backend.<your-subdomain>.workers.dev"
echo -e "   2. AI Worker: https://unified-ai-quantum.<your-subdomain>.workers.dev"
echo -e "   3. HexStrike Worker: https://unified-hexstrike.<your-subdomain>.workers.dev"
echo -e "   4. D1 Database: $DB_NAME (ID: $DB_ID)"

echo -e "\n${CYAN}📝 下一步：${NC}"
echo -e "   1. 配置自定義域名（參考 setup-custom-domains.md）"
echo -e "   2. 測試所有端點："
echo -e "      ${YELLOW}bash test-all-workers.sh${NC}"
echo -e "   3. 查看實時日誌："
echo -e "      ${YELLOW}wrangler tail unified-backend${NC}"
echo -e "      ${YELLOW}wrangler tail unified-ai-quantum${NC}"
echo -e "      ${YELLOW}wrangler tail unified-hexstrike${NC}"
echo -e "   4. 訪問 Dashboards："
echo -e "      Backend: https://unified-backend.<subdomain>.workers.dev/dashboard"
echo -e "      AI: https://unified-ai-quantum.<subdomain>.workers.dev/dashboard"
echo -e "      HexStrike: https://unified-hexstrike.<subdomain>.workers.dev/dashboard"

echo -e "\n============================================================"

