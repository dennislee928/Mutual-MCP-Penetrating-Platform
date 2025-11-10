# AI/量子安全服務

> 統一安全平台的 AI 威脅偵測與量子計算模組

## 📋 概述

本模組提供：

- 🤖 **AI 威脅偵測**：異常行為分析、惡意流量識別
- 🔬 **量子計算整合**：QKD 量子金鑰分發、後量子密碼學
- 📊 **實時監控**：持續分析安全事件並產生告警
- 🔗 **服務整合**：與 Go 後端和 HexStrike AI 整合

## 🚀 快速開始

### 安裝依賴

```bash
cd src/ai-quantum
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 啟動服務

```bash
# 開發模式
python -m uvicorn api.main:app --reload --port 8000

# 生產模式
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000
```

服務將在 http://localhost:8000 啟動

### 驗證

```bash
curl http://localhost:8000/health
```

## 📚 API 文件

啟動後訪問：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### 主要端點

#### AI 威脅偵測

```http
POST /api/ai/analyze          # 威脅分析
POST /api/ai/behavior         # 行為分析
GET  /api/ai/models/status    # 模型狀態
```

#### 量子計算

```http
POST /api/quantum/qkd/generate    # 生成量子金鑰
POST /api/quantum/pqcrypto        # 後量子密碼操作
GET  /api/quantum/status          # 量子服務狀態
GET  /api/quantum/random/{bits}   # 量子隨機數
```

## 🏗️ 專案結構

```
ai-quantum/
├── models/                   # AI/ML 模型
│   ├── threat_detection/     # 威脅偵測模型
│   └── quantum/              # 量子計算模組
├── services/                 # 業務邏輯服務
├── api/                      # FastAPI 應用
│   ├── main.py              # 主程式
│   ├── routes/              # 路由
│   └── schemas/             # Pydantic 模型
├── config/                   # 配置
│   └── settings.py          # 設定檔
├── requirements.txt         # 依賴
├── Dockerfile               # Docker 映像
└── README.md                # 本文件
```

## ⚙️ 配置

環境變數配置（.env）：

```env
# 伺服器
HOST=0.0.0.0
PORT=8000
DEBUG=False

# Go 後端
BACKEND_URL=http://localhost:3001

# HexStrike AI
HEXSTRIKE_URL=http://localhost:8888

# IBM Quantum（可選）
IBM_QUANTUM_TOKEN=your_token_here
IBM_QUANTUM_CHANNEL=ibm_quantum
IBM_QUANTUM_INSTANCE=ibm_qasm_simulator

# AI 模型
MODEL_PATH=./models
ANOMALY_THRESHOLD=0.7
THREAT_CONFIDENCE_THRESHOLD=0.6

# 日誌
LOG_LEVEL=INFO
LOG_FORMAT=json
```

## 🧪 測試

```bash
# 執行測試
pytest

# 測試覆蓋率
pytest --cov=. --cov-report=html
```

## 🐳 Docker 部署

```bash
# 建置映像
docker build -t ai-quantum-service:latest .

# 執行容器
docker run -p 8000:8000 --env-file .env ai-quantum-service:latest
```

## 📊 監控

服務暴露 Prometheus 指標於 `/metrics` 端點（如果啟用）。

## 🔐 安全性

- 所有敏感配置使用環境變數
- API 端點需要身份驗證（與 Go 後端整合）
- 量子金鑰使用安全通道傳輸
- 模型訓練資料需加密儲存

## 🤝 貢獻

請參閱根目錄的 `CONTRIBUTING.md`

## 📄 授權

MIT License


