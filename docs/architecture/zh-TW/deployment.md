# 部署指南

> 本文件提供從開發環境到生產環境的完整部署指南

## 目錄

- [部署模式選擇](#部署模式選擇)
- [開發環境部署](#開發環境部署)
- [測試環境部署](#測試環境部署)
- [生產環境部署](#生產環境部署)
- [雲端平台部署](#雲端平台部署)
- [Kubernetes 部署](#kubernetes-部署)
- [部署檢查清單](#部署檢查清單)

---

## 部署模式選擇

### 環境對比

| 特性 | 開發環境 | 測試環境 | 生產環境 |
|------|---------|---------|---------|
| 硬體需求 | 2核/4GB | 4核/8GB | 8+核/16+GB |
| 高可用性 | ❌ | 部分 | ✅ |
| 備份策略 | 無 | 每日 | 即時+每日 |
| 監控 | 基本 | 完整 | 完整+告警 |
| SSL/TLS | 自簽憑證 | 自簽憑證 | Let's Encrypt |
| 資料保留 | 7天 | 30天 | 90天+ |
| 部署時間 | 5分鐘 | 15分鐘 | 30分鐘+ |

---

## 開發環境部署

### 快速啟動

適合本地開發和測試：

```bash
# 1. 克隆專案
git clone https://github.com/your-username/Security-and-Infrastructure-tools-Set.git
cd Security-and-Infrastructure-tools-Set

# 2. 使用預設配置啟動
cd Make_Files
make up

# 3. 檢查狀態
make health
```

### 開發環境配置

**最小化 `.env` 配置**:
```bash
# 資料庫（使用簡單密碼）
DB_PASSWORD=devpass123
VAULT_TOKEN=devtoken

# 掃描設定（降低並發）
SCAN_CONCURRENCY=5
NUCLEI_RATE_LIMIT=50

# 除錯模式
DEBUG=true
```

### 開發技巧

#### 1. 即時日誌查看

```bash
# 所有服務日誌
docker-compose logs -f

# 特定服務
docker-compose logs -f postgres
docker-compose logs -f scanner-nuclei
```

#### 2. 快速重建服務

```bash
# 重建特定服務
docker-compose up -d --build scanner-nuclei

# 強制重建所有服務
docker-compose build --no-cache
docker-compose up -d --force-recreate
```

#### 3. 資料庫重置

```bash
# 停止並刪除所有資料
make clean

# 重新初始化
make up
```

---

## 測試環境部署

### 硬體規劃

```
┌─────────────────────────────────────┐
│        測試伺服器規格                │
├─────────────────────────────────────┤
│ CPU:        4 核心                  │
│ RAM:        8GB                     │
│ Disk:       100GB SSD               │
│ Network:    1Gbps                   │
│ OS:         Ubuntu 22.04 LTS        │
└─────────────────────────────────────┘
```

### 部署步驟

#### 1. 伺服器準備

```bash
# 更新系統
sudo apt update && sudo apt upgrade -y

# 安裝 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安裝 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 將使用者加入 docker 群組
sudo usermod -aG docker $USER
newgrp docker

# 安裝 Make
sudo apt install make -y
```

#### 2. 防火牆配置

```bash
# UFW 防火牆規則
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# 或使用 iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

#### 3. 部署應用程式

```bash
# 克隆專案到 /opt
cd /opt
sudo git clone https://github.com/your-username/Security-and-Infrastructure-tools-Set.git
cd Security-and-Infrastructure-tools-Set

# 配置環境變數
cp .env.template .env
nano .env  # 修改配置

# 啟動服務
cd Make_Files
make up

# 驗證部署
make health
```

#### 4. 設定自動啟動

```bash
# 創建 systemd service
sudo nano /etc/systemd/system/security-stack.service
```

```ini
[Unit]
Description=Security Tools Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/Security-and-Infrastructure-tools-Set/Make_Files
ExecStart=/usr/bin/make up
ExecStop=/usr/bin/make down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
# 啟用服務
sudo systemctl enable security-stack.service
sudo systemctl start security-stack.service
```

### 測試環境監控

#### 1. 健康檢查腳本

```bash
#!/bin/bash
# /opt/health-check.sh

SERVICES=("postgres" "vault" "traefik" "argocd")
FAILED=0

for service in "${SERVICES[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null)
    if [ "$STATUS" != "healthy" ]; then
        echo "❌ $service is $STATUS"
        FAILED=1
    else
        echo "✅ $service is healthy"
    fi
done

exit $FAILED
```

#### 2. 定時健康檢查

```bash
# 加入 crontab
crontab -e

# 每 5 分鐘檢查一次
*/5 * * * * /opt/health-check.sh || /usr/bin/systemctl restart security-stack.service
```

---

## 生產環境部署

### 架構設計

```
┌──────────────────────────────────────────────────┐
│                  Load Balancer                   │
│              (Nginx/HAProxy/AWS ELB)             │
└─────────────┬──────────────┬─────────────────────┘
              │              │
     ┌────────▼──────┐  ┌───▼────────┐
     │   App Node 1  │  │ App Node 2 │
     │  (Active)     │  │ (Standby)  │
     └────────┬──────┘  └───┬────────┘
              │              │
              └──────┬───────┘
                     │
         ┌───────────▼────────────┐
         │  PostgreSQL Primary    │
         └───────────┬────────────┘
                     │
         ┌───────────▼────────────┐
         │ PostgreSQL Replica     │
         │    (Read-only)         │
         └────────────────────────┘
```

### 生產環境檢查清單

#### 安全性

- [ ] **強密碼**: 修改所有預設密碼
- [ ] **SSL/TLS**: 啟用 Let's Encrypt 或使用企業憑證
- [ ] **防火牆**: 配置嚴格的防火牆規則
- [ ] **密鑰管理**: 使用 Vault 或 AWS Secrets Manager
- [ ] **網路隔離**: 資料庫不暴露公網
- [ ] **審計日誌**: 啟用所有服務的審計功能
- [ ] **入侵偵測**: 部署 fail2ban 或 OSSEC

#### 高可用性

- [ ] **負載均衡**: 多節點部署
- [ ] **資料庫複製**: PostgreSQL 主從架構
- [ ] **健康檢查**: 自動故障轉移
- [ ] **備份策略**: 自動化備份與異地儲存
- [ ] **監控告警**: Prometheus + AlertManager

#### 效能優化

- [ ] **資源限制**: 合理配置 CPU/Memory
- [ ] **連線池**: pgBouncer 資料庫連線池
- [ ] **快取**: Redis 快取熱點資料
- [ ] **CDN**: 靜態資源使用 CDN
- [ ] **壓縮**: 啟用 gzip/brotli 壓縮

### 生產環境配置

#### 1. 環境變數 (生產)

```bash
# .env.production

# === 安全設定 ===
DB_PASSWORD=<使用 pwgen 生成 32 位隨機密碼>
VAULT_TOKEN=<使用 vault token create 生成>

# === 資料庫設定 ===
DB_HOST=postgres-primary.internal
DB_PORT=5432
DB_REPLICA_HOST=postgres-replica.internal  # 讀寫分離

# === 掃描設定 ===
SCAN_CONCURRENCY=20
NUCLEI_RATE_LIMIT=200
SCAN_TIMEOUT=7200  # 2 小時

# === 監控設定 ===
PROMETHEUS_ENABLED=true
GRAFANA_ADMIN_PASSWORD=<strong_password>

# === 備份設定 ===
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=90
BACKUP_S3_BUCKET=my-security-backups
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx

# === 告警設定 ===
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx
ALERT_EMAIL=security-team@company.com

# === 其他 ===
DEBUG=false
TZ=Asia/Taipei
LOG_LEVEL=INFO
```

#### 2. Docker Compose 覆蓋

創建 `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  traefik:
    command:
      - "--api.insecure=false"  # 關閉不安全的 API
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@company.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    volumes:
      - letsencrypt:/letsencrypt
  
  postgres:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
    volumes:
      - /mnt/data/postgres:/var/lib/postgresql/data  # 使用外部掛載
  
  # 添加備份服務
  backup:
    image: prodrigestivill/postgres-backup-local:14
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_DB: security
      POSTGRES_USER: sectools
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      SCHEDULE: "@daily"
      BACKUP_KEEP_DAYS: 90
    volumes:
      - /mnt/backups:/backups

volumes:
  letsencrypt:
```

**啟動生產環境**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

#### 3. 資料庫優化

```sql
-- PostgreSQL 生產環境調優
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;  # SSD
ALTER SYSTEM SET effective_io_concurrency = 200;  # SSD
ALTER SYSTEM SET work_mem = '32MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';
ALTER SYSTEM SET max_worker_processes = 4;
ALTER SYSTEM SET max_parallel_workers_per_gather = 2;
ALTER SYSTEM SET max_parallel_workers = 4;

-- 重新載入
SELECT pg_reload_conf();
```

---

## 雲端平台部署

### AWS 部署

#### 架構圖

```
Internet
    │
    ├─► Application Load Balancer (ALB)
         │
         ├─► Target Group: EC2 Auto Scaling Group
              │
              ├─► EC2 Instance 1 (Docker Host)
              ├─► EC2 Instance 2 (Docker Host)
              └─► EC2 Instance 3 (Docker Host)
         │
         └─► RDS PostgreSQL (Multi-AZ)
         │
         └─► ElastiCache Redis (Optional)
         │
         └─► EFS (Shared Storage)
         │
         └─► S3 (Backup Storage)
```

#### 部署步驟

**1. VPC 與子網路**

```bash
# 使用 AWS CLI 創建 VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=security-vpc}]'

# 創建子網路
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
```

**2. RDS PostgreSQL**

```bash
# 創建 DB 子網路群組
aws rds create-db-subnet-group \
    --db-subnet-group-name security-db-subnet \
    --db-subnet-group-description "Security Tools DB Subnet" \
    --subnet-ids subnet-xxx subnet-yyy

# 創建 RDS 實例
aws rds create-db-instance \
    --db-instance-identifier security-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --engine-version 15.4 \
    --master-username sectools \
    --master-user-password <strong_password> \
    --allocated-storage 100 \
    --storage-type gp3 \
    --multi-az \
    --backup-retention-period 30 \
    --db-subnet-group-name security-db-subnet
```

**3. EC2 Auto Scaling**

```bash
# 創建啟動範本
aws ec2 create-launch-template \
    --launch-template-name security-stack-template \
    --version-description "v1.0" \
    --launch-template-data file://launch-template.json
```

`launch-template.json`:
```json
{
  "ImageId": "ami-xxxxxxxxx",
  "InstanceType": "t3.large",
  "KeyName": "my-key-pair",
  "SecurityGroupIds": ["sg-xxx"],
  "UserData": "IyEvYmluL2Jhc2gK...",  # Base64 encoded startup script
  "IamInstanceProfile": {
    "Name": "EC2-Security-Stack-Role"
  },
  "BlockDeviceMappings": [{
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "VolumeSize": 100,
      "VolumeType": "gp3",
      "DeleteOnTermination": true
    }
  }]
}
```

**User Data Script**:
```bash
#!/bin/bash
# 安裝 Docker
curl -fsSL https://get.docker.com | sh

# 安裝 Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 克隆專案
cd /opt
git clone https://github.com/your-username/Security-and-Infrastructure-tools-Set.git
cd Security-and-Infrastructure-tools-Set

# 從 AWS Secrets Manager 獲取密鑰
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id security-db-password --query SecretString --output text)
export VAULT_TOKEN=$(aws secretsmanager get-secret-value --secret-id vault-token --query SecretString --output text)

# 創建 .env
cat > .env <<EOF
DB_HOST=$(aws rds describe-db-instances --db-instance-identifier security-db --query 'DBInstances[0].Endpoint.Address' --output text)
DB_PASSWORD=$DB_PASSWORD
VAULT_TOKEN=$VAULT_TOKEN
EOF

# 啟動服務
cd Make_Files
make up
```

### GCP 部署

#### 使用 Google Cloud Run

```bash
# 1. 構建容器映像
gcloud builds submit --tag gcr.io/your-project/security-stack

# 2. 部署到 Cloud Run
gcloud run deploy security-stack \
    --image gcr.io/your-project/security-stack \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --set-env-vars DB_HOST=xxx,DB_PASSWORD=xxx \
    --memory 2Gi \
    --cpu 2
```

### Azure 部署

#### 使用 Azure Container Instances

```bash
# 1. 創建資源群組
az group create --name security-stack-rg --location eastus

# 2. 創建 Azure Database for PostgreSQL
az postgres server create \
    --resource-group security-stack-rg \
    --name security-db \
    --location eastus \
    --admin-user sectools \
    --admin-password <strong_password> \
    --sku-name GP_Gen5_2

# 3. 部署容器
az container create \
    --resource-group security-stack-rg \
    --name security-stack \
    --image your-registry/security-stack:latest \
    --dns-name-label security-stack \
    --ports 80 443 \
    --environment-variables DB_HOST=security-db.postgres.database.azure.com DB_PASSWORD=xxx \
    --cpu 2 \
    --memory 4
```

---

## Kubernetes 部署

### Helm Chart 結構

```
security-stack-helm/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── hpa.yaml
└── charts/
    └── postgresql/  # 子圖表
```

### 簡化部署（未來版本）

```bash
# 使用 Helm 部署
helm install security-stack ./security-stack-helm \
    --namespace security \
    --create-namespace \
    --values values.production.yaml

# 查看狀態
kubectl get pods -n security

# 更新部署
helm upgrade security-stack ./security-stack-helm
```

---

## 部署檢查清單

### 部署前

- [ ] 選擇合適的部署模式
- [ ] 準備硬體/雲端資源
- [ ] 配置域名與 DNS
- [ ] 準備 SSL 憑證
- [ ] 規劃備份策略
- [ ] 設計監控方案

### 部署中

- [ ] 克隆/上傳程式碼
- [ ] 配置環境變數
- [ ] 啟動服務
- [ ] 檢查健康狀態
- [ ] 驗證網路連通性
- [ ] 測試基本功能

### 部署後

- [ ] 執行測試掃描
- [ ] 驗證資料庫連接
- [ ] 確認備份正常
- [ ] 設定監控告警
- [ ] 文件化部署細節
- [ ] 團隊培訓

---

**文件版本**: 1.0  
**最後更新**: 2025-10-17

