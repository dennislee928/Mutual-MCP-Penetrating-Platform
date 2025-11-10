# 統一安全・基礎設施・AI 滲透測試平台  
**Unified Security, Infrastructure & AI-Driven Offensive Platform**

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.24+-blue.svg)](https://golang.org)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://docker.com)
[![MCP](https://img.shields.io/badge/MCP-Compatible-purple.svg)](#ai--mcp-子系統)
[![Security Tools](https://img.shields.io/badge/Security%20Tools-150%2B-brightgreen.svg)](#安全工具武器庫-150)

繁體中文 | [English](README.md)

---

## 1. 概述

這是一個把「雲原生安全與基礎設施管理」和「AI/MCP 自動化滲透測試框架」合在同一個專案裡的統一平台：

1. **防禦面 / SecOps 面（原 WHY_MR_ANDERSON_WHY）**
   - IDS/IPS、AI/ML 威脅偵測
   - 多雲部署（Cloudflare / OCI / IBM Cloud / K8s）
   - 監控、可觀測性 (Prometheus, Grafana, Loki)
   - Go 後端 + React 前端 + Python AI/量子模組
2. **攻擊面 / Offensive-AI 面（原 HexStrike AI MCP v7.0）**
   - 150+ 滲透/偵察/雲端/CTF 工具打包
   - MCP (Model Context Protocol) 讓 GPT / Claude / Cursor 能「直接叫工具」
   - LLM 增強決策引擎 (LLMEnhancedDecisionEngine)
   - RAG 安全知識庫、AI 報表生成
   - Docker 一鍵跑起來、也能放 VPS / Render / Railway

合併後，你可以想成：**這是一個能監看你的基礎設施，必要時又能自動叫 AI 去打授權目標、產報告的安全控制平面**。

---

## 2. 主要能力

- 🛡️ **雲原生安全控制**：IDS/IPS、漏洞掃描、零信任、mTLS、SAST、合規 (GDPR / SOC2 / ISO27001 對齊)
- 🤖 **AI 威脅偵測**：Python 3.11+ 模型、即時資料流監控、行為異常
- 🧠 **LLM/MCP 滲透測試**：GPT/Claude 透過 MCP 直接叫 Nmap、Nuclei、sqlmap、wpscan…
- 🔬 **量子計算整合**：IBM Quantum、QKD、PQ Crypto
- 🌐 **多雲部署**：Cloudflare Workers、OCI 永久免費層、IBM Cloud Lite
- 📊 **可觀測性**：Prometheus + Grafana + Loki + Tracing
- ⚙️ **基礎設施即程式碼**：Docker, K8s manifests, Terraform, Argo CD, Harness
- 🧩 **優雅降級**：沒 OpenAI key 就回到規則型決策引擎
- 📦 **150+ 安全工具武器庫**：網路、Web、雲、Binary、CTF、OSINT 一次打包

---

## 3. 平台總體架構

```text
┌──────────────────────────────────────────────┐
│         Unified Security & AI Platform       │
└──────────────────────────────────────────────┘
                     │
     ┌───────────────┴────────────────┐
     │                                │
┌────▼──────┐                    ┌────▼─────────────────────────┐
│  防禦面    │                    │   攻擊面 / AI-MCP 子系統     │
│  (Go/React)│                    │   (HexStrike AI v7.0)        │
└────┬──────┘                    └────┬─────────────────────────┘
     │                                │
     │                                │
     ▼                                ▼
K8s / Docker / Multi-Cloud     150+ Security Tools, LLM, RAG
Prometheus / Grafana           MCP Server (給 GPT / Claude 用)
Loki / Tracing                 /api/intelligence/... endpoints
```

---

## 4. 專案結構（合併版建議）

```text
unified-sec-ai-platform/
├── src/
│   ├── backend/              # Go 核心服務 (原統一安全平台)
│   ├── frontend/             # React / Next.js 前端
│   ├── ai-quantum/           # Python AI & 量子整合
│   └── hexstrike-ai/         # ← 原 HexStrike AI MCP v7.0 (Offensive)
│       ├── mcp/
│       ├── core/
│       └── docs/
├── infrastructure/
│   ├── docker/
│   ├── kubernetes/
│   └── cloud-configs/
├── cicd/
│   ├── argocd/
│   ├── buddy/
│   └── harness/
├── docs/
│   ├── architecture/
│   ├── deployment/
│   ├── mcp-integration.md    # ← 新增：說明怎麼讓 GPT/Claude 接進來
│   └── api-reference.md
└── tests/
```

> 重點是把 HexStrike 放進 `src/hexstrike-ai/` 當成「進階 offensive 模組」，而不是跟你的 Go API 混在同一層，這樣部署/打包可以分開。

---

## 5. 快速開始

### 5.1 前置需求

- Docker 20.10+ / Docker Compose 2.0+
- Go 1.24+
- Python 3.11+
- Node.js 18+
- （可選）OpenAI / Anthropic API key（要用 LLM 增強決策時）

### 5.2 一鍵啟動（防禦面＋可觀測性）

```bash
git clone <your-repo-url>
cd unified-sec-ai-platform

cp .env.example .env   # 填 DB / Redis / Cloud Token
cd infrastructure/docker
docker-compose up -d
```

啟動後預設服務（依你原本的）：

- 前端 UI: http://localhost:3001
- 後端 API: http://localhost:3001/api/v1
- Swagger: http://localhost:3001/swagger
- AI/量子 API: http://localhost:8000
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

### 5.3 啟動 AI/MCP 滲透測試子系統（HexStrike 部分）

```bash
cd src/hexstrike-ai
python3 -m venv venv
source venv/bin/activate   # Windows 用 venv\Scripts\activate
pip install -r requirements.txt

# 啟動 MCP/AI server (預設 8888)
python3 hexstrike_server.py --port 8888
```

健康檢查：

```bash
curl http://localhost:8888/health
```

---

## 6. AI / MCP 子系統

這一塊就是你原本的 **HexStrike AI MCP Agents v7.0**，我直接整段保留概念，只是接到你這個大平台底下。

### 6.1 三層 AI 架構（簡版）

1. **MCP 通訊層**：Claude / GPT / Cursor → MCP → HexStrike MCP Server
2. **AI 決策層**：IntelligentDecisionEngine + LLMEnhancedDecisionEngine (有 key 就走 LLM)
3. **工具執行層**：150+ 安全工具、攻擊鏈建構、報告生成

### 6.2 主要 API

```text
GET  /health
POST /api/intelligence/analyze-target
POST /api/intelligence/select-tools
POST /api/intelligence/optimize-parameters
POST /api/intelligence/llm-enhanced-scan   # v7.0 新增
POST /api/intelligence/rag-search          # v7.0 新增
```

範例：

```bash
curl -X POST http://localhost:8888/api/intelligence/llm-enhanced-scan   -H "Content-Type: application/json"   -d '{
    "target": "https://example.com",
    "objective": "bug_bounty"
  }'
```

---

## 7. 安全工具武器庫 (150+)

本平台內建 150+ 專業安全工具，涵蓋 **網路偵察、Web 安全、雲端與 K8s 安全、Binary/RE、CTF/Forensics、Bug Bounty/OSINT**。  
詳細清單請參見 `docs/security-tools.md`。

---

## 8. 監控與可觀測性

- Prometheus 指標收集
- Grafana 儀表板
- Loki 日誌聚合
- 分散式追蹤
- WebSocket 即時事件 → 可顯示 AI/MCP 任務進度

> 建議：把 AI/MCP 掃描結果也回寫到後端，前端 Dashboard 就能同時看到「基礎設施狀態」與「近期攻擊/掃描任務」。

---

## 9. 部署

### 9.1 本地開發

```bash
# Go 後端
cd src/backend
go run cmd/server/main.go

# React 前端
cd src/frontend
npm install
npm run dev

# AI/量子 (defensive ML)
cd src/ai-quantum
pip install -r requirements.txt
python main.py

# AI/MCP (offensive)
cd src/hexstrike-ai
python3 hexstrike_server.py
```

### 9.2 Docker / Kubernetes

- `infrastructure/docker/docker-compose.yml`：啟動主要服務
- `infrastructure/kubernetes/`：K8s manifest
- Offensive 子系統可在 K8s 跑成獨立 service，外部 GPT/Claude 透過 MCP 進來

### 9.3 雲端

- Cloudflare Workers / OCI / IBM Cloud → 依照原來部署文件
- Offensive 部分可直接用 Docker Hub image：`dennisleetw/hexstrike-ai:latest`

---

## 10. 安全性與合規

- ✅ 靜態加密敏感資料
- ✅ 服務間 mTLS
- ✅ API rate limit、DDoS 防護
- ✅ CI/CD SAST
- ✅ GDPR / SOC2 / ISO27001 對齊
- ✅ AI/MCP 操作需授權且全程記錄

⚠️ AI/MCP 滲透測試僅能用於**授權**目標（Bug Bounty / Red Team / 自家系統 / CTF）。請先取得書面授權。

---

## 11. 路線圖（合併版）

### 2025 Q1
- ✅ 統一專案結構（defense + offensive）
- ✅ 多雲部署
- ✅ 三個 CI/CD 平台
- ✅ LLM 增強決策引擎整合
- [ ] AI 掃描結果回寫到防禦面儀表板
- [ ] 擴展量子演算法

### 2025 Q2
- [ ] 行動端管理介面
- [ ] 多租戶 / MSP 模式
- [ ] MISP 威脅情報整合
- [ ] 250+ 安全工具擴充（原 HexStrike v7.1+）

---

## 12. 授權

本專案採用 **MIT License**，兩個原本 repo 的授權可合併沿用同一份 `LICENSE`。

---

## 13. 支援與貢獻

1. Fork 專案
2. 建立分支 `feature/<name>`
3. 建立 PR
4. 可針對：
   - 新 AI agent
   - 新安全工具整合
   - 前端 Dashboard 顯示 AI/MCP 任務
   - 新的雲端部署範例
