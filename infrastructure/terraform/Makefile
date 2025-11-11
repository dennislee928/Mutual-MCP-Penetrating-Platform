# Terraform Makefile
# 簡化 Terraform 命令執行

.PHONY: help init plan apply destroy fmt validate clean test

# 預設環境
ENV ?= production

# 顏色輸出
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

help: ## 顯示此幫助訊息
	@echo '${CYAN}Terraform 管理工具${RESET}'
	@echo ''
	@echo '使用方式:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET} ${YELLOW}[ENV=<environment>]${RESET}'
	@echo ''
	@echo '目標:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${GREEN}%-20s${RESET} %s\n", $$1, $$2}'
	@echo ''
	@echo '環境:'
	@echo '  ${YELLOW}dev${RESET}         開發環境'
	@echo '  ${YELLOW}staging${RESET}     測試環境'
	@echo '  ${YELLOW}production${RESET}  生產環境 (預設)'
	@echo ''
	@echo '範例:'
	@echo '  ${CYAN}make init${RESET}              # 初始化 production 環境'
	@echo '  ${CYAN}make plan ENV=dev${RESET}     # 查看 dev 環境的執行計畫'
	@echo '  ${CYAN}make apply ENV=staging${RESET} # 部署到 staging 環境'

init: ## 初始化 Terraform
	@echo "${CYAN}🔧 初始化 Terraform (環境: ${ENV})...${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform init; \
	else \
		terraform init; \
	fi
	@echo "${GREEN}✅ 初始化完成${RESET}"

plan: ## 查看執行計畫
	@echo "${CYAN}📋 生成執行計畫 (環境: ${ENV})...${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform plan; \
	else \
		terraform plan; \
	fi

apply: ## 執行部署
	@echo "${CYAN}🚀 執行部署 (環境: ${ENV})...${RESET}"
	@echo "${YELLOW}⚠️  確認要部署到 ${ENV} 環境嗎？${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform apply; \
	else \
		terraform apply; \
	fi
	@echo "${GREEN}✅ 部署完成${RESET}"

apply-auto: ## 自動執行部署（無需確認）
	@echo "${CYAN}🚀 自動執行部署 (環境: ${ENV})...${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform apply -auto-approve; \
	else \
		terraform apply -auto-approve; \
	fi
	@echo "${GREEN}✅ 部署完成${RESET}"

destroy: ## 銷毀資源
	@echo "${YELLOW}⚠️  確認要銷毀 ${ENV} 環境的資源嗎？${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform destroy; \
	else \
		terraform destroy; \
	fi

fmt: ## 格式化 Terraform 檔案
	@echo "${CYAN}📝 格式化 Terraform 檔案...${RESET}"
	@terraform fmt -recursive
	@echo "${GREEN}✅ 格式化完成${RESET}"

validate: ## 驗證配置
	@echo "${CYAN}🔍 驗證 Terraform 配置...${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform validate; \
	else \
		terraform validate; \
	fi
	@echo "${GREEN}✅ 驗證通過${RESET}"

clean: ## 清理臨時檔案
	@echo "${CYAN}🧹 清理臨時檔案...${RESET}"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "${GREEN}✅ 清理完成${RESET}"

test: init validate ## 執行測試（初始化 + 驗證 + 計畫）
	@echo "${CYAN}🧪 執行測試...${RESET}"
	@$(MAKE) plan ENV=${ENV}
	@echo "${GREEN}✅ 測試完成${RESET}"

output: ## 顯示輸出
	@echo "${CYAN}📊 顯示輸出 (環境: ${ENV})...${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && terraform output; \
	else \
		terraform output; \
	fi

health-check: ## 執行健康檢查
	@echo "${CYAN}🏥 執行健康檢查 (環境: ${ENV})...${RESET}"
	@if [ "${ENV}" = "production" ] || [ "${ENV}" = "dev" ]; then \
		cd environments/${ENV} && \
		WORKER_URL=$$(terraform output -raw hexstrike_worker_url 2>/dev/null) && \
		if [ -n "$$WORKER_URL" ]; then \
			echo "Testing: $$WORKER_URL/health" && \
			curl -f "$$WORKER_URL/health" || echo "Health check failed"; \
		else \
			echo "Worker URL not found"; \
		fi; \
	fi

# 環境特定快捷命令
dev-init: ## 初始化 dev 環境
	@$(MAKE) init ENV=dev

dev-plan: ## dev 環境執行計畫
	@$(MAKE) plan ENV=dev

dev-apply: ## 部署到 dev 環境
	@$(MAKE) apply ENV=dev

prod-init: ## 初始化 production 環境
	@$(MAKE) init ENV=production

prod-plan: ## production 環境執行計畫
	@$(MAKE) plan ENV=production

prod-apply: ## 部署到 production 環境
	@$(MAKE) apply ENV=production

