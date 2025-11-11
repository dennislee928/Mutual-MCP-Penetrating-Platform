"""
AI/量子安全服務 - FastAPI 主程式
"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from config.settings import settings
from api.routes import ai_routes, quantum_routes

# 配置日誌
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """應用程式生命週期管理"""
    logger.info("🚀 AI/量子安全服務啟動中...")
    
    # 啟動時初始化
    # TODO: 載入 AI 模型
    # TODO: 初始化量子連接（如果配置了）
    
    logger.info("✅ AI/量子安全服務已就緒")
    
    yield
    
    # 關閉時清理
    logger.info("🛑 AI/量子安全服務關閉中...")
    # TODO: 清理資源


# 建立 FastAPI 應用
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="AI 威脅偵測與量子計算安全服務",
    lifespan=lifespan
)

# CORS 中間件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 健康檢查端點
@app.get("/health")
async def health_check():
    """健康檢查"""
    return {
        "status": "ok",
        "service": settings.app_name,
        "version": settings.app_version
    }


@app.get("/")
async def root():
    """根端點"""
    return {
        "message": "AI/量子安全服務",
        "version": settings.app_version,
        "docs": "/docs",
        "health": "/health"
    }


# 註冊路由
app.include_router(
    ai_routes.router,
    prefix="/api/ai",
    tags=["AI 威脅偵測"]
)

app.include_router(
    quantum_routes.router,
    prefix="/api/quantum",
    tags=["量子計算"]
)


# 全域異常處理
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """全域異常處理器"""
    logger.error(f"未處理的異常: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_server_error",
            "message": "伺服器內部錯誤"
        }
    )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )





