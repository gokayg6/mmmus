"""
Report Schemas - Request/Response models for report endpoints
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ReportCreateRequest(BaseModel):
    """Rapor oluşturma isteği"""
    session_token: str
    connection_id: Optional[str] = None
    reason: str = Field(..., description="NUDITY, HARASSMENT, SPAM, BOT, OTHER")
    description: Optional[str] = Field(None, max_length=1000)
    
    class Config:
        json_schema_extra = {
            "example": {
                "session_token": "a1b2c3d4e5f6...",
                "connection_id": "550e8400-e29b-41d4-a716-446655440000",
                "reason": "HARASSMENT",
                "description": "Uygunsuz davranış"
            }
        }


class ReportCreateResponse(BaseModel):
    """Rapor oluşturma yanıtı"""
    report_id: str
    message: str = "Raporunuz alındı. Teşekkürler."


class ReportListItem(BaseModel):
    """Admin için rapor listesi öğesi"""
    id: str
    connection_id: Optional[str]
    reason: str
    status: str
    created_at: datetime
    reporter_country: Optional[str]
    reported_country: Optional[str]


class ReportUpdateRequest(BaseModel):
    """Rapor durumu güncelleme"""
    status: str = Field(..., description="NEW, UNDER_REVIEW, RESOLVED, REJECTED")
