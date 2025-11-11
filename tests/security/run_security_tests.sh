#!/bin/bash
# 安全測試執行腳本

echo "🔐 統一安全平台 - 安全修復驗證測試"
echo "=" | tr '=' '=' | head -c 60; echo

# 檢查環境
if [ -z "$HEXSTRIKE_URL" ]; then
    export HEXSTRIKE_URL="http://localhost:8888"
    echo "⚠️  未設定 HEXSTRIKE_URL，使用預設值: $HEXSTRIKE_URL"
fi

# 檢查服務是否運行
echo ""
echo "📡 檢查服務狀態..."
if curl -s -f "$HEXSTRIKE_URL/health" > /dev/null 2>&1; then
    echo "✅ HexStrike AI 服務正在運行"
else
    echo "❌ HexStrike AI 服務未運行於 $HEXSTRIKE_URL"
    echo "   請先啟動服務：cd src/hexstrike-ai && python hexstrike_server.py"
    exit 1
fi

echo ""
echo "🧪 執行單元測試..."
python -m pytest test_security_fixes.py -v --tb=short

echo ""
echo "🔍 執行手動安全測試..."

# 測試 1: 命令注入
echo ""
echo "📋 測試 1: 命令注入阻擋"
response=$(curl -s -X POST "$HEXSTRIKE_URL/api/tools/nmap" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $HEXSTRIKE_API_KEY" \
    -d '{"target": "8.8.8.8; cat /etc/passwd"}' \
    -w "%{http_code}")

if echo "$response" | grep -q "root:"; then
    echo "❌ 命令注入測試失敗：命令被執行了！"
else
    echo "✅ 命令注入測試通過：命令被阻擋"
fi

# 測試 2: 路徑穿越
echo ""
echo "📋 測試 2: 路徑穿越阻擋"
response=$(curl -s "$HEXSTRIKE_URL/api/files?path=../../../etc/passwd" \
    -H "X-API-Key: $HEXSTRIKE_API_KEY")

if echo "$response" | grep -q "root:"; then
    echo "❌ 路徑穿越測試失敗：敏感文件被讀取了！"
else
    echo "✅ 路徑穿越測試通過：訪問被阻擋"
fi

# 測試 3: 授權
echo ""
echo "📋 測試 3: API 授權"
if [ "$API_AUTH_ENABLED" = "true" ]; then
    response=$(curl -s -w "%{http_code}" "$HEXSTRIKE_URL/api/tools/nmap" \
        -o /dev/null)
    
    if [ "$response" = "401" ]; then
        echo "✅ 授權測試通過：未授權請求被拒絕"
    else
        echo "❌ 授權測試失敗：未授權請求未被拒絕（狀態碼: $response）"
    fi
else
    echo "⚠️  授權功能未啟用（API_AUTH_ENABLED != true）"
fi

echo ""
echo "=" | tr '=' '=' | head -c 60; echo
echo "🎉 安全測試完成！"




