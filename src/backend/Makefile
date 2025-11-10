.PHONY: help build run test clean migrate-up migrate-down swagger lint

# 預設目標
.DEFAULT_GOAL := help

# 變數定義
BINARY_NAME=security-platform
MAIN_PATH=./cmd/server
MIGRATION_PATH=./database/migrations

## help: 顯示幫助資訊
help:
	@echo "可用指令："
	@echo "  make build          - 建置應用程式"
	@echo "  make run            - 執行應用程式"
	@echo "  make dev            - 開發模式執行（hot reload）"
	@echo "  make test           - 執行測試"
	@echo "  make test-coverage  - 執行測試並產生覆蓋率報告"
	@echo "  make lint           - 執行程式碼檢查"
	@echo "  make clean          - 清理建置檔案"
	@echo "  make deps           - 安裝依賴"
	@echo "  make migrate-up     - 執行資料庫遷移（升級）"
	@echo "  make migrate-down   - 執行資料庫遷移（降級）"
	@echo "  make swagger        - 產生 Swagger 文件"
	@echo "  make docker-build   - 建置 Docker 映像"
	@echo "  make docker-run     - 執行 Docker 容器"

## deps: 安裝依賴
deps:
	@echo "📦 安裝 Go 依賴..."
	go mod download
	go mod tidy

## build: 建置應用程式
build: deps
	@echo "🔨 建置應用程式..."
	go build -o bin/$(BINARY_NAME) $(MAIN_PATH)/main.go

## run: 執行應用程式
run: build
	@echo "🚀 啟動應用程式..."
	./bin/$(BINARY_NAME)

## dev: 開發模式執行
dev:
	@echo "🔧 開發模式啟動（使用 air）..."
	@if command -v air > /dev/null; then \
		air; \
	else \
		echo "⚠️  未安裝 air，請執行: go install github.com/cosmtrek/air@latest"; \
		go run $(MAIN_PATH)/main.go; \
	fi

## test: 執行所有測試
test:
	@echo "🧪 執行測試..."
	go test -v ./...

## test-coverage: 執行測試並產生覆蓋率報告
test-coverage:
	@echo "📊 執行測試並產生覆蓋率..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "✅ 覆蓋率報告已產生: coverage.html"

## lint: 執行程式碼檢查
lint:
	@echo "🔍 執行程式碼檢查..."
	@if command -v golangci-lint > /dev/null; then \
		golangci-lint run; \
	else \
		echo "⚠️  未安裝 golangci-lint，請執行: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
		go vet ./...; \
	fi

## clean: 清理建置檔案
clean:
	@echo "🧹 清理建置檔案..."
	rm -rf bin/
	rm -f coverage.out coverage.html

## migrate-up: 執行資料庫遷移（升級）
migrate-up:
	@echo "⬆️  執行資料庫遷移..."
	@if command -v migrate > /dev/null; then \
		migrate -path $(MIGRATION_PATH) -database "$${DATABASE_URL}" up; \
	else \
		echo "⚠️  未安裝 migrate，請執行: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"; \
	fi

## migrate-down: 執行資料庫遷移（降級）
migrate-down:
	@echo "⬇️  回滾資料庫遷移..."
	@if command -v migrate > /dev/null; then \
		migrate -path $(MIGRATION_PATH) -database "$${DATABASE_URL}" down; \
	else \
		echo "⚠️  未安裝 migrate"; \
	fi

## migrate-create: 建立新的遷移檔案
migrate-create:
	@read -p "輸入遷移檔案名稱: " name; \
	migrate create -ext sql -dir $(MIGRATION_PATH) -seq $$name

## swagger: 產生 Swagger 文件
swagger:
	@echo "📖 產生 Swagger 文件..."
	@if command -v swag > /dev/null; then \
		swag init -g $(MAIN_PATH)/main.go -o ./docs; \
	else \
		echo "⚠️  未安裝 swag，請執行: go install github.com/swaggo/swag/cmd/swag@latest"; \
	fi

## docker-build: 建置 Docker 映像
docker-build:
	@echo "🐳 建置 Docker 映像..."
	docker build -t unified-security-platform-backend:latest -f Dockerfile .

## docker-run: 執行 Docker 容器
docker-run:
	@echo "🐳 啟動 Docker 容器..."
	docker run -p 3001:3001 --env-file .env unified-security-platform-backend:latest

## format: 格式化程式碼
format:
	@echo "💅 格式化程式碼..."
	go fmt ./...
	@if command -v goimports > /dev/null; then \
		goimports -w .; \
	fi

## mod-update: 更新所有依賴到最新版本
mod-update:
	@echo "🔄 更新依賴..."
	go get -u ./...
	go mod tidy



