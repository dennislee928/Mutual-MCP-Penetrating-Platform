# 安全最佳實踐

> 本文件提供全面的安全配置指南和最佳實踐

## 目錄

- [安全原則](#安全原則)
- [身份認證與授權](#身份認證與授權)
- [密鑰管理](#密鑰管理)
- [網路安全](#網路安全)
- [容器安全](#容器安全)
- [資料保護](#資料保護)
- [審計與合規](#審計與合規)
- [安全檢查清單](#安全檢查清單)

---

## 安全原則

### 深度防禦 (Defense in Depth)

採用多層安全防禦策略，即使某一層被突破，其他層仍能提供保護：

```
Layer 7: 使用者教育與意識 👥
Layer 6: 應用程式安全 🔒
Layer 5: 資料安全 💾
Layer 4: 主機安全 🖥️
Layer 3: 網路安全 🌐
Layer 2: 實體安全 🏢
Layer 1: 政策與程序 📋
```

### 最小權限原則

每個服務和使用者只擁有完成任務所需的最小權限：

**❌ 錯誤做法**:
```yaml
services:
  scanner:
    user: root  # 以 root 運行，風險高
    privileged: true  # 特權模式，可訪問主機
```

**✅ 正確做法**:
```yaml
services:
  scanner:
    user: "1000:1000"  # 非特權使用者
    cap_drop:
      - ALL
    cap_add:
      - NET_RAW  # 僅添加必要的 capability
```

---

## 身份認證與授權

### Vault 認證方法

#### 1. AppRole (推薦用於服務)

```bash
# 創建 AppRole
vault write auth/approle/role/scanner \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40

# 獲取 role_id
ROLE_ID=$(vault read -field=role_id auth/approle/role/scanner/role-id)

# 生成 secret_id
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/scanner/secret-id)

# 使用 AppRole 登入
TOKEN=$(vault write -field=token auth/approle/login \
    role_id=$ROLE_ID \
    secret_id=$SECRET_ID)
```

#### 2. Token (用於初始化)

```bash
# 創建有限期限的 Token
vault token create \
    -policy=scanner-policy \
    -ttl=1h \
    -renewable=false
```

### PostgreSQL 認證

#### 強密碼策略

```sql
-- 創建密碼驗證函數
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 設定密碼複雜度要求
CREATE OR REPLACE FUNCTION check_password_strength(password TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- 至少 12 個字元
    IF LENGTH(password) < 12 THEN
        RETURN FALSE;
    END IF;
    
    -- 至少包含大寫字母
    IF password !~ '[A-Z]' THEN
        RETURN FALSE;
    END IF;
    
    -- 至少包含小寫字母
    IF password !~ '[a-z]' THEN
        RETURN FALSE;
    END IF;
    
    -- 至少包含數字
    IF password !~ '[0-9]' THEN
        RETURN FALSE;
    END IF;
    
    -- 至少包含特殊字元
    IF password !~ '[!@#$%^&*()]' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

#### 角色與權限

```sql
-- 創建只讀角色
CREATE ROLE readonly;
GRANT CONNECT ON DATABASE security TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- 創建掃描器角色（讀寫）
CREATE ROLE scanner_role;
GRANT INSERT, SELECT, UPDATE ON scan_jobs, scan_findings TO scanner_role;

-- 創建具體使用者
CREATE USER scanner_user WITH PASSWORD 'strong_password';
GRANT scanner_role TO scanner_user;
```

---

## 密鑰管理

### Vault 動態密鑰

#### 配置資料庫引擎

```bash
# 啟用資料庫引擎
vault secrets enable database

# 配置 PostgreSQL 連接
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="scanner,readonly" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/security" \
    username="vault" \
    password="vault_password"

# 創建角色（動態生成憑證）
vault write database/roles/scanner \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT scanner_role TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

#### 應用程式使用動態密鑰

```python
import hvac
import psycopg2

# 連接 Vault
client = hvac.Client(url='http://vault:8200', token=os.getenv('VAULT_TOKEN'))

# 獲取動態資料庫憑證
creds = client.secrets.database.generate_credentials('scanner')

# 使用臨時憑證連接資料庫
conn = psycopg2.connect(
    host='postgres',
    database='security',
    user=creds['data']['username'],
    password=creds['data']['password']
)

# 使用後憑證會自動過期
```

### 密鑰輪換策略

```bash
# 定期輪換 Vault 根密鑰
vault operator rekey -init -key-shares=5 -key-threshold=3

# 輪換資料庫根憑證
vault write -f database/rotate-root/postgresql
```

---

## 網路安全

### 防火牆規則

#### iptables 規則

```bash
#!/bin/bash
# firewall-rules.sh

# 清空現有規則
iptables -F
iptables -X

# 預設政策：拒絕所有
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允許 Loopback
iptables -A INPUT -i lo -j ACCEPT

# 允許已建立的連接
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 允許 SSH (限制來源 IP)
iptables -A INPUT -p tcp -s 203.0.113.0/24 --dport 22 -j ACCEPT

# 允許 HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 限制連線速率（防止 DDoS）
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# 記錄被拒絕的連接
iptables -A INPUT -j LOG --log-prefix "iptables-dropped: " --log-level 4

# 儲存規則
iptables-save > /etc/iptables/rules.v4
```

### Docker Network 隔離

```yaml
# 多網路隔離
networks:
  # 公開網路：僅 Traefik 可訪問
  frontend:
    driver: bridge
    internal: false
  
  # 內部網路：應用層通訊
  backend:
    driver: bridge
    internal: true
  
  # 資料庫網路：僅資料庫相關服務
  database:
    driver: bridge
    internal: true

services:
  traefik:
    networks:
      - frontend  # 可訪問外網
  
  web-ui:
    networks:
      - frontend  # 對外服務
      - backend   # 訪問內部服務
  
  postgres:
    networks:
      - database  # 完全隔離
```

### TLS/SSL 配置

#### Traefik 自動 HTTPS

```yaml
# docker-compose.yml
traefik:
  command:
    - "--certificatesresolvers.letsencrypt.acme.email=admin@example.com"
    - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
  labels:
    # 自動重導向 HTTPS
    - "traefik.http.routers.http-catchall.rule=hostregexp(`{host:.+}`)"
    - "traefik.http.routers.http-catchall.entrypoints=web"
    - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
    - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
```

---

## 容器安全

### Docker 最佳實踐

#### 1. 使用最小化基礎映像

**❌ 避免**:
```dockerfile
FROM ubuntu:latest  # 大型映像，攻擊面大
```

**✅ 推薦**:
```dockerfile
FROM alpine:3.18  # 最小化映像
# 或
FROM gcr.io/distroless/static-debian11  # Google Distroless
```

#### 2. 多階段建構

```dockerfile
# 建構階段
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o scanner main.go

# 執行階段
FROM alpine:3.18
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/scanner /usr/local/bin/
USER nobody
ENTRYPOINT ["scanner"]
```

#### 3. 掃描映像漏洞

```bash
# 使用 Trivy 掃描
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image \
    --severity HIGH,CRITICAL \
    scanner-nuclei:latest

# 使用 Snyk
snyk container test scanner-nuclei:latest

# 使用 Clair
clairctl analyze -l scanner-nuclei:latest
```

### Seccomp & AppArmor

#### Seccomp Profile

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "close",
        "stat", "fstat", "lseek", "mmap",
        "mprotect", "munmap", "brk", "rt_sigaction"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

```yaml
# 使用 Seccomp
services:
  scanner:
    security_opt:
      - seccomp=./seccomp-profile.json
```

---

## 資料保護

### 資料加密

#### 1. 傳輸中加密 (TLS)

所有網路通訊使用 TLS 1.2+：

```yaml
# PostgreSQL 啟用 SSL
postgres:
  environment:
    POSTGRES_SSL_CERT_FILE: /etc/ssl/certs/server.crt
    POSTGRES_SSL_KEY_FILE: /etc/ssl/private/server.key
    POSTGRES_SSL_CA_FILE: /etc/ssl/certs/ca.crt
```

#### 2. 靜態資料加密

```bash
# 使用 LUKS 加密磁碟
cryptsetup luksFormat /dev/sdb
cryptsetup open /dev/sdb encrypted_volume
mkfs.ext4 /dev/mapper/encrypted_volume

# 掛載加密卷
mount /dev/mapper/encrypted_volume /var/lib/docker
```

### 備份加密

```bash
#!/bin/bash
# encrypted-backup.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="security-$DATE.sql"
ENCRYPTED_FILE="$BACKUP_FILE.gpg"

# 1. 執行備份
docker-compose exec -T postgres pg_dump -U sectools security > $BACKUP_FILE

# 2. 使用 GPG 加密
gpg --symmetric --cipher-algo AES256 --output $ENCRYPTED_FILE $BACKUP_FILE

# 3. 刪除未加密檔案
rm -f $BACKUP_FILE

# 4. 上傳到雲端
aws s3 cp $ENCRYPTED_FILE s3://my-encrypted-backups/

# 解密還原
# gpg --decrypt security-20251017.sql.gpg > security-20251017.sql
```

---

## 審計與合規

### 審計日誌

#### Vault 審計

```bash
# 啟用檔案審計
vault audit enable file file_path=/vault/logs/audit.log

# 審計日誌格式
{
  "time": "2025-10-17T10:30:45Z",
  "type": "response",
  "auth": {
    "client_token": "hmac-sha256:xxx",
    "accessor": "xxx",
    "display_name": "token",
    "policies": ["scanner-policy"]
  },
  "request": {
    "operation": "read",
    "path": "database/creds/scanner"
  },
  "response": {
    "data": {
      "username": "v-scanner-abcd1234"
    }
  }
}
```

#### PostgreSQL 審計

```sql
-- 啟用查詢日誌
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_duration = 'on';

-- 或使用 pgAudit 擴展
CREATE EXTENSION pgaudit;
ALTER SYSTEM SET pgaudit.log = 'all';
```

### 合規檢查

#### CIS Docker Benchmark

```bash
# 使用 Docker Bench Security
docker run -it --net host --pid host --userns host --cap-add audit_control \
    -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
    -v /etc:/etc:ro \
    -v /usr/bin/containerd:/usr/bin/containerd:ro \
    -v /usr/bin/runc:/usr/bin/runc:ro \
    -v /usr/lib/systemd:/usr/lib/systemd:ro \
    -v /var/lib:/var/lib:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --label docker_bench_security \
    docker/docker-bench-security
```

---

## 安全檢查清單

### 部署前檢查

- [ ] 所有預設密碼已修改
- [ ] 啟用 SSL/TLS
- [ ] 配置防火牆規則
- [ ] 設定密鑰管理（Vault）
- [ ] 容器以非 root 使用者運行
- [ ] 移除不必要的 Linux capabilities
- [ ] 啟用 Seccomp profile
- [ ] 設定資源限制
- [ ] 配置健康檢查
- [ ] 啟用審計日誌

### 定期檢查（每月）

- [ ] 更新容器映像
- [ ] 掃描映像漏洞
- [ ] 輪換密鑰和憑證
- [ ] 檢查審計日誌
- [ ] 測試備份還原
- [ ] 檢查存取控制
- [ ] 更新文件

### 緊急事件回應

- [ ] 隔離受影響系統
- [ ] 收集日誌和證據
- [ ] 通知相關人員
- [ ] 執行根本原因分析
- [ ] 修復漏洞
- [ ] 更新安全政策

---

**文件版本**: 1.0  
**最後更新**: 2025-10-17

