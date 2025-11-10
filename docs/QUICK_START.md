# 🚀 Dennis Security And Infra Toolkit - 快速開始指南

## 📋 系統狀態

### ✅ 已啟動的核心服務
- **PostgreSQL**: `localhost:5432` (內部資料庫)
- **Vault**: <http://localhost:8200> (密鑰管理)
- **Traefik**: <http://localhost:8888> (HTTP), <https://localhost:8443> (HTTPS)
- **Traefik Dashboard**: <http://localhost:8090>
- **Web UI**: <http://localhost:8082>

### 🔧 可用的掃描工具
- **Nuclei**: 漏洞掃描器 (v3.4.10)
- **Nmap**: 網路掃描器
- **AMASS**: 攻擊面映射工具 (v4.2.0)
- **Burp Suite**: Web 應用安全測試
- **IntelOwl Nuclei**: 進階漏洞分析

## 🎮 快速使用

### Windows 用戶 (推薦)
```powershell
# 進入工具目錄
cd Make_Files

# 查看所有命令
powershell -ExecutionPolicy Bypass -File .\make.ps1 help

# 啟動所有服務
powershell -ExecutionPolicy Bypass -File .\make.ps1 up

# 執行掃描
powershell -ExecutionPolicy Bypass -File .\make.ps1 scan-nuclei -Target https://example.com
powershell -ExecutionPolicy Bypass -File .\make.ps1 scan-nmap -Target 192.168.1.1
powershell -ExecutionPolicy Bypass -File .\make.ps1 scan-amass -Target example.com

# 查看服務狀態
powershell -ExecutionPolicy Bypass -File .\make.ps1 ps
```

### Linux/macOS 用戶
```bash
# 使用 Makefile
make help
make up
make scan-nuclei TARGET=https://example.com
make scan-nmap TARGET=192.168.1.1
```

### 直接使用 Docker Compose
```bash
cd Docker/compose

# 啟動核心服務
docker-compose up -d

# 執行掃描
docker-compose run --rm scanner-nuclei nuclei -u https://example.com
docker-compose run --rm nmap nmap -sV scanme.nmap.org
docker-compose run --rm scanner-amass amass enum -d example.com
```

## 🔍 掃描範例

### 1. Nuclei 漏洞掃描
```bash
# 基本掃描
nuclei -u https://target.com

# 使用特定模板
nuclei -u https://target.com -t cves/

# 輸出到文件
nuclei -u https://target.com -o results.json
```

### 2. Nmap 網路掃描
```bash
# 基本端口掃描
nmap -sV target.com

# 全面掃描
nmap -A -T4 target.com

# 掃描特定端口
nmap -p 80,443,22 target.com
```

### 3. AMASS 子域名枚舉
```bash
# 基本枚舉
amass enum -d target.com

# 被動枚舉
amass enum -passive -d target.com

# 輸出到文件
amass enum -d target.com -o results.txt
```

## 📊 結果查看

### 掃描結果位置
- **Volume**: `dennis-security-infra-toolkit_scan_results`
- **本地路徑**: Docker volumes 中
- **Web UI**: <http://localhost:8082>

### 查看掃描結果
```bash
# 查看 volume 內容
docker volume inspect dennis-security-infra-toolkit_scan_results

# 進入容器查看結果
docker run --rm -v dennis-security-infra-toolkit_scan_results:/results alpine ls -la /results
```

## 🛠️ 進階配置

### 環境變數
創建 `.env` 文件：
```bash
DB_PASSWORD=your_secure_password
VAULT_TOKEN=your_vault_token
```

### 自定義掃描
編輯 `Docker/compose/docker-compose.yml` 添加新的掃描工具：
```yaml
scanner-custom:
  image: your-scanner:latest
  volumes:
    - scan_results:/results
  networks:
    - security_net
  profiles:
    - scanner
```

## 🆘 故障排除

### 常見問題
1. **端口衝突**: 修改 `docker-compose.yml` 中的端口映射
2. **權限問題**: 確保 Docker 有足夠權限
3. **網路問題**: 檢查防火牆設置

### 日誌查看
```bash
# 查看所有服務日誌
docker-compose logs

# 查看特定服務日誌
docker-compose logs postgres
docker-compose logs vault
```

### 重置環境
```bash
# 停止所有服務並清理
docker-compose down -v
docker system prune -f

# 重新啟動
docker-compose up -d
```

## 📚 更多資源

- **完整文檔**: `README.md`
- **工具列表**: `TOOLS.md`
- **架構說明**: `ARCHITECTURE.md`
- **範例腳本**: `examples/` 目錄

---

🎉 **恭喜！您的 Dennis Security And Infra Toolkit 已準備就緒！**
