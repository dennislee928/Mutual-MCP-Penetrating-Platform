# 安全測試

本目錄包含安全修復的驗證測試。

## 執行測試

### 前置需求

```bash
pip install requests
```

### 執行所有測試

```bash
cd tests/security
python test_security_fixes.py
```

### 設定環境變數

```bash
# HexStrike AI 服務 URL
export HEXSTRIKE_URL=http://localhost:8888

# API Key（如果啟用授權）
export HEXSTRIKE_API_KEY=your-api-key-here

# 環境類型
export ENVIRONMENT=development  # 或 production
```

## 測試類別

### 1. Command Injection Tests
驗證命令注入修復是否有效：
- Nmap 命令注入阻擋
- Gobuster 命令注入阻擋
- 其他工具的命令注入阻擋

### 2. Path Traversal Tests
驗證路徑穿越修復是否有效：
- 阻擋 `../` 路徑
- 阻擋絕對路徑
- 阻擋 URL 編碼的路徑穿越

### 3. Auth Middleware Tests
驗證授權中間件是否正常工作：
- 缺少 API Key 被拒絕
- 無效 API Key 被拒絕
- Rate Limiting 生效

### 4. SSL Verification Tests
驗證 SSL 驗證是否預設啟用

### 5. Docker Security Tests
驗證 Docker 文件的安全配置：
- 固定版本標籤
- HEALTHCHECK 存在

### 6. Kubernetes Security Tests
驗證 K8s 配置的安全性：
- securityContext 存在
- allowPrivilegeEscalation = false
- readOnlyRootFilesystem = true
- capabilities dropped

### 7. Hardcoded Credentials Tests
驗證沒有硬編碼憑證：
- Go config 有驗證
- Grafana 使用環境變數

## 預期結果

所有測試應該通過（PASS）：

```
test_backend_dockerfile_uses_fixed_version ... OK
test_command_injection_blocked ... OK
test_frontend_dockerfile_has_healthcheck ... OK
test_go_config_validates_default_passwords ... OK
test_grafana_uses_env_vars ... OK
test_invalid_api_key_rejected ... OK
test_loadbalancer_has_ip_restriction ... OK
test_missing_api_key_rejected ... OK
test_nmap_command_injection_blocked ... OK
test_parser_amass_has_security_context ... OK
test_path_traversal_blocked ... OK
test_rate_limiting ... OK
test_ssl_verification_enabled_by_default ... OK
```

## 故障排除

### 測試失敗

如果測試失敗，檢查：
1. 服務是否正在運行
2. 環境變數是否正確設定
3. 網路連接是否正常
4. API Key 是否有效

### 跳過測試

某些測試可能需要特定環境：
- 授權測試需要 `API_AUTH_ENABLED=true`
- Rate limiting 測試需要服務正在運行

## 手動測試

### 測試命令注入

```bash
# 嘗試注入命令（應該失敗）
curl -X POST http://localhost:8888/api/tools/nmap \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $HEXSTRIKE_API_KEY" \
  -d '{"target": "8.8.8.8; whoami"}'
```

### 測試路徑穿越

```bash
# 嘗試訪問敏感文件（應該失敗）
curl "http://localhost:8888/api/files?path=../../../etc/passwd" \
  -H "X-API-Key: $HEXSTRIKE_API_KEY"
```

### 測試授權

```bash
# 無 API Key（應該 401）
curl http://localhost:8888/api/tools/nmap

# 無效 API Key（應該 401）
curl -H "X-API-Key: invalid" http://localhost:8888/api/tools/nmap
```

## 持續監控

建議：
1. 將這些測試加入 CI/CD 管道
2. 定期執行安全掃描（Snyk, SonarQube）
3. 監控審計日誌檔案
4. 定期更新依賴套件


