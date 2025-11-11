# 📚 Terraform IaC 文檔索引

快速導航到您需要的文檔。

---

## 🚀 新手入門

### 1. 第一次使用？
👉 [QUICKSTART.md](./QUICKSTART.md) - **5 分鐘快速開始**
- 3 步驟開始部署
- 前置需求檢查
- 第一次部署指南

### 2. 需要詳細說明？
👉 [README.md](./README.md) - **完整使用手冊**
- 模組詳細說明
- 所有功能介紹
- 進階配置選項

### 3. 快速查找命令？
👉 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - **一頁式參考**
- 所有常用命令
- 快速配置範例
- 故障排除速查

---

## 📖 深入學習

### 完整實作指南
👉 [TERRAFORM_COMPLETE.md](./TERRAFORM_COMPLETE.md)
- 完整技術細節
- 架構設計說明
- 最佳實踐
- 擴展指南

### 實作總結
👉 [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)
- 完成情況總覽
- 統計數據
- 成功指標
- 商業價值

### 待辦清單
👉 [TODO.md](./TODO.md)
- 已完成功能
- 待實作功能
- 優先級說明
- 路線圖

---

## 🎯 按任務查找

### 部署相關
- **首次部署**: [QUICKSTART.md](./QUICKSTART.md)
- **環境部署**: [README.md](./README.md#環境配置)
- **CI/CD 部署**: [README.md](./README.md#ci-cd-整合)

### 配置相關
- **變數配置**: [terraform.tfvars.example](./terraform.tfvars.example)
- **環境配置**: [environments/](./environments/)
- **模組配置**: [modules/](./modules/)

### 維護相關
- **更新映像**: [README.md](./README.md#維護)
- **健康檢查**: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md#健康檢查)
- **故障排除**: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md#故障排除)

---

## 🛠️ 按工具查找

### Terraform 命令
👉 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md#terraform-基本命令)
- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform destroy`

### Make 命令
👉 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md#makefile-命令linuxmacos)
- `make help`
- `make init`
- `make apply`
- `make health-check`

### PowerShell 腳本
👉 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md#powershell-命令windows)
- `.\deploy.ps1`
- `.\deploy.ps1 -Action plan`
- `.\deploy.ps1 -Action health-check`

---

## 🏗️ 按模組查找

### cloudflare-worker 模組
👉 [modules/cloudflare-worker/](./modules/cloudflare-worker/)
- Worker 部署
- 環境變數配置
- Durable Objects

### cloudflare-container 模組
👉 [modules/cloudflare-container/](./modules/cloudflare-container/)
- 容器管理
- 映像推送
- 實例配置

---

## 📊 按環境查找

### Development
👉 [environments/dev/](./environments/dev/)
- 開發環境配置
- 低資源配置
- Debug 模式

### Production
👉 [environments/production/](./environments/production/)
- 生產環境配置
- 高可用配置
- 監控和日誌

---

## 💡 常見問題

### Q: 我應該從哪裡開始？
**A**: 從 [QUICKSTART.md](./QUICKSTART.md) 開始，5 分鐘即可完成首次部署。

### Q: 如何配置變數？
**A**: 參考 [terraform.tfvars.example](./terraform.tfvars.example)，複製並填入實際值。

### Q: 有沒有快速命令參考？
**A**: 查看 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)，一頁包含所有常用命令。

### Q: 如何部署到不同環境？
**A**: 參考 [README.md](./README.md#環境特定部署) 的環境配置章節。

### Q: 遇到錯誤怎麼辦？
**A**: 查看 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md#故障排除) 的故障排除部分。

---

## 📁 檔案結構速查

```
terraform/
├── 📖 文檔
│   ├── README.md                      ← 主文檔
│   ├── QUICKSTART.md                  ← 快速開始
│   ├── QUICK_REFERENCE.md             ← 命令參考
│   ├── TERRAFORM_COMPLETE.md          ← 完整指南
│   ├── IMPLEMENTATION_SUMMARY.md      ← 實作總結
│   ├── TODO.md                        ← 待辦清單
│   └── INDEX.md                       ← 本文件
│
├── ⚙️ 配置檔案
│   ├── providers.tf                   ← Provider 配置
│   ├── versions.tf                    ← 版本鎖定
│   ├── variables.tf                   ← 變數定義
│   ├── outputs.tf                     ← 輸出配置
│   ├── locals.tf                      ← 本地值
│   └── main.tf                        ← 主配置
│
├── 🛠️ 工具
│   ├── Makefile                       ← Make 命令
│   ├── deploy.ps1                     ← PowerShell 腳本
│   └── terraform.tfvars.example       ← 配置範例
│
├── 📦 模組
│   ├── modules/cloudflare-worker/     ← Worker 模組
│   └── modules/cloudflare-container/  ← 容器模組
│
└── 🌍 環境
    ├── environments/dev/              ← 開發環境
    └── environments/production/       ← 生產環境
```

---

## 🎯 推薦學習路徑

### 第 1 天：快速開始
1. 閱讀 [QUICKSTART.md](./QUICKSTART.md)
2. 完成首次部署
3. 執行健康檢查

### 第 2 天：深入了解
1. 閱讀 [README.md](./README.md)
2. 理解模組架構
3. 嘗試環境配置

### 第 3 天：實踐應用
1. 部署到不同環境
2. 自訂配置
3. 整合 CI/CD

### 第 4 天：進階主題
1. 閱讀 [TERRAFORM_COMPLETE.md](./TERRAFORM_COMPLETE.md)
2. 學習最佳實踐
3. 計畫擴展

---

## 🔗 外部資源

### 官方文檔
- [Terraform 官方文檔](https://www.terraform.io/docs)
- [Cloudflare Provider 文檔](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare Workers 文檔](https://developers.cloudflare.com/workers/)
- [Cloudflare Containers 文檔](https://developers.cloudflare.com/containers/)

### 工具
- [Terraform](https://www.terraform.io/)
- [Wrangler](https://developers.cloudflare.com/workers/wrangler/)
- [Docker](https://www.docker.com/)

### 社群
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core)
- [Cloudflare Community](https://community.cloudflare.com/)

---

## 💬 需要幫助？

1. **查看文檔**: 從上方索引找到相關文檔
2. **查看範例**: 檢查 `terraform.tfvars.example` 和 `environments/`
3. **運行幫助命令**: `make help` 或 `.\deploy.ps1 -Action help`
4. **搜尋文檔**: 使用 Ctrl+F 在文檔中搜尋關鍵字
5. **創建 Issue**: 在 GitHub 報告問題或提問

---

## ⭐ 快速連結

### 最常用的文檔
| 文檔 | 用途 | 時間 |
|------|------|------|
| [QUICKSTART.md](./QUICKSTART.md) | 快速開始 | 5 分鐘 |
| [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | 命令參考 | 隨時查閱 |
| [README.md](./README.md) | 完整手冊 | 30 分鐘 |

### 最常用的命令
```bash
make help               # 顯示所有命令
make init               # 初始化
make apply              # 部署
make health-check       # 健康檢查
```

### 最常用的檔案
- `terraform.tfvars` - 配置值（從 .example 複製）
- `Makefile` - 便捷命令
- `deploy.ps1` - Windows 部署腳本

---

**保存此索引頁面以便快速導航！** 🗺️

*最後更新: 2025-11-11*

