# 系統架構設計文件 | System Architecture

> 本文件詳細說明 Security & Infrastructure Tools Set 的架構設計理念、技術選型、資料流程與擴展性考量

---

## 📋 目錄

- [架構概覽](#架構概覽)
- [設計原則](#設計原則)
- [技術選型理由](#技術選型理由)
- [服務架構](#服務架構)
- [資料流程](#資料流程)
- [資料庫設計](#資料庫設計)
- [網路拓樸](#網路拓樸)
- [安全架構](#安全架構)
- [擴展性設計](#擴展性設計)
- [效能與安全權衡](#效能與安全權衡)

---

## 架構概覽

### 系統架構圖

```
┌─────────────────────────────────────────────────────────────────┐
│                         外部使用者                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │    Traefik      │ ◄── 反向代理 & 負載均衡
                    │  (Port 80/443)  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼─────┐      ┌──────▼──────┐      ┌─────▼──────┐
   │  Vault   │      │   ArgoCD    │      │  Web UI    │
   │ :8200    │      │   :8081     │      │  :8082     │
   └────┬─────┘      └──────┬──────┘      └─────┬──────┘
        │ 密鑰管理          │ GitOps            │ 查詢介面
        │                   │                    │
        └───────────────────┼────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   PostgreSQL   │ ◄── 中央資料庫
                    │     :5432      │
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼─────┐      ┌─────▼──────┐      ┌────▼──────┐
   │ Scanner  │      │  Operator  │      │  Parsers  │
   │ Nuclei   │      │ SecCodeBox │      │ N/A/N     │
   │ Nmap     │      │            │      │           │
   └──────────┘      └────────────┘      └───────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                    ┌───────▼────────┐
                    │  Scan Results  │ ◄── 共享儲存卷
                    │    Volume      │
                    └────────────────┘
```

### 核心組件

1. **接入層**: Traefik（反向代理、SSL 終止）
2. **密鑰管理層**: Vault（敏感資料集中管理）
3. **資料層**: PostgreSQL（關聯式資料庫）
4. **掃描層**: Nuclei, Nmap, AMASS（安全掃描工具）
5. **編排層**: SecureCodeBox Operator（工作流管理）
6. **解析層**: 各工具 Parser（結果標準化）
7. **部署層**: ArgoCD（GitOps 持續部署）

---

## 設計原則

### 1. 容器化優先 (Container-First)

**理念**: 每個服務運行在獨立容器中，遵循單一職責原則

**優勢**:
- 隔離性：故障不會蔓延
- 可移植性：任何支援 Docker 的環境都能運行
- 可重現性：版本固定，環境一致
- 可擴展性：水平擴展簡單

**實踐**:
```yaml
# 每個服務獨立定義
services:
  postgres:     # 一個容器，一個服務
  vault:        # 一個容器，一個服務
  nuclei:       # 一個容器，一個服務
```

### 2. 微服務架構 (Microservices)

**理念**: 將複雜系統拆分為小型、鬆耦合的服務

**服務分層**:
```
展示層 → Web UI, Dashboard
應用層 → Operator, Parsers
掃描層 → Nuclei, Nmap, AMASS
資料層 → PostgreSQL, Volumes
基礎層 → Traefik, Vault
```

**通訊機制**:
- HTTP/REST API（同步）
- 共享資料庫（狀態共享）
- 共享卷（檔案交換）
- Docker Network（服務發現）

### 3. 聲明式配置 (Declarative Configuration)

**理念**: 使用 Docker Compose YAML 描述期望狀態

**優勢**:
- 版本控制：配置即代碼
- 可審查性：變更可追蹤
- 可重現性：一鍵部署

### 4. 健康優先 (Health-First)

**理念**: 每個關鍵服務都有健康檢查

**實踐**:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U sectools"]
  interval: 10s
  timeout: 5s
  retries: 5
```

**依賴管理**:
```yaml
depends_on:
  postgres:
    condition: service_healthy  # 等待健康後才啟動
```

### 5. 安全內建 (Security by Design)

**理念**: 安全不是事後添加，而是設計時內建

**實踐**:
- 密鑰管理：Vault 集中管理
- 網路隔離：自定義 Docker Network
- 最小權限：唯讀掛載 (`ro`)
- 資源限制：防止資源耗盡

---

## 技術選型理由

### PostgreSQL (資料庫)

**為何選擇**:
- ✅ 強大的 JSONB 支援（適合非結構化掃描結果）
- ✅ 豐富的索引類型（B-tree, GIN, GIST）
- ✅ 成熟的生態系統
- ✅ ACID 保證（資料完整性）
- ✅ 優秀的全文搜尋功能

**替代方案對比**:
| 特性 | PostgreSQL | MySQL | MongoDB |
|------|-----------|-------|---------|
| 關聯查詢 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| JSON 支援 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 效能 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 生態系統 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

**結論**: 需要關聯查詢和 JSON 靈活性，PostgreSQL 最佳

### Vault (密鑰管理)

**為何選擇**:
- ✅ 業界標準的密鑰管理解決方案
- ✅ 動態密鑰生成
- ✅ 審計日誌完整
- ✅ 支援多種後端儲存
- ✅ HashiCorp 生態系統整合

**使用場景**:
```
資料庫密碼 → Vault 動態生成，定期輪換
API Token → 加密儲存，按需讀取
憑證管理 → PKI 後端自動簽發
```

### Traefik (反向代理)

**為何選擇**:
- ✅ 原生 Docker 整合（自動服務發現）
- ✅ 自動 Let's Encrypt SSL
- ✅ 輕量級（相比 Nginx Ingress）
- ✅ 動態配置，無需重啟
- ✅ 內建監控指標

**vs Nginx**:
| 特性 | Traefik | Nginx |
|------|---------|-------|
| Docker 原生 | ✅ | ❌ |
| 自動 SSL | ✅ | 需插件 |
| 動態更新 | ✅ | 需 reload |
| 配置複雜度 | 低 | 高 |

### Nuclei (漏洞掃描)

**為何選擇**:
- ✅ 快速（Go 編寫，並發能力強）
- ✅ 模板化掃描（YAML 定義，易擴展）
- ✅ 社群活躍（templates 更新快）
- ✅ 低誤報率
- ✅ 輕量級資源需求

**模板範例**:
```yaml
id: example-check
info:
  name: Example Vulnerability
  severity: high
requests:
  - method: GET
    path: /{path}
    matchers:
      - type: word
        words: ["vulnerable_string"]
```

### SecureCodeBox (編排)

**為何選擇**:
- ✅ 專為安全掃描設計
- ✅ 統一的掃描介面
- ✅ 結果標準化（SARIF 格式）
- ✅ 易於整合新掃描器
- ✅ Kubernetes-native（未來擴展）

---

## 服務架構

### 服務分層詳解

#### Layer 1: 網路層
```
Traefik
├── 功能：反向代理、負載均衡、SSL 終止
├── 端口：80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
└── 路由規則：基於域名/路徑的流量分發
```

#### Layer 2: 應用層
```
Web UI, ArgoCD, Vault
├── 提供：用戶介面、配置管理、密鑰存取
├── 通訊：HTTP REST API
└── 認證：基於 Token 的存取控制
```

#### Layer 3: 編排層
```
SecureCodeBox Operator
├── 功能：掃描任務調度、生命週期管理
├── 輸入：掃描請求（JSON）
└── 輸出：標準化結果（SARIF）
```

#### Layer 4: 掃描層
```
Nuclei, Nmap, AMASS
├── 功能：實際執行安全掃描
├── 輸入：目標清單、掃描參數
└── 輸出：原始掃描結果（JSON/XML）
```

#### Layer 5: 解析層
```
Parser-Nuclei, Parser-AMASS
├── 功能：標準化掃描結果
├── 輸入：原始掃描輸出
└── 輸出：結構化資料（寫入資料庫）
```

#### Layer 6: 資料層
```
PostgreSQL
├── 功能：持久化儲存
├── 資料：掃描任務、發現項、元數據
└── 備份：pg_dump 定期備份
```

### 服務通訊矩陣

| 源服務 | 目標服務 | 協定 | 用途 |
|--------|---------|------|------|
| Traefik | Web UI | HTTP | 流量轉發 |
| Traefik | Vault | HTTP | API 存取 |
| Traefik | ArgoCD | HTTP | GitOps 介面 |
| Scanner | PostgreSQL | TCP:5432 | 寫入結果 |
| Parser | PostgreSQL | TCP:5432 | 標準化儲存 |
| All | Vault | HTTP:8200 | 密鑰讀取 |
| Operator | Scanner | Docker API | 任務調度 |

---

## 資料流程

### 完整掃描流程

```
1. 使用者觸發掃描
   │
   └─► make scan-nuclei TARGET=example.com
        │
        ├─► 2. Operator 接收請求
        │    │
        │    ├─► 檢查 Vault 是否有必要的憑證
        │    └─► 建立掃描任務記錄 (scan_jobs 表)
        │
        ├─► 3. Scanner 執行掃描
        │    │
        │    ├─► 從 Vault 讀取配置
        │    ├─► 執行 Nuclei 掃描
        │    └─► 輸出到 /results/nuclei-{timestamp}.json
        │
        ├─► 4. Parser 解析結果
        │    │
        │    ├─► 讀取 JSON 檔案
        │    ├─► 標準化資料結構
        │    └─► 寫入 nuclei_results 和 scan_findings 表
        │
        └─► 5. 結果可查詢
             │
             ├─► Web UI 展示
             ├─► API 查詢
             └─► SQL 直接查詢
```

### 資料轉換流程

```
原始掃描輸出 (JSON/XML)
    │
    ├─► Parser 標準化
    │    │
    │    ├─► 提取關鍵欄位
    │    ├─► 嚴重度歸一化
    │    ├─► CVE 映射
    │    └─► CVSS 評分計算
    │
    └─► 結構化資料
         │
         ├─► scan_findings (通用發現項)
         ├─► nuclei_results (Nuclei 特定)
         ├─► nmap_results (Nmap 特定)
         └─► amass_results (AMASS 特定)
```

---

## 資料庫設計

### Schema 設計理念

1. **正規化 vs 反正規化權衡**
   - 核心表（scan_jobs, scan_findings）高度正規化
   - 工具特定表（nuclei_results）允許部分反正規化
   - JSONB 欄位儲存動態資料（evidence, metadata）

2. **索引策略**
   ```sql
   -- 查詢優化
   CREATE INDEX idx_scan_findings_severity ON scan_findings(severity);
   CREATE INDEX idx_scan_jobs_status ON scan_jobs(status);
   
   -- JSONB 索引（快速查詢元數據）
   CREATE INDEX idx_scan_findings_evidence_gin ON scan_findings USING GIN (evidence);
   ```

3. **分割策略（未來）**
   ```sql
   -- 時間分割（按月）
   CREATE TABLE scan_findings_2025_01 PARTITION OF scan_findings
   FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
   ```

### 實體關聯圖 (ERD)

```
┌─────────────────┐
│   scan_jobs     │
├─────────────────┤
│ id (PK)         │
│ scan_type       │◄──┐
│ target          │   │
│ status          │   │
│ started_at      │   │ 1:N
│ completed_at    │   │
│ metadata (JSON) │   │
└─────────────────┘   │
                      │
        ┌─────────────┼─────────────┬─────────────┐
        │             │             │             │
┌───────▼────────┐ ┌──▼──────────┐ ┌▼────────────┐ ┌▼───────────┐
│ scan_findings  │ │nuclei_res.  │ │nmap_results │ │amass_res.  │
├────────────────┤ ├─────────────┤ ├─────────────┤ ├────────────┤
│ id (PK)        │ │ id (PK)     │ │ id (PK)     │ │ id (PK)    │
│ scan_job_id(FK)│ │ job_id (FK) │ │ job_id (FK) │ │ job_id(FK) │
│ severity       │ │ template_id │ │ host        │ │ domain     │
│ title          │ │ matched_at  │ │ port        │ │ subdomain  │
│ cvss_score     │ │ severity    │ │ service     │ │ ip[]       │
│ evidence (JSON)│ │ results (J) │ │ version     │ │ sources[]  │
└────────────────┘ └─────────────┘ └─────────────┘ └────────────┘
```

### View 設計

```sql
-- 高危發現項快速查詢
CREATE VIEW critical_findings AS
SELECT 
    sj.scan_type,
    sj.target,
    sf.severity,
    sf.title,
    sf.host,
    sf.cvss_score,
    sf.discovered_at
FROM scan_findings sf
JOIN scan_jobs sj ON sf.scan_job_id = sj.id
WHERE sf.severity IN ('critical', 'high')
ORDER BY sf.cvss_score DESC, sf.discovered_at DESC;

-- 掃描統計儀表板
CREATE VIEW scan_summary AS
SELECT 
    scan_type,
    COUNT(*) as total_scans,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM scan_jobs
GROUP BY scan_type;
```

---

## 網路拓樸

### Docker Network 設計

```yaml
networks:
  security_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1
```

**優勢**:
- 服務間可通過服務名稱通訊（DNS 解析）
- 與主機網路隔離
- 自定義 IP 範圍避免衝突

### 服務網路配置

```
外網 (0.0.0.0/0)
    │
    └─► Traefik (80, 443, 8080)
         │
         └─► security_net (172.28.0.0/16)
              │
              ├─► postgres (172.28.0.2)
              ├─► vault (172.28.0.3)
              ├─► argocd (172.28.0.4)
              ├─► scanner-nuclei (動態 IP)
              └─► nmap (動態 IP)
```

### 防火牆規則（建議）

```bash
# 僅允許必要的對外端口
iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT   # HTTPS
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT  # Traefik Dashboard (生產應關閉)
iptables -A INPUT -j DROP  # 其他全部拒絕
```

---

## 安全架構

### 多層防禦策略

```
Layer 1: 網路隔離
├─► Docker Network (服務間隔離)
├─► 防火牆規則（端口限制）
└─► TLS 加密（Traefik 自動化）

Layer 2: 身份認證
├─► Vault Token 驗證
├─► ArgoCD RBAC
└─► PostgreSQL 密碼認證

Layer 3: 授權控制
├─► 最小權限原則
├─► 唯讀掛載（配置檔）
└─► 資源限制（CPU/Memory）

Layer 4: 審計日誌
├─► Vault Audit Log
├─► PostgreSQL Query Log
└─► Docker Container Log
```

### 密鑰管理生命週期

```
1. 生成
   │ Vault 動態生成資料庫憑證
   │
2. 分發
   │ 環境變數注入容器
   │ 禁止明文儲存
   │
3. 使用
   │ 應用程式讀取環境變數
   │ 記憶體中處理，不落地
   │
4. 輪換
   │ 定期自動更新（30天）
   │ 零停機時間輪換
   │
5. 撤銷
   │ 即時撤銷洩露憑證
   │ Vault Lease 機制
```

### 容器安全最佳實踐

```yaml
# 唯讀根檔案系統
read_only: true
tmpfs:
  - /tmp

# 移除不必要的 Linux Capabilities
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # 僅添加必要的

# 非 root 使用者運行
user: "1000:1000"

# Seccomp Profile
security_opt:
  - seccomp=default.json

# 資源限制（防止 DoS）
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1G
```

---

## 擴展性設計

### 水平擴展策略

#### 1. 無狀態服務擴展
```yaml
# 掃描器可水平擴展
scanner-nuclei:
  deploy:
    replicas: 3  # 增加副本數
  scale: 3
```

#### 2. 資料庫讀寫分離
```yaml
# 主從架構
postgres-primary:
  image: postgres:15-alpine
  
postgres-replica-1:
  image: postgres:15-alpine
  environment:
    POSTGRES_PRIMARY_HOST: postgres-primary
    POSTGRES_REPLICATION_MODE: slave
```

#### 3. 快取層添加
```yaml
# Redis 快取掃描結果
redis:
  image: redis:7-alpine
  deploy:
    resources:
      limits:
        memory: 256M
```

### 垂直擴展考量

```yaml
# 根據負載調整資源
postgres:
  deploy:
    resources:
      limits:
        cpus: '4'      # 原 2 → 4
        memory: 8G     # 原 2G → 8G
```

### 儲存擴展

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: nfs  # 改用 NFS 網路儲存
      o: addr=10.0.0.100,rw
      device: ":/mnt/postgres"
```

### 未來 Kubernetes 遷移路徑

```
當前 Docker Compose 架構
    │
    ├─► 階段 1: 服務無狀態化
    │    ├─► 外部資料庫
    │    └─► 外部儲存（S3/NFS）
    │
    ├─► 階段 2: Helm Charts
    │    ├─► Chart 定義
    │    └─► ConfigMaps/Secrets
    │
    └─► 階段 3: Kubernetes
         ├─► Deployments
         ├─► Services
         ├─► Ingress
         └─► HPA (自動擴展)
```

---

## 效能與安全權衡

### 權衡決策表

| 決策點 | 效能選項 | 安全選項 | 我們的選擇 | 理由 |
|--------|---------|---------|-----------|------|
| 資料庫連線 | 連線池 (大) | 連線池 (小) | 中等大小池 | 平衡並發與資源 |
| 掃描並發度 | 高 | 低 | 中等 (10) | 避免目標 IP 被封 |
| 日誌等級 | ERROR | DEBUG | INFO | 生產 INFO，除錯 DEBUG |
| SSL 驗證 | 關閉 | 嚴格 | 嚴格 | 安全優先 |
| 掃描速率 | 無限制 | 嚴格限制 | 150 req/s | 避免 DoS 誤判 |
| 結果保留 | 永久 | 30天 | 90天 | 合規與儲存平衡 |

### 效能優化建議

#### 1. 資料庫優化
```sql
-- 定期 VACUUM
VACUUM ANALYZE scan_findings;

-- 分割大表
ALTER TABLE scan_findings PARTITION BY RANGE (discovered_at);

-- 物化視圖（快速查詢）
CREATE MATERIALIZED VIEW mv_monthly_stats AS
SELECT ...;
REFRESH MATERIALIZED VIEW mv_monthly_stats;
```

#### 2. 掃描優化
```bash
# Nuclei 效能調優
nuclei \
  -c 50 \              # 並發數
  -rate-limit 150 \    # 速率限制
  -timeout 5 \         # 逾時設定
  -retries 1 \         # 重試次數
  -bulk-size 25        # 批次大小
```

#### 3. 網路優化
```yaml
# Traefik 優化
--entrypoints.web.http.maxIdleConnsPerHost=200
--entrypoints.web.http.idleConnTimeout=90s
```

### 安全強化建議

#### 1. 最小化攻擊面
```bash
# 移除不必要的服務
# 關閉 Debug 端口
# 使用 Alpine 基礎映像（小體積）
```

#### 2. 定期安全掃描
```bash
# 掃描容器映像
trivy image postgres:15-alpine

# 掃描 Compose 檔案
checkov -f docker-compose.yml
```

#### 3. 安全更新策略
```yaml
# 使用特定版本（非 latest）
postgres:15.4-alpine  # ✅ 好
postgres:latest       # ❌ 避免

# 定期檢查更新
watchtower:  # 自動更新容器
  image: containrrr/watchtower
```

---

## 監控與可觀測性

### 三大支柱

```
Metrics (指標)
├─► Prometheus 收集
├─► Grafana 視覺化
└─► 關鍵指標
    ├─► 掃描成功率
    ├─► 資料庫連線數
    ├─► 容器資源使用
    └─► API 回應時間

Logs (日誌)
├─► Loki 聚合
├─► Promtail 收集
└─► 關鍵日誌
    ├─► 掃描錯誤
    ├─► 認證失敗
    ├─► 資料庫慢查詢
    └─► 容器重啟

Traces (追蹤)
├─► Jaeger 分散式追蹤
└─► 請求流程視覺化
    └─► 使用者請求 → Scanner → Parser → DB
```

---

## 災難恢復

### 備份策略

```
RTO (Recovery Time Objective): 1小時
RPO (Recovery Point Objective): 24小時

備份內容：
├─► PostgreSQL 資料庫 (每日)
├─► Vault 密鑰 (每週)
├─► 配置檔案 (每次變更)
└─► 掃描結果 (選擇性)

備份方式：
├─► 自動化備份腳本
├─► 異地儲存 (S3/NFS)
└─► 加密備份檔案
```

### 還原測試

```bash
# 定期測試還原流程（每季）
1. 停止服務
2. 還原資料庫
3. 驗證資料完整性
4. 重啟服務
5. 執行測試掃描
```

---

## 總結

本架構設計基於以下核心理念：

1. **容器化與微服務**: 模組化、可擴展
2. **安全內建**: 多層防禦、密鑰管理
3. **可觀測性**: 完整的監控與日誌
4. **實用主義**: 權衡效能與安全
5. **演進式設計**: Docker → Kubernetes 平滑過渡

**適用場景**:
- ✅ 中小型團隊安全掃描平台
- ✅ 持續安全測試 CI/CD 整合
- ✅ 漏洞管理與追蹤
- ✅ 安全研究與學習

**未來演進方向**:
- 🚀 AI 增強分析
- 🚀 雲原生部署 (K8s)
- 🚀 多租戶支援
- 🚀 威脅情報整合

---

**文件維護**: 本文件應隨架構變更同步更新

**最後更新**: 2025-10-17  
**版本**: 1.0  
**作者**: Security Infrastructure Team

