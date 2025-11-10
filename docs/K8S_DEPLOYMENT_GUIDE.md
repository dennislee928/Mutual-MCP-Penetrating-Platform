# 🚀 Kubernetes 服務部署指南

## 📋 部署前準備

### 1. 啟用 Docker Desktop Kubernetes

**重要**: 在執行部署之前，您需要先啟用 Docker Desktop Kubernetes：

1. 打開 **Docker Desktop**
2. 點擊右上角的 **Settings** (齒輪圖標)
3. 在左側選單中選擇 **Kubernetes**
4. 勾選 **Enable Kubernetes**
5. 點擊 **Apply & Restart**
6. 等待 Docker Desktop 重啟並啟動 Kubernetes (約 2-5 分鐘)

### 2. 驗證 Kubernetes 環境

```bash
# 檢查 kubectl 是否可用
kubectl version --client

# 切換到 Docker Desktop 上下文
kubectl config use-context docker-desktop

# 驗證集群連接
kubectl cluster-info
kubectl get nodes
```

## 🎮 部署方式

### 方式 1: 使用 PowerShell 腳本 (推薦)

```powershell
# 進入工具目錄
cd Make_Files

# 部署 Kubernetes 服務
powershell -ExecutionPolicy Bypass -File .\make.ps1 deploy-k8s

# 檢查服務狀態
powershell -ExecutionPolicy Bypass -File .\make.ps1 k8s-status

# 清理服務 (如需要)
powershell -ExecutionPolicy Bypass -File .\make.ps1 teardown-k8s
```

### 方式 2: 使用 Bash 腳本

```bash
# 給腳本執行權限
chmod +x scripts/deploy-k8s.sh
chmod +x scripts/teardown-k8s.sh

# 部署服務
./scripts/deploy-k8s.sh

# 清理服務 (如需要)
./scripts/teardown-k8s.sh
```

### 方式 3: 手動部署

```bash
# 1. 部署命名空間和配置
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml

# 2. 部署 ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f k8s/argocd-service.yaml

# 3. 部署 SecureCodeBox Operator
kubectl apply -f https://raw.githubusercontent.com/secureCodeBox/secureCodeBox/main/operator/crds/cascading-rule.yaml
kubectl apply -f https://raw.githubusercontent.com/secureCodeBox/secureCodeBox/main/operator/crds/scan-type.yaml
kubectl apply -f https://raw.githubusercontent.com/secureCodeBox/secureCodeBox/main/operator/crds/scan.yaml
kubectl apply -f k8s/securecodebox-rbac.yaml
kubectl apply -f k8s/securecodebox-operator.yaml

# 4. 部署 Parser 服務
kubectl apply -f k8s/parser-nuclei.yaml
kubectl apply -f k8s/parser-amass.yaml
```

## 🌐 服務訪問

### ArgoCD
- **URL**: http://localhost:30081
- **用戶名**: admin
- **密碼**: 運行以下命令獲取
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

### Parser 服務測試
```bash
# Nuclei Parser
kubectl port-forward -n security-tools svc/parser-nuclei 8080:8080
curl http://localhost:8080/health

# AMASS Parser
kubectl port-forward -n security-tools svc/parser-amass 8081:8080
curl http://localhost:8081/health
```

## 📊 監控和日誌

### 查看服務狀態
```bash
# 查看所有 Pod
kubectl get pods -n security-tools
kubectl get pods -n argocd

# 查看服務
kubectl get services -n security-tools
kubectl get services -n argocd

# 查看部署
kubectl get deployments -n security-tools
kubectl get deployments -n argocd
```

### 查看日誌
```bash
# SecureCodeBox Operator
kubectl logs -n security-tools -l app=securecodebox-operator

# Nuclei Parser
kubectl logs -n security-tools -l app=parser-nuclei

# AMASS Parser
kubectl logs -n security-tools -l app=parser-amass

# ArgoCD Server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## 🔧 故障排除

### 常見問題

1. **kubectl 無法連接集群**
   ```bash
   # 檢查 Docker Desktop Kubernetes 是否啟用
   kubectl config get-contexts
   
   # 切換到正確的上下文
   kubectl config use-context docker-desktop
   ```

2. **Pod 無法啟動**
   ```bash
   # 查看 Pod 詳細信息
   kubectl describe pod <pod-name> -n security-tools
   
   # 查看事件
   kubectl get events -n security-tools --sort-by='.lastTimestamp'
   ```

3. **Parser 無法連接 PostgreSQL**
   - 確保 Docker Compose 中的 PostgreSQL 正在運行
   - 檢查 ConfigMap 中的 `POSTGRES_HOST` 設置
   - 驗證 Secret 中的密碼是否正確

4. **ArgoCD 無法訪問**
   ```bash
   # 檢查 ArgoCD Server 狀態
   kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
   
   # 檢查 Service
   kubectl get svc -n argocd
   
   # 手動端口轉發
   kubectl port-forward -n argocd svc/argocd-server 8080:443
   ```

## 🧹 清理

### 完全清理
```bash
# 使用腳本清理
./scripts/teardown-k8s.sh

# 或手動清理
kubectl delete namespace security-tools
kubectl delete namespace argocd
kubectl delete crd scans.execution.securecodebox.io
kubectl delete crd scantypes.execution.securecodebox.io
kubectl delete crd cascadingrules.execution.securecodebox.io
```

## 📝 注意事項

1. **資源需求**: 確保 Docker Desktop 有足夠的 CPU 和記憶體分配
2. **網路連接**: Kubernetes 服務需要能訪問 Docker Compose 中的 PostgreSQL
3. **持久化**: 清理操作會刪除所有數據，請提前備份重要信息
4. **版本兼容**: 確保 kubectl 版本與 Kubernetes 集群版本兼容

## 🎯 下一步

部署完成後，您可以：

1. 使用 ArgoCD 進行 GitOps 部署
2. 通過 SecureCodeBox Operator 管理掃描工作流
3. 使用 Parser 服務處理掃描結果
4. 整合現有的 Docker Compose 服務

---

**需要幫助？** 查看 `README.md` 或運行 `.\make.ps1 help` 獲取更多信息。

