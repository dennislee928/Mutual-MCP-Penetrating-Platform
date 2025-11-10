# 故障排除指南

> 常見問題與解決方案完整指南

## 快速診斷

```bash
# 一鍵診斷腳本
curl -fsSL https://raw.githubusercontent.com/your-username/Security-and-Infrastructure-tools-Set/main/scripts/diagnose.sh | bash
```

## 目錄

- [服務無法啟動](#服務無法啟動)
- [資料庫問題](#資料庫問題)
- [網路連通性問題](#網路連通性問題)
- [掃描問題](#掃描問題)
- [效能問題](#效能問題)
- [資料問題](#資料問題)
- [權限問題](#權限問題)

---

## 服務無法啟動

### 問題 1: 端口已被佔用

**症狀**:
```
Error starting userland proxy: listen tcp 0.0.0.0:8200: bind: address already in use
```

**診斷**:
```bash
# 查看端口佔用
sudo lsof -i :8200
# 或
sudo netstat -tulpn | grep 8200
```

**解決方案**:

方案 A: 停止衝突的服務
```bash
# 找出佔用端口的進程
PID=$(sudo lsof -t -i:8200)
sudo kill -9 $PID
```

方案 B: 修改端口映射
```yaml
# docker-compose.yml
vault:
  ports:
    - "8300:8200"  # 改用 8300 端口
```

### 問題 2: Docker Daemon 未運行

**症狀**:
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**解決方案**:
```bash
# Linux
sudo systemctl start docker
sudo systemctl enable docker

# macOS/Windows
# 啟動 Docker Desktop 應用程式

# 驗證
docker ps
```

### 問題 3: 記憶體不足

**症狀**:
```
Error: OCI runtime create failed: container_linux.go: starting container process caused: process_linux.go
```

**診斷**:
```bash
# 檢查 Docker 記憶體限制
docker info | grep Memory

# 檢查系統記憶體
free -h
```

**解決方案**:
```bash
# 增加 Docker 記憶體限制（Docker Desktop）
# Settings -> Resources -> Memory -> 調整至 8GB+

# 或減少服務資源需求
# docker-compose.yml
deploy:
  resources:
    limits:
      memory: 512M  # 原 2G
```

---

## 資料庫問題

### 問題 1: PostgreSQL 連接被拒絕

**症狀**:
```
psycopg2.OperationalError: could not connect to server: Connection refused
```

**診斷**:
```bash
# 1. 檢查 PostgreSQL 是否運行
docker-compose ps postgres

# 2. 檢查健康狀態
docker inspect --format='{{.State.Health.Status}}' postgres

# 3. 查看日誌
docker-compose logs postgres
```

**解決方案**:

方案 A: 等待服務啟動
```bash
# PostgreSQL 需要時間初始化
sleep 30
docker-compose ps postgres
```

方案 B: 重啟服務
```bash
docker-compose restart postgres
```

方案 C: 重建容器
```bash
docker-compose down
docker-compose up -d postgres
```

### 問題 2: 資料庫認證失敗

**症狀**:
```
FATAL: password authentication failed for user "sectools"
```

**診斷**:
```bash
# 檢查環境變數
docker-compose exec postgres env | grep POSTGRES

# 檢查 .env 檔案
cat .env | grep DB_PASSWORD
```

**解決方案**:
```bash
# 1. 確認密碼正確
docker-compose exec postgres psql -U sectools -d security -c "SELECT 1;"

# 2. 重設密碼
docker-compose exec postgres psql -U postgres -c \
    "ALTER USER sectools WITH PASSWORD 'new_password';"

# 3. 更新 .env
echo "DB_PASSWORD=new_password" >> .env
```

### 問題 3: 資料庫磁碟空間不足

**症狀**:
```
ERROR: could not write to file: No space left on device
```

**診斷**:
```bash
# 檢查磁碟空間
df -h

# 檢查 Docker 卷大小
docker system df -v
```

**解決方案**:
```bash
# 1. 清理舊資料
docker exec -it postgres psql -U sectools -d security -c \
    "DELETE FROM scan_findings WHERE discovered_at < NOW() - INTERVAL '90 days';"

# 2. VACUUM 回收空間
docker exec -it postgres psql -U sectools -d security -c "VACUUM FULL;"

# 3. 清理 Docker 系統
docker system prune -a --volumes
```

---

## 網路連通性問題

### 問題 1: 容器間無法通訊

**症狀**:
```
curl: (7) Failed to connect to postgres port 5432: Connection refused
```

**診斷**:
```bash
# 1. 檢查容器是否在同一網路
docker network inspect security_net

# 2. 測試 DNS 解析
docker exec scanner-nuclei nslookup postgres

# 3. 測試端口連通性
docker exec scanner-nuclei nc -zv postgres 5432
```

**解決方案**:
```yaml
# 確保所有服務在同一網路
services:
  postgres:
    networks:
      - security_net
  
  scanner:
    networks:
      - security_net

networks:
  security_net:
    driver: bridge
```

### 問題 2: 無法訪問外網

**症狀**:
```
Could not resolve host: github.com
```

**診斷**:
```bash
# 測試外網連通性
docker exec scanner-nuclei ping -c 3 8.8.8.8
docker exec scanner-nuclei curl -I https://www.google.com
```

**解決方案**:
```yaml
# 設定自訂 DNS
services:
  scanner:
    dns:
      - 8.8.8.8
      - 1.1.1.1
```

### 問題 3: Traefik 無法路由

**症狀**:
訪問 `http://localhost` 回傳 404

**診斷**:
```bash
# 檢查 Traefik 配置
docker-compose logs traefik

# 檢查路由規則
curl http://localhost:8080/api/http/routers
```

**解決方案**:
```yaml
# 確保服務有正確的標籤
services:
  web-ui:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webui.rule=Host(`localhost`)"
      - "traefik.http.services.webui.loadbalancer.server.port=8080"
```

---

## 掃描問題

### 問題 1: Nuclei 掃描無結果

**可能原因**:
1. 目標無漏洞
2. 範本過時
3. 速率限制觸發
4. 目標封鎖

**解決方案**:
```bash
# 1. 更新範本
docker-compose run --rm scanner-nuclei nuclei -update-templates

# 2. 降低速率
docker-compose run --rm scanner-nuclei \
    nuclei -u https://example.com -rate-limit 50

# 3. 使用測試目標
docker-compose run --rm scanner-nuclei \
    nuclei -u https://scanme.nmap.org
```

### 問題 2: Nmap 掃描權限錯誤

**症狀**:
```
You requested a scan type which requires root privileges
```

**解決方案**:
```yaml
# 添加必要的 capability
services:
  nmap:
    cap_add:
      - NET_RAW
      - NET_ADMIN
```

### 問題 3: 掃描結果未入庫

**診斷**:
```bash
# 1. 檢查掃描輸出檔案
docker-compose exec scanner-nuclei ls -la /results/

# 2. 檢查 Parser 運行狀態
docker-compose ps parser-nuclei

# 3. 手動執行 Parser
docker-compose run --rm parser-nuclei \
    python /app/parse.py /results/nuclei-20251017.json
```

---

## 效能問題

### 問題 1: CPU 使用率 100%

**診斷**:
```bash
# 查看容器資源使用
docker stats

# 查看系統負載
top
htop
```

**解決方案**:
```bash
# 1. 限制並發數
# .env
SCAN_CONCURRENCY=5

# 2. 限制容器 CPU
# docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '0.5'
```

### 問題 2: 記憶體洩漏

**症狀**:
記憶體使用持續增長

**診斷**:
```bash
# 監控記憶體使用
docker stats --no-stream

# 查看容器記憶體詳情
docker inspect -f '{{.HostConfig.Memory}}' postgres
```

**解決方案**:
```bash
# 定期重啟服務
0 3 * * * cd /opt/Security-and-Infrastructure-tools-Set/Make_Files && make restart
```

### 問題 3: 資料庫查詢慢

**診斷**:
```sql
-- 查看慢查詢
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 查看索引使用情況
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

**解決方案**:
```sql
-- 添加缺失的索引
CREATE INDEX idx_missing ON scan_findings(column_name);

-- ANALYZE 更新統計資訊
ANALYZE scan_findings;

-- VACUUM 清理
VACUUM ANALYZE scan_findings;
```

---

## 資料問題

### 問題 1: 資料不一致

**症狀**:
掃描結果與實際不符

**診斷**:
```sql
-- 檢查孤立記錄
SELECT * FROM scan_findings
WHERE scan_job_id NOT IN (SELECT id FROM scan_jobs);

-- 檢查重複記錄
SELECT host, port, COUNT(*)
FROM scan_findings
GROUP BY host, port
HAVING COUNT(*) > 1;
```

**解決方案**:
```sql
-- 清理孤立記錄
DELETE FROM scan_findings
WHERE scan_job_id NOT IN (SELECT id FROM scan_jobs);

-- 去重
DELETE FROM scan_findings a USING scan_findings b
WHERE a.id < b.id
AND a.host = b.host
AND a.port = b.port;
```

### 問題 2: 資料遺失

**恢復方案**:
```bash
# 1. 檢查備份
ls -lh /backups/

# 2. 還原最近的備份
docker-compose exec -T postgres psql -U sectools security < /backups/latest.sql

# 3. 驗證資料
docker exec -it postgres psql -U sectools -d security -c \
    "SELECT COUNT(*) FROM scan_jobs;"
```

---

## 權限問題

### 問題 1: Volume 權限錯誤

**症狀**:
```
Permission denied: '/results/scan.json'
```

**解決方案**:
```bash
# 修改 volume 權限
sudo chown -R $(id -u):$(id -g) ./scan_results
sudo chmod -R 755 ./scan_results
```

### 問題 2: Docker Socket 權限

**症狀**:
```
permission denied while trying to connect to the Docker daemon socket
```

**解決方案**:
```bash
# 將使用者加入 docker 群組
sudo usermod -aG docker $USER
newgrp docker

# 驗證
docker ps
```

---

## 日誌分析

### 有用的日誌命令

```bash
# 查看所有服務日誌
docker-compose logs

# 查看特定服務日誌
docker-compose logs -f postgres

# 查看最近 100 行
docker-compose logs --tail=100 scanner-nuclei

# 搜尋錯誤
docker-compose logs | grep -i error

# 導出日誌
docker-compose logs > debug.log 2>&1
```

---

## 獲取幫助

如果以上方案都無法解決問題：

1. **收集診斷資訊**:
```bash
# 執行診斷腳本
bash scripts/diagnose.sh > diagnosis.txt
```

2. **提交 Issue**:
- 訪問 [GitHub Issues](https://github.com/your-username/Security-and-Infrastructure-tools-Set/issues)
- 附上診斷資訊
- 描述重現步驟

3. **社群支援**:
- [GitHub Discussions](https://github.com/your-username/Security-and-Infrastructure-tools-Set/discussions)
- [Discord 頻道](https://discord.gg/xxx)

---

**文件版本**: 1.0  
**最後更新**: 2025-10-17

