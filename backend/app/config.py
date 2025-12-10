"""
OmeChat Configuration Settings
NOTE: .env dosyası yoksa veya DATABASE_URL yanlışsa uygulama başlamaz.
"""
import os
from typing import List
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "OmeChat"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/omechat"
    
    # Redis (optional, for horizontal scaling)
    REDIS_URL: str = "redis://localhost:6379/0"
    USE_REDIS: bool = False
    
    # JWT Settings (for admin auth)
    JWT_SECRET_KEY: str = "omechat-super-secret-key-change-this-in-production-2024"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    
    # Session Settings
    SESSION_TOKEN_LENGTH: int = 64
    SESSION_TIMEOUT_MINUTES: int = 30
    
    # Matchmaking
    MATCH_TIMEOUT_SECONDS: int = 60
    
    # STUN/TURN Configuration - Google'ın ücretsiz STUN sunucuları
    STUN_SERVERS: List[str] = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302"
    ]
    TURN_SERVER: str = ""
    TURN_USERNAME: str = ""
    TURN_CREDENTIAL: str = ""
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"  # Ignore extra fields in .env


@lru_cache()
def get_settings() -> Settings:
    return Settings()
