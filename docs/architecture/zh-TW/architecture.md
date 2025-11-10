# 詳細架構設計文件

> 本文件深入探討系統架構的技術細節和設計決策

## 目錄

- [微服務設計模式](#微服務設計模式)
- [容器編排策略](#容器編排策略)
- [資料庫架構](#資料庫架構)
- [安全架構](#安全架構)
- [網路設計](#網路設計)
- [監控與可觀測性](#監控與可觀測性)

---

## 微服務設計模式

### 服務分解原則

我們採用「按業務能力分解」的原則，將系統劃分為以下微服務：

```
┌─────────────────────────────────────────┐
│          接入層 (Entry Layer)            │
│  - Traefik (Reverse Proxy)              │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         應用層 (Application Layer)       │
│  - Web UI (Query Interface)             │
│  - ArgoCD (GitOps)                      │
│  - Vault (Secret Management)            │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         編排層 (Orchestration Layer)     │
│  - SecureCodeBox Operator               │
│  - Workflow Engine                      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          掃描層 (Scanning Layer)         │
│  - Nuclei Scanner                       │
│  - Nmap Scanner                         │
│  - AMASS Scanner                        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         解析層 (Parsing Layer)           │
│  - Nuclei Parser                        │
│  - Nmap Parser                          │
│  - AMASS Parser                         │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          資料層 (Data Layer)             │
│  - PostgreSQL (Relational DB)           │
│  - Shared Volumes (File Storage)        │
└─────────────────────────────────────────┘
```

### 服務間通訊

#### 1. 同步通訊 (HTTP/REST)

用於需要即時回應的場景：

```
Client → Traefik → Web UI → PostgreSQL
         (HTTP)    (REST)    (TCP/SQL)
```

**優點**:
- 簡單直觀
- 即時回饋
- 易於除錯

**缺點**:
- 耦合度較高
- 需要服務可用

#### 2. 非同步通訊 (Shared Storage)

用於掃描任務：

```
Operator → Scanner → Write to /results/
                     ↓
Parser ← Read from /results/ ← Shared Volume
  ↓
PostgreSQL
```

**優點**:
- 鬆耦合
- 容錯性強
- 可重試

**缺點**:
- 延遲較高
- 需要輪詢或監聽

### 服務發現機制

使用 Docker 內建的 DNS 服務發現：

```yaml
services:
  scanner:
    # 可通過 'postgres' 主機名連接
    environment:
      DB_HOST: postgres  # Docker DNS 自動解析
  
  postgres:
    # 服務名稱即為 hostname
```

---

## 容器編排策略

### Docker Compose 配置模式

#### 1. 健康檢查與依賴管理

```yaml
services:
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sectools"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s
  
  parser:
    depends_on:
      postgres:
        condition: service_healthy  # 等待 postgres 健康
```

**啟動順序**:
```
1. postgres 啟動
2. postgres 健康檢查通過
3. parser 啟動
```

#### 2. 資源限制與保留

```yaml
deploy:
  resources:
    limits:
      cpus: '2'          # 最多使用 2 核
      memory: 2G         # 最多使用 2GB
    reservations:
      cpus: '0.5'        # 保證 0.5 核
      memory: 512M       # 保證 512MB
```

**目的**:
- 防止單一服務佔用所有資源
- 保證關鍵服務的基本資源
- 提升系統穩定性

#### 3. 卷管理策略

```yaml
volumes:
  # 資料庫持久化（重要資料）
  postgres_data:
    driver: local
  
  # 掃描結果（可定期清理）
  scan_results:
    driver: local
  
  # 快取（可隨時刪除）
  nuclei_templates:
    driver: local
```

**卷生命週期管理**:
- `postgres_data`: 定期備份，永久保留
- `scan_results`: 30-90 天保留期
- `nuclei_templates`: 可重新下載，隨時清理

---

## 資料庫架構

### Schema 設計理念

#### 1. 核心實體關係

```
scan_jobs (掃描任務)
    ↓ 1:N
scan_findings (統一發現項)
    ↓ 1:N
nuclei_results (Nuclei 特定)
nmap_results (Nmap 特定)
amass_results (AMASS 特定)
```

#### 2. 正規化 vs 反正規化

**正規化部分** (避免冗餘):
```sql
-- 掃描任務基本資訊
scan_jobs (
    id,
    scan_type,  -- 'nuclei', 'nmap', 'amass'
    target,
    status
)

-- 發現項通用欄位
scan_findings (
    id,
    scan_job_id REFERENCES scan_jobs(id),
    severity,
    title,
    cvss_score
)
```

**反正規化部分** (提升查詢效能):
```sql
-- 工具特定結果（包含部分冗餘資料）
nuclei_results (
    id,
    scan_job_id,
    -- 冗餘存儲 severity（避免 JOIN）
    severity,
    -- Nuclei 特定欄位
    template_id,
    matched_at
)
```

#### 3. JSONB 欄位使用

**適合使用 JSONB 的場景**:
```sql
-- 動態、非結構化資料
scan_findings (
    ...
    evidence JSONB,  -- 證據資料（各工具不同）
    metadata JSONB   -- 擴展元數據
)
```

**JSONB 索引**:
```sql
-- GIN 索引加速 JSONB 查詢
CREATE INDEX idx_evidence_gin ON scan_findings USING GIN (evidence);

-- 查詢範例
SELECT * FROM scan_findings 
WHERE evidence @> '{"type": "xss"}';
```

### 索引策略

#### 1. B-tree 索引（預設）

用於等值查詢和範圍查詢：

```sql
-- 嚴重度查詢
CREATE INDEX idx_severity ON scan_findings(severity);

-- 時間範圍查詢
CREATE INDEX idx_discovered_at ON scan_findings(discovered_at);

-- 複合索引
CREATE INDEX idx_job_severity ON scan_findings(scan_job_id, severity);
```

#### 2. GIN 索引

用於全文搜尋和 JSONB：

```sql
-- 陣列欄位
CREATE INDEX idx_cve_ids_gin ON scan_findings USING GIN (cve_ids);

-- JSONB 欄位
CREATE INDEX idx_metadata_gin ON scan_findings USING GIN (metadata);
```

#### 3. 部分索引

只索引常用資料：

```sql
-- 只索引高危和嚴重漏洞
CREATE INDEX idx_critical_findings 
ON scan_findings(discovered_at)
WHERE severity IN ('critical', 'high');
```

### 查詢優化

#### 1. 使用 View 簡化查詢

```sql
CREATE VIEW critical_findings AS
SELECT 
    sj.scan_type,
    sj.target,
    sf.severity,
    sf.title,
    sf.cvss_score,
    sf.discovered_at
FROM scan_findings sf
JOIN scan_jobs sj ON sf.scan_job_id = sj.id
WHERE sf.severity IN ('critical', 'high')
ORDER BY sf.cvss_score DESC;

-- 使用 View
SELECT * FROM critical_findings WHERE discovered_at > NOW() - INTERVAL '7 days';
```

#### 2. 物化 View 加速複雜查詢

```sql
CREATE MATERIALIZED VIEW mv_monthly_stats AS
SELECT 
    DATE_TRUNC('month', discovered_at) as month,
    scan_type,
    severity,
    COUNT(*) as finding_count
FROM scan_findings
JOIN scan_jobs ON scan_findings.scan_job_id = scan_jobs.id
GROUP BY month, scan_type, severity;

-- 建立索引
CREATE INDEX idx_mv_month ON mv_monthly_stats(month);

-- 定期刷新（每日）
REFRESH MATERIALIZED VIEW mv_monthly_stats;
```

---

## 安全架構

### 深度防禦策略

#### Layer 1: 網路隔離

```yaml
# 自定義 Docker Network
networks:
  security_net:
    driver: bridge
    internal: false  # 可訪問外網（掃描需要）
    ipam:
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1
```

**隔離規則**:
- 掃描器可訪問外網（執行掃描）
- 資料庫不可直接訪問外網
- 僅 Traefik 暴露端口到主機

#### Layer 2: 容器安全

**最小權限執行**:
```yaml
services:
  scanner:
    user: "1000:1000"  # 非 root 使用者
    read_only: true    # 唯讀根檔案系統
    tmpfs:
      - /tmp           # 臨時檔案使用記憶體
    cap_drop:
      - ALL            # 移除所有 capabilities
    cap_add:
      - NET_RAW        # 僅添加必要的（Nmap 需要）
```

**Seccomp Profile**:
```yaml
security_opt:
  - no-new-privileges:true
  - seccomp=default.json
```

#### Layer 3: 密鑰管理

**Vault 架構**:
```
Application
    ↓ (Request Secret)
Vault Server
    ↓ (Authenticate & Authorize)
Secret Engine
    ↓ (Dynamic Secret Generation)
Backend Storage (Encrypted)
```

**動態密鑰工作流**:
```bash
# 1. 應用程式向 Vault 請求資料庫憑證
TOKEN=$(vault write -field=token auth/approle/login \
    role_id=xxx secret_id=xxx)

# 2. Vault 動態生成臨時憑證（TTL: 1小時）
CREDS=$(vault read -format=json database/creds/scanner)

# 3. 應用程式使用臨時憑證連接資料庫
psql -h postgres -U $(echo $CREDS | jq -r .data.username) ...

# 4. 1小時後憑證自動失效，需重新請求
```

**優勢**:
- 無需在配置檔中存儲密碼
- 自動輪換
- 審計追蹤
- 即時撤銷

---

## 網路設計

### 服務端口規劃

| 服務 | 內部端口 | 暴露端口 | 協定 | 用途 |
|------|---------|---------|------|------|
| Traefik | 80, 443, 8080 | 80, 443, 8080 | HTTP/HTTPS | 反向代理與管理 |
| PostgreSQL | 5432 | - | TCP | 資料庫（內部） |
| Vault | 8200 | 8200 | HTTP | 密鑰管理 |
| ArgoCD | 8080 | 8081 | HTTP | GitOps UI |
| Web UI | 8080 | 8082 | HTTP | 查詢介面 |

**安全考量**:
- PostgreSQL 不暴露到主機（僅容器內訪問）
- 生產環境應關閉 Traefik Dashboard (8080)
- 使用 Traefik 統一處理 SSL

### DNS 解析

Docker 內建 DNS 自動解析服務名稱：

```bash
# 在任何容器內
ping postgres     # 解析到 postgres 容器 IP
ping vault        # 解析到 vault 容器 IP
ping scanner-nuclei  # 解析到 scanner-nuclei 容器 IP
```

**自訂 DNS**（如需要）:
```yaml
services:
  scanner:
    dns:
      - 8.8.8.8      # Google DNS
      - 1.1.1.1      # Cloudflare DNS
    dns_search:
      - example.com
```

---

## 監控與可觀測性

### 三大支柱實作

#### 1. Metrics（指標）

**Prometheus 配置**:
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:9187']
  
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
  
  - job_name: 'docker'
    static_configs:
      - targets: ['docker-exporter:9323']
```

**關鍵指標**:
- 容器 CPU/記憶體使用率
- 資料庫連線數
- 掃描成功/失敗率
- API 回應時間

#### 2. Logs（日誌）

**Loki + Promtail 架構**:
```
Container Logs
    ↓
Docker Log Driver
    ↓
Promtail (收集)
    ↓
Loki (儲存)
    ↓
Grafana (查詢與視覺化)
```

**日誌標籤**:
```yaml
# promtail 配置
scrape_configs:
  - job_name: containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'
```

#### 3. Traces（追蹤）

**分散式追蹤** (未來整合):
```
User Request
    ↓ (Trace ID: abc123)
Traefik
    ↓ (Span: routing)
Web UI
    ↓ (Span: query)
PostgreSQL
    ↓ (Span: sql_query)
Response
```

---

## 災難恢復計劃

### RTO & RPO 目標

- **RTO** (Recovery Time Objective): 1 小時
- **RPO** (Recovery Point Objective): 24 小時

### 備份策略

#### 1. PostgreSQL 備份

```bash
#!/bin/bash
# scripts/backup.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=/backups
RETENTION_DAYS=30

# 全量備份
docker-compose exec -T postgres pg_dump -U sectools -Fc security > \
    $BACKUP_DIR/security-$DATE.dump

# 刪除舊備份
find $BACKUP_DIR -name "security-*.dump" -mtime +$RETENTION_DAYS -delete

# 上傳到雲端（可選）
# aws s3 cp $BACKUP_DIR/security-$DATE.dump s3://my-bucket/backups/
```

#### 2. Vault 備份

```bash
# Vault snapshot
docker exec vault vault operator raft snapshot save /vault/snapshots/vault-$DATE.snap
```

#### 3. 配置檔備份

```bash
# Git 版本控制
git add docker-compose.yml .env Makefile
git commit -m "Backup config $DATE"
git push origin main
```

### 還原程序

#### PostgreSQL 還原

```bash
# 1. 停止服務
docker-compose stop postgres

# 2. 還原資料
docker-compose exec -T postgres pg_restore -U sectools -d security < backup-20251017.dump

# 3. 啟動服務
docker-compose start postgres

# 4. 驗證
docker exec -it postgres psql -U sectools -d security -c "SELECT COUNT(*) FROM scan_jobs;"
```

---

**文件版本**: 1.0  
**最後更新**: 2025-10-17

