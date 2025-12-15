"""
Friend and Chat Schemas
"""
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from uuid import UUID

from app.models.friendship import FriendshipStatus

# --- FRIEND SCHEMAS ---

class FriendRequestCreate(BaseModel):
    username: str

class FriendResponse(BaseModel):
    id: UUID
    username: str
    avatar_url: Optional[str] = None
    is_online: bool = False
    
    class Config:
        orm_mode = True

class FriendshipResponse(BaseModel):
    id: UUID
    friend: FriendResponse
    status: FriendshipStatus
    created_at: datetime

    class Config:
        orm_mode = True

# --- CHAT SCHEMAS ---

class MessageCreate(BaseModel):
    receiver_id: UUID
    content: str

class MessageResponse(BaseModel):
    id: UUID
    sender_id: UUID
    receiver_id: UUID
    content: str
    created_at: datetime
    is_read: bool
    
    class Config:
        orm_mode = True

class ConversationResponse(BaseModel):
    friend: FriendResponse
    last_message: Optional[MessageResponse]
    unread_count: int
