"""Application settings and configuration management."""

from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # API Configuration
    api_title: str = "Financial Analysis API"
    api_description: str = "Mizan PDF/Excel veri çıkarımı ve GIB beyanname PDF parse servisi"
    api_version: str = "2.0.0"
    api_host: str = Field(default="0.0.0.0", env="API_HOST")
    api_port: int = Field(default=8000, env="API_PORT")

    # File Processing Configuration
    max_file_size: int = Field(default=50 * 1024 * 1024, env="MAX_FILE_SIZE")  # 50MB
    allowed_extensions: list[str] = [".xlsx", ".xlsm", ".xls", ".csv", ".pdf"]

    # OCR Configuration
    tesseract_lang: str = Field(default="tur", env="TESSERACT_LANG")
    pdf_dpi: int = Field(default=300, env="PDF_DPI")

    # Logging Configuration
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Database Configuration
    database_url: Optional[str] = Field(default=None, env="DATABASE_URL")
    db_pool_min_size: int = Field(default=2, env="DB_POOL_MIN_SIZE")
    db_pool_max_size: int = Field(default=10, env="DB_POOL_MAX_SIZE")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"



@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
