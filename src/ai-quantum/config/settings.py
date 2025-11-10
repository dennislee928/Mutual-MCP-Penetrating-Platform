"""
AI/量子模組配置
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """應用程式設定"""

    # 伺服器配置
    app_name: str = "AI Quantum Security Service"
    app_version: str = "1.0.0"
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False
    
    # CORS 配置
    cors_origins: list[str] = ["*"]
    
    # Go 後端 API
    backend_url: str = "http://localhost:3001"
    
    # HexStrike AI 服務
    hexstrike_url: str = "http://localhost:8888"
    
    # IBM Quantum 配置（可選）
    ibm_quantum_token: Optional[str] = None
    ibm_quantum_channel: str = "ibm_quantum"
    ibm_quantum_instance: str = "ibm_qasm_simulator"
    
    # AI 模型配置
    model_path: str = "./models"
    anomaly_threshold: float = 0.7
    threat_confidence_threshold: float = 0.6
    
    # 快取配置
    cache_enabled: bool = True
    cache_ttl: int = 300  # 秒
    
    # 日誌配置
    log_level: str = "INFO"
    log_format: str = "json"
    
    # Prometheus 指標
    metrics_enabled: bool = True
    metrics_port: int = 9100
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# 全域設定實例
settings = Settings()


