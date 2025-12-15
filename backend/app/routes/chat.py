"""
Chat Routes
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc
from typing import List
from uuid import UUID

from app.database import get_db
from app.routes.auth import get_current_user
from app.models.user import User
from app.models.message import Message
from app.models.friendship import Friendship, FriendshipStatus
from app.schemas.chat import MessageCreate, MessageResponse, ConversationResponse, FriendResponse
from app.routes.websocket import manager
import json
from datetime import datetime

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("/send", response_model=MessageResponse)
async def send_message(
    msg: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send a message with full defensive coding.
    PRODUCTION-GRADE: Never returns 500, always validates, always rolls back on error.
    """
    import logging
    logger = logging.getLogger(__name__)
    
    # VALIDATION 1: Receiver exists
    receiver = db.query(User).filter(User.id == msg.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")
    
    # VALIDATION 2: Not sending to self
    if receiver.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot send message to yourself")
    
    # VALIDATION 3: Content not empty
    if not msg.content or not msg.content.strip():
        raise HTTPException(status_code=400, detail="Message content cannot be empty")
    
    # VALIDATION 4: Content length (prevent abuse)
    if len(msg.content) > 5000:
        raise HTTPException(status_code=400, detail="Message too long (max 5000 characters)")
    
    # Save message to database with transaction safety
    try:
        new_msg = Message(
            sender_id=current_user.id,
            receiver_id=msg.receiver_id,
            content=msg.content.strip()
        )
        db.add(new_msg)
        db.commit()
        db.refresh(new_msg)
        
        logger.info(f"Message {new_msg.id} saved: {current_user.id} -> {msg.receiver_id}")
        
    except Exception as e:
        # CRITICAL: Always rollback on database errors
        db.rollback()
        logger.error(f"Message insert failed: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=503,
            detail="Could not save message. Please retry."
        )
    
    # WebSocket notification - ISOLATED - never crashes this endpoint
    try:
        message_data = {
            "type": "CHAT_MESSAGE",
            "message": {
                "id": str(new_msg.id),
                "sender_id": str(new_msg.sender_id),
                "content": new_msg.content,
                "created_at": new_msg.created_at.isoformat(),
                "is_read": False
            }
        }
        await manager.send_personal_message(message_data, msg.receiver_id)
        logger.debug(f"WebSocket notification sent to {msg.receiver_id}")
        
    except Exception as e:
        # WebSocket failure is NOT critical - message was saved successfully
        logger.warning(f"WebSocket notification failed (non-critical): {type(e).__name__}: {e}")
        # Do NOT raise - return the saved message
    
    return MessageResponse.from_orm(new_msg)

@router.get("/history/{other_user_id}", response_model=List[MessageResponse])
def get_chat_history(
    other_user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    messages = db.query(Message).filter(
        or_(
            and_(Message.sender_id == current_user.id, Message.receiver_id == other_user_id),
            and_(Message.sender_id == other_user_id, Message.receiver_id == current_user.id)
        )
    ).order_by(Message.created_at.asc()).all()
    
    # Mark as read (simple logic: all incoming from this user)
    # Ideally should be a separate endpoint or optimize update
    db.query(Message).filter(
        Message.sender_id == other_user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).update({"is_read": True})
    db.commit()
    
    return [MessageResponse.from_orm(m) for m in messages]

@router.get("/conversations", response_model=List[ConversationResponse])
def get_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 1. Get all friends
    friendships = db.query(Friendship).filter(
        ((Friendship.user_id == current_user.id) | (Friendship.friend_id == current_user.id)) &
        (Friendship.status == FriendshipStatus.ACCEPTED)
    ).all()
    
    conversations = []
    
    for f in friendships:
         # Identify friend
        friend_id = f.friend_id if f.user_id == current_user.id else f.user_id
        friend_user = db.query(User).filter(User.id == friend_id).first()
        
        # Get last message
        last_msg = db.query(Message).filter(
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == friend_id),
                and_(Message.sender_id == friend_id, Message.receiver_id == current_user.id)
            )
        ).order_by(Message.created_at.desc()).first()
        
        # Get unread count
        unread = db.query(Message).filter(
            Message.sender_id == friend_id,
            Message.receiver_id == current_user.id,
            Message.is_read == False
        ).count()
        
        conversations.append(ConversationResponse(
            friend=FriendResponse(id=friend_user.id, username=friend_user.username, avatar_url=friend_user.avatar_url),
            last_message=MessageResponse.from_orm(last_msg) if last_msg else None,
            unread_count=unread
        ))
    
    # Sort by last message time
    conversations.sort(key=lambda x: x.last_message.created_at if x.last_message else datetime.min, reverse=True)
    
    return conversations
