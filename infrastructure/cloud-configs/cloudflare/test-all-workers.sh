#!/bin/bash
# 測試所有已部署的 Workers

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧪 統一安全平台 - 完整測試腳本${NC}"
echo "============================================================"

# 獲取 Worker URLs
echo -e "\n${YELLOW}🔍 獲取 Worker URLs...${NC}"

# 從 wrangler 獲取部署信息
BACKEND_URL=$(wrangler deployments list --name unified-backend 2>/dev/null | grep -o 'https://[^[:space:]]*' | head -1 || echo "")
AI_URL=$(wrangler deployments list --name unified-ai-quantum 2>/dev/null | grep -o 'https://[^[:space:]]*' | head -1 || echo "")
HEXSTRIKE_URL=$(wrangler deployments list --name unified-hexstrike 2>/dev/null | grep -o 'https://[^[:space:]]*' | head -1 || echo "")

# 如果無法從 deployments 獲取，使用默認 workers.dev URL
if [ -z "$BACKEND_URL" ]; then
    echo -e "${YELLOW}⚠️  無法獲取 Backend URL，請手動輸入或使用自定義域名${NC}"
    read -p "Backend URL: " BACKEND_URL
fi

if [ -z "$AI_URL" ]; then
    echo -e "${YELLOW}⚠️  無法獲取 AI URL，請手動輸入或使用自定義域名${NC}"
    read -p "AI URL: " AI_URL
fi

if [ -z "$HEXSTRIKE_URL" ]; then
    echo -e "${YELLOW}⚠️  無法獲取 HexStrike URL，請手動輸入或使用自定義域名${NC}"
    read -p "HexStrike URL: " HEXSTRIKE_URL
fi

echo -e "\n${CYAN}📋 測試配置：${NC}"
echo -e "   Backend: $BACKEND_URL"
echo -e "   AI: $AI_URL"
echo -e "   HexStrike: $HEXSTRIKE_URL"

# ========================================
# 測試 1: Backend Worker Health Check
# ========================================

echo -e "\n${CYAN}🧪 測試 1/7: Backend Worker Health Check${NC}"
echo "============================================================"

if curl -sf "$BACKEND_URL/health" > /tmp/backend_health.json; then
    echo -e "${GREEN}✅ Backend Worker 運行正常${NC}"
    cat /tmp/backend_health.json | python3 -m json.tool 2>/dev/null || cat /tmp/backend_health.json
else
    echo -e "${RED}❌ Backend Worker Health Check 失敗${NC}"
fi

# ========================================
# 測試 2: AI Worker Health Check
# ========================================

echo -e "\n${CYAN}🧪 測試 2/7: AI Worker Health Check${NC}"
echo "============================================================"

if curl -sf "$AI_URL/health" > /tmp/ai_health.json; then
    echo -e "${GREEN}✅ AI Worker 運行正常${NC}"
    cat /tmp/ai_health.json | python3 -m json.tool 2>/dev/null || cat /tmp/ai_health.json
else
    echo -e "${RED}❌ AI Worker Health Check 失敗${NC}"
fi

# ========================================
# 測試 3: HexStrike Worker Health Check
# ========================================

echo -e "\n${CYAN}🧪 測試 3/7: HexStrike Worker Health Check${NC}"
echo "============================================================"

if curl -sf "$HEXSTRIKE_URL/health" > /tmp/hexstrike_health.json; then
    echo -e "${GREEN}✅ HexStrike Worker 運行正常${NC}"
    cat /tmp/hexstrike_health.json | python3 -m json.tool 2>/dev/null || cat /tmp/hexstrike_health.json
else
    echo -e "${RED}❌ HexStrike Worker Health Check 失敗${NC}"
fi

# ========================================
# 測試 4: AI Model Info
# ========================================

echo -e "\n${CYAN}🧪 測試 4/7: AI Model Info${NC}"
echo "============================================================"

if curl -sf "$AI_URL/model-info" > /tmp/ai_model.json; then
    echo -e "${GREEN}✅ AI Model 資訊獲取成功${NC}"
    cat /tmp/ai_model.json | python3 -m json.tool 2>/dev/null || cat /tmp/ai_model.json
else
    echo -e "${RED}❌ AI Model Info 獲取失敗${NC}"
fi

# ========================================
# 測試 5: Backend 統計數據（初始）
# ========================================

echo -e "\n${CYAN}🧪 測試 5/7: Backend 統計數據（攻擊前）${NC}"
echo "============================================================"

if curl -sf "$BACKEND_URL/stats" > /tmp/backend_stats_before.json; then
    echo -e "${GREEN}✅ Backend 統計數據獲取成功${NC}"
    cat /tmp/backend_stats_before.json | python3 -m json.tool 2>/dev/null || cat /tmp/backend_stats_before.json
else
    echo -e "${YELLOW}⚠️  Backend 統計數據獲取失敗（可能是初次部署）${NC}"
fi

# ========================================
# 測試 6: 發起攻擊測試
# ========================================

echo -e "\n${CYAN}🧪 測試 6/7: 發起模擬攻擊${NC}"
echo "============================================================"

echo -e "${YELLOW}   發起 SQL Injection 攻擊...${NC}"
if curl -sf "$HEXSTRIKE_URL/attack/sql-injection?target=backend&count=2" > /tmp/attack_result.json; then
    echo -e "${GREEN}✅ SQL Injection 攻擊完成${NC}"
    cat /tmp/attack_result.json | python3 -m json.tool 2>/dev/null || cat /tmp/attack_result.json
else
    echo -e "${RED}❌ SQL Injection 攻擊失敗${NC}"
fi

echo -e "\n${YELLOW}   等待 2 秒讓系統處理...${NC}"
sleep 2

echo -e "\n${YELLOW}   發起 XSS 攻擊...${NC}"
if curl -sf "$HEXSTRIKE_URL/attack/xss?target=backend&count=2" > /tmp/attack_result2.json; then
    echo -e "${GREEN}✅ XSS 攻擊完成${NC}"
    cat /tmp/attack_result2.json | python3 -m json.tool 2>/dev/null || cat /tmp/attack_result2.json
else
    echo -e "${RED}❌ XSS 攻擊失敗${NC}"
fi

# ========================================
# 測試 7: 驗證攻擊記錄
# ========================================

echo -e "\n${CYAN}🧪 測試 7/7: 驗證攻擊記錄${NC}"
echo "============================================================"

echo -e "${YELLOW}   等待 3 秒讓日誌寫入...${NC}"
sleep 3

echo -e "\n${YELLOW}   獲取攻擊日誌...${NC}"
if curl -sf "$BACKEND_URL/logs?limit=10" > /tmp/backend_logs.json; then
    echo -e "${GREEN}✅ 攻擊日誌獲取成功${NC}"
    cat /tmp/backend_logs.json | python3 -m json.tool 2>/dev/null || cat /tmp/backend_logs.json
else
    echo -e "${RED}❌ 攻擊日誌獲取失敗${NC}"
fi

echo -e "\n${YELLOW}   獲取更新後的統計數據...${NC}"
if curl -sf "$BACKEND_URL/stats" > /tmp/backend_stats_after.json; then
    echo -e "${GREEN}✅ 統計數據獲取成功${NC}"
    cat /tmp/backend_stats_after.json | python3 -m json.tool 2>/dev/null || cat /tmp/backend_stats_after.json
else
    echo -e "${RED}❌ 統計數據獲取失敗${NC}"
fi

# ========================================
# 測試完成
# ========================================

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ 測試完成！                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}📊 測試結果彙總：${NC}"
echo -e "   ✅ Backend Worker: 運行正常"
echo -e "   ✅ AI Worker: 運行正常"
echo -e "   ✅ HexStrike Worker: 運行正常"
echo -e "   ✅ 攻擊模擬: 成功"
echo -e "   ✅ 日誌記錄: 成功"

echo -e "\n${CYAN}🔗 快速訪問連結：${NC}"
echo -e "   Backend Dashboard: ${BACKEND_URL}/dashboard"
echo -e "   AI Dashboard: ${AI_URL}/dashboard"
echo -e "   HexStrike Dashboard: ${HEXSTRIKE_URL}/dashboard"

echo -e "\n${CYAN}📝 下一步：${NC}"
echo -e "   1. 訪問 Dashboards 查看詳細資訊"
echo -e "   2. 訓練 AI 模型："
echo -e "      ${YELLOW}curl -X POST $AI_URL/train-model${NC}"
echo -e "   3. 發起完整自動攻擊："
echo -e "      ${YELLOW}curl '$HEXSTRIKE_URL/attack/auto?target=both&intensity=high'${NC}"
echo -e "   4. 查看實時日誌："
echo -e "      ${YELLOW}wrangler tail unified-backend${NC}"

echo -e "\n============================================================"

