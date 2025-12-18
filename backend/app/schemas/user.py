"""
User Schemas - Pydantic models for auth endpoints
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
import re


class UserCreate(BaseModel):
    """Schema for user registration"""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8, max_length=100)
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir')
        return v.lower()
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Şifre en az 8 karakter olmalıdır')
        return v


class UserLogin(BaseModel):
    """Schema for user login"""
    email: EmailStr
    password: str


class UserUpdate(BaseModel):
    """Schema for updating user profile"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    avatar_url: Optional[str] = Field(None, max_length=512)
    bio: Optional[str] = Field(None, max_length=500)
    gender: Optional[str] = Field(None, max_length=20)
    birthdate: Optional[datetime] = None
    location: Optional[str] = Field(None, max_length=100)
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir')
        return v.lower()


class UserResponse(BaseModel):
    """Schema for user response (public data)"""
    id: str
    email: str
    username: str
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    gender: Optional[str] = None
    birthdate: Optional[datetime] = None
    location: Optional[str] = None
    created_at: datetime
    is_active: bool
    
    # Premium
    is_premium: bool = False
    premium_until: Optional[datetime] = None
    credits: int = 0
    
    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    """Schema for auth response with token"""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class TokenPayload(BaseModel):
    """Schema for JWT token payload"""
    sub: str  # user_id
    email: str
    username: str
    exp: datetime
    type: str = "access"  # "access" or "refresh"
