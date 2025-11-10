# 開發者指南

> 本文件提供擴展和自訂專案的完整指南

## 目錄

- [開發環境設定](#開發環境設定)
- [專案結構](#專案結構)
- [添加新掃描工具](#添加新掃描工具)
- [自訂 Parser](#自訂-parser)
- [擴展 API](#擴展-api)
- [測試指南](#測試指南)
- [貢獻流程](#貢獻流程)

---

## 開發環境設定

### 工具需求

```bash
# 開發工具
- Docker Desktop 20.10+
- Docker Compose 2.0+
- Git
- 程式碼編輯器（VS Code 推薦）
- Make
- curl / httpie（API 測試）
- jq（JSON 處理）
```

### VS Code 推薦擴展

```json
{
  "recommendations": [
    "ms-azuretools.vscode-docker",
    "ms-python.python",
    "golang.go",
    "hashicorp.terraform",
    "redhat.vscode-yaml",
    "ms-vscode.makefile-tools",
    "esbenp.prettier-vscode"
  ]
}
```

---

## 專案結構

```
Security-and-Infrastructure-tools-Set/
├── Docker/
│   ├── compose/
│   │   └── docker-compose.yml       # 主要編排檔案
│   ├── images/                      # 自訂 Dockerfile
│   │   ├── scanner-custom/
│   │   │   └── Dockerfile
│   │   └── parser-custom/
│   │       └── Dockerfile
│   └── configs/                     # 服務配置檔
│       ├── traefik/
│       ├── vault/
│       └── prometheus/
├── Make_Files/
│   └── Makefile                     # Make 命令定義
├── init_scripts/
│   ├── 01-init-sql                  # 資料庫初始化
│   └── 02-custom-tables.sql         # 自訂表結構
├── scripts/                         # 實用腳本
│   ├── parsers/                     # 解析器腳本
│   │   ├── nuclei_parser.py
│   │   └── custom_parser.py
│   ├── backup.sh                    # 備份腳本
│   └── health-check.sh              # 健康檢查
├── docs/                            # 文件
│   ├── zh-TW/
│   └── en/
├── examples/                        # 使用範例
│   ├── scan-examples.sh
│   └── query-examples.sql
├── tests/                           # 測試檔案
│   ├── unit/
│   └── integration/
├── .env.template                    # 環境變數範本
├── .gitignore
├── README.md
└── LICENSE
```

---

## 添加新掃描工具

### 範例：整合 ZAP (OWASP Zed Attack Proxy)

#### 步驟 1: 研究工具

```bash
# 測試 Docker 映像
docker run --rm owasp/zap2docker-stable zap-cli --help

# 了解輸出格式
docker run --rm owasp/zap2docker-stable zap-baseline.py -t https://example.com
```

#### 步驟 2: 添加到 docker-compose.yml

```yaml
# Docker/compose/docker-compose.yml
services:
  scanner-zap:
    image: owasp/zap2docker-stable:latest
    volumes:
      - scan_results:/zap/wrk
    networks:
      - security_net
    command: ["zap-cli", "--help"]
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
```

#### 步驟 3: 添加 Makefile 命令

```makefile
# Make_Files/Makefile
scan-zap:
	@echo "Running ZAP scan on $(TARGET)..."
	docker-compose run --rm scanner-zap \
		zap-baseline.py -t $(TARGET) \
		-J /zap/wrk/zap-$(shell date +%Y%m%d-%H%M%S).json \
		-r /zap/wrk/zap-$(shell date +%Y%m%d-%H%M%S).html
	@echo "Scan complete. Results in scan_results/"
```

#### 步驟 4: 創建資料庫表

```sql
-- init_scripts/02-zap-tables.sql
CREATE TABLE IF NOT EXISTS zap_results (
    id SERIAL PRIMARY KEY,
    scan_job_id INTEGER REFERENCES scan_jobs(id) ON DELETE CASCADE,
    alert_name VARCHAR(255) NOT NULL,
    risk VARCHAR(20) NOT NULL,  -- High, Medium, Low, Informational
    confidence VARCHAR(20) NOT NULL,
    url VARCHAR(500) NOT NULL,
    parameter VARCHAR(255),
    attack VARCHAR(255),
    evidence TEXT,
    solution TEXT,
    reference TEXT,
    cwe_id INTEGER,
    wasc_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_zap_risk ON zap_results(risk);
CREATE INDEX idx_zap_scan_job ON zap_results(scan_job_id);
```

#### 步驟 5: 創建 Parser

```python
#!/usr/bin/env python3
# scripts/parsers/zap_parser.py

import json
import psycopg2
import os
from datetime import datetime

def parse_zap_result(json_file):
    """解析 ZAP JSON 輸出"""
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # 連接資料庫
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'postgres'),
        database=os.getenv('DB_NAME', 'security'),
        user=os.getenv('DB_USER', 'sectools'),
        password=os.getenv('DB_PASSWORD')
    )
    cursor = conn.cursor()
    
    # 創建掃描任務
    cursor.execute("""
        INSERT INTO scan_jobs (scan_type, target, status, started_at, completed_at)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id
    """, ('zap', data.get('@target'), 'completed', datetime.now(), datetime.now()))
    
    scan_job_id = cursor.fetchone()[0]
    
    # 解析每個 alert
    for site in data.get('site', []):
        for alert in site.get('alerts', []):
            # 插入 zap_results
            cursor.execute("""
                INSERT INTO zap_results (
                    scan_job_id, alert_name, risk, confidence,
                    url, parameter, attack, evidence, solution, reference, cwe_id, wasc_id
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                scan_job_id,
                alert.get('name'),
                alert.get('riskdesc', '').split()[0],  # "High (Medium)" -> "High"
                alert.get('confidence'),
                alert.get('url'),
                alert.get('param'),
                alert.get('attack'),
                alert.get('evidence'),
                alert.get('solution'),
                alert.get('reference'),
                alert.get('cweid'),
                alert.get('wascid')
            ))
            
            # 同時插入通用 scan_findings 表
            cursor.execute("""
                INSERT INTO scan_findings (
                    scan_job_id, severity, title, description, host, evidence
                ) VALUES (%s, %s, %s, %s, %s, %s::jsonb)
            """, (
                scan_job_id,
                alert.get('riskdesc', '').split()[0].lower(),
                alert.get('name'),
                alert.get('desc'),
                alert.get('url'),
                json.dumps({'parameter': alert.get('param'), 'attack': alert.get('attack')})
            ))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print(f"✅ Parsed ZAP results. Scan Job ID: {scan_job_id}")

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 2:
        print("Usage: zap_parser.py <zap_json_file>")
        sys.exit(1)
    
    parse_zap_result(sys.argv[1])
```

#### 步驟 6: 創建 Parser 容器

```dockerfile
# Docker/images/parser-zap/Dockerfile
FROM python:3.11-alpine

RUN pip install --no-cache-dir psycopg2-binary

COPY scripts/parsers/zap_parser.py /app/parser.py

WORKDIR /app
CMD ["python", "parser.py"]
```

```yaml
# docker-compose.yml
services:
  parser-zap:
    build: ./Docker/images/parser-zap
    environment:
      DB_HOST: postgres
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - scan_results:/results
    networks:
      - security_net
```

#### 步驟 7: 測試整合

```bash
# 1. 重建服務
docker-compose build parser-zap

# 2. 啟動服務
docker-compose up -d

# 3. 執行 ZAP 掃描
make scan-zap TARGET=https://example.com

# 4. 手動執行 Parser（如果未自動化）
docker-compose run --rm parser-zap \
    python /app/parser.py /results/zap-20251017-103045.json

# 5. 查詢結果
docker exec -it postgres psql -U sectools -d security \
    -c "SELECT * FROM zap_results ORDER BY id DESC LIMIT 5;"
```

---

## 自訂 Parser

### Parser 開發模板

```python
#!/usr/bin/env python3
# scripts/parsers/template_parser.py

import json
import psycopg2
import os
from datetime import datetime
from typing import Dict, List, Any

class ScanParser:
    """通用掃描結果解析器基類"""
    
    def __init__(self):
        self.conn = self.connect_db()
        self.cursor = self.conn.cursor()
    
    def connect_db(self):
        """連接 PostgreSQL"""
        return psycopg2.connect(
            host=os.getenv('DB_HOST', 'postgres'),
            database=os.getenv('DB_NAME', 'security'),
            user=os.getenv('DB_USER', 'sectools'),
            password=os.getenv('DB_PASSWORD')
        )
    
    def create_scan_job(self, scan_type: str, target: str) -> int:
        """創建掃描任務記錄"""
        self.cursor.execute("""
            INSERT INTO scan_jobs (scan_type, target, status, started_at, completed_at)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
        """, (scan_type, target, 'completed', datetime.now(), datetime.now()))
        
        return self.cursor.fetchone()[0]
    
    def insert_finding(self, scan_job_id: int, finding: Dict[str, Any]):
        """插入發現項"""
        self.cursor.execute("""
            INSERT INTO scan_findings (
                scan_job_id, severity, title, description, host, port, evidence
            ) VALUES (%s, %s, %s, %s, %s, %s, %s::jsonb)
        """, (
            scan_job_id,
            finding.get('severity'),
            finding.get('title'),
            finding.get('description'),
            finding.get('host'),
            finding.get('port'),
            json.dumps(finding.get('evidence', {}))
        ))
    
    def parse(self, file_path: str):
        """解析檔案（需子類實作）"""
        raise NotImplementedError("Subclass must implement parse()")
    
    def commit(self):
        """提交資料庫變更"""
        self.conn.commit()
    
    def close(self):
        """關閉連接"""
        self.cursor.close()
        self.conn.close()

class MyCustomParser(ScanParser):
    """自訂掃描器解析器"""
    
    def parse(self, file_path: str):
        """解析自訂格式"""
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        # 創建掃描任務
        scan_job_id = self.create_scan_job('my_scanner', data.get('target'))
        
        # 解析發現項
        for item in data.get('findings', []):
            finding = {
                'severity': self._map_severity(item['level']),
                'title': item['name'],
                'description': item['details'],
                'host': item['url'],
                'port': item.get('port'),
                'evidence': {'raw': item}
            }
            self.insert_finding(scan_job_id, finding)
        
        self.commit()
        print(f"✅ Parsed {len(data.get('findings', []))} findings. Job ID: {scan_job_id}")
    
    def _map_severity(self, level: str) -> str:
        """映射嚴重度"""
        mapping = {
            '1': 'low',
            '2': 'medium',
            '3': 'high',
            '4': 'critical'
        }
        return mapping.get(str(level), 'info')

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: template_parser.py <scan_result_file>")
        sys.exit(1)
    
    parser = MyCustomParser()
    try:
        parser.parse(sys.argv[1])
    finally:
        parser.close()
```

---

## 擴展 API

### FastAPI 範例

```python
# scripts/api/main.py
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import psycopg2
import os

app = FastAPI(title="Security Stack API", version="1.0.0")

# 資料庫連接
def get_db():
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'postgres'),
        database=os.getenv('DB_NAME', 'security'),
        user=os.getenv('DB_USER', 'sectools'),
        password=os.getenv('DB_PASSWORD')
    )
    try:
        yield conn
    finally:
        conn.close()

# Pydantic Models
class ScanJob(BaseModel):
    id: int
    scan_type: str
    target: str
    status: str
    started_at: str

class Finding(BaseModel):
    id: int
    severity: str
    title: str
    description: Optional[str]
    host: Optional[str]
    discovered_at: str

# API Endpoints
@app.get("/")
def read_root():
    return {"message": "Security Stack API v1.0", "status": "running"}

@app.get("/api/v1/scans", response_model=List[ScanJob])
def get_scans(
    limit: int = 10,
    scan_type: Optional[str] = None,
    db=Depends(get_db)
):
    """獲取掃描任務列表"""
    cursor = db.cursor()
    
    if scan_type:
        cursor.execute("""
            SELECT id, scan_type, target, status, started_at::text
            FROM scan_jobs
            WHERE scan_type = %s
            ORDER BY started_at DESC
            LIMIT %s
        """, (scan_type, limit))
    else:
        cursor.execute("""
            SELECT id, scan_type, target, status, started_at::text
            FROM scan_jobs
            ORDER BY started_at DESC
            LIMIT %s
        """, (limit,))
    
    results = cursor.fetchall()
    cursor.close()
    
    return [
        {"id": r[0], "scan_type": r[1], "target": r[2], "status": r[3], "started_at": r[4]}
        for r in results
    ]

@app.get("/api/v1/scans/{scan_id}/findings", response_model=List[Finding])
def get_findings(scan_id: int, db=Depends(get_db)):
    """獲取特定掃描的發現項"""
    cursor = db.cursor()
    
    cursor.execute("""
        SELECT id, severity, title, description, host, discovered_at::text
        FROM scan_findings
        WHERE scan_job_id = %s
        ORDER BY discovered_at DESC
    """, (scan_id,))
    
    results = cursor.fetchall()
    cursor.close()
    
    if not results:
        raise HTTPException(status_code=404, detail="Scan not found or no findings")
    
    return [
        {
            "id": r[0],
            "severity": r[1],
            "title": r[2],
            "description": r[3],
            "host": r[4],
            "discovered_at": r[5]
        }
        for r in results
    ]

@app.get("/api/v1/stats")
def get_stats(db=Depends(get_db)):
    """獲取統計資料"""
    cursor = db.cursor()
    
    cursor.execute("SELECT * FROM scan_summary")
    results = cursor.fetchall()
    cursor.close()
    
    return {
        "summary": [
            {"scan_type": r[0], "total": r[1], "completed": r[2], "failed": r[3]}
            for r in results
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 部署 API

```dockerfile
# Docker/images/api-server/Dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn psycopg2-binary

COPY scripts/api/main.py /app/

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
services:
  api-server:
    build: ./Docker/images/api-server
    ports:
      - "8000:8000"
    environment:
      DB_HOST: postgres
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - security_net
```

---

## 測試指南

### 單元測試

```python
# tests/unit/test_parser.py
import unittest
from scripts.parsers.nuclei_parser import NucleiParser

class TestNucleiParser(unittest.TestCase):
    
    def test_severity_mapping(self):
        parser = NucleiParser()
        self.assertEqual(parser._map_severity('critical'), 'critical')
        self.assertEqual(parser._map_severity('high'), 'high')
    
    def test_parse_valid_json(self):
        parser = NucleiParser()
        result = parser.parse('tests/fixtures/nuclei-sample.json')
        self.assertIsNotNone(result)

if __name__ == '__main__':
    unittest.main()
```

### 整合測試

```bash
#!/bin/bash
# tests/integration/test_full_scan.sh

set -e

echo "🧪 Running integration tests..."

# 1. 啟動服務
cd Make_Files
make up
sleep 30

# 2. 執行測試掃描
make scan-nuclei TARGET=https://scanme.nmap.org

# 3. 驗證資料庫記錄
COUNT=$(docker exec postgres psql -U sectools -d security -t -c \
    "SELECT COUNT(*) FROM scan_jobs WHERE target='https://scanme.nmap.org'")

if [ "$COUNT" -gt 0 ]; then
    echo "✅ Integration test passed!"
else
    echo "❌ Integration test failed!"
    exit 1
fi

# 4. 清理
make down
```

---

**文件版本**: 1.0  
**最後更新**: 2025-10-17

