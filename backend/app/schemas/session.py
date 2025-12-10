"""
Session Schemas - Request/Response models for session endpoints
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime
from uuid import UUID


class SessionStartRequest(BaseModel):
    """Session başlatma isteği"""
    device_type: str = Field(..., description="WEB, IOS veya ANDROID")
    gender: Optional[str] = Field("UNSPECIFIED", description="MALE, FEMALE, OTHER, UNSPECIFIED")
    device_fingerprint: Optional[str] = Field(None, max_length=256)
    
    class Config:
        json_schema_extra = {
            "example": {
                "device_type": "IOS",
                "gender": "UNSPECIFIED",
                "device_fingerprint": "abc123xyz"
            }
        }


class SessionStartResponse(BaseModel):
    """Session başlatma yanıtı"""
    session_id: str
    session_token: str
    ice_servers: List[Any]
    
    class Config:
        json_schema_extra = {
            "example": {
                "session_id": "550e8400-e29b-41d4-a716-446655440000",
                "session_token": "a1b2c3d4e5f6...",
                "ice_servers": [
                    {"urls": "stun:stun.l.google.com:19302"}
                ]
            }
        }


class SessionHeartbeatRequest(BaseModel):
    """Heartbeat isteği - session'ı canlı tutmak için"""
    session_token: str


class SessionHeartbeatResponse(BaseModel):
    """Heartbeat yanıtı"""
    success: bool
    online_users: int
