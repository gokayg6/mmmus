"""
Admin Schemas - Request/Response models for admin endpoints
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime, date


# === Auth Schemas ===

class AdminLoginRequest(BaseModel):
    """Admin giriş isteği"""
    email: EmailStr
    password: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "admin@omechat.com",
                "password": "secure_password"
            }
        }


class AdminLoginResponse(BaseModel):
    """Admin giriş yanıtı"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    admin_id: str
    role: str


class AdminCreateRequest(BaseModel):
    """Yeni admin oluşturma"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    name: Optional[str] = None
    role: str = "MODERATOR"


# === Ban Schemas ===

class BanCreateRequest(BaseModel):
    """Yeni ban oluşturma"""
    ip_address: Optional[str] = None
    device_fingerprint: Optional[str] = None
    reason: str
    expires_in_hours: Optional[int] = None  # None = kalıcı
    
    class Config:
        json_schema_extra = {
            "example": {
                "ip_address": "192.168.1.1",
                "device_fingerprint": "abc123xyz",
                "reason": "Tekrarlayan uygunsuz içerik",
                "expires_in_hours": 24
            }
        }


class BanResponse(BaseModel):
    """Ban bilgisi yanıtı"""
    id: str
    ip_address: Optional[str]
    device_fingerprint: Optional[str]
    reason: str
    created_at: datetime
    expires_at: Optional[datetime]
    is_active: bool


class BanUpdateRequest(BaseModel):
    """Ban güncelleme"""
    is_active: Optional[bool] = None
    expires_in_hours: Optional[int] = None


# === Stats Schemas ===

class StatsOverviewResponse(BaseModel):
    """Dashboard istatistikleri"""
    online_users: int
    active_connections: int
    sessions_today: int
    reports_today: int
    reports_pending: int


class DailyStatsResponse(BaseModel):
    """Günlük istatistikler"""
    date: date
    active_users: int
    total_sessions: int
    avg_session_duration_sec: int
    new_reports: int
    peak_concurrent_users: int
