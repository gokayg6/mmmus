"""
Friendship Model
"""
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, Uuid, Enum as SQLEnum
from sqlalchemy.orm import relationship
import uuid
import enum

from app.database import Base

class FriendshipStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    BLOCKED = "BLOCKED"

class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False)
    friend_id = Column(Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status = Column(SQLEnum(FriendshipStatus, name="friendship_status_enum", create_constraint=True), default=FriendshipStatus.PENDING, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    # Note: access these via User model typically
    user = relationship("User", foreign_keys=[user_id])
    friend = relationship("User", foreign_keys=[friend_id])

    def __repr__(self):
        return f"<Friendship {self.user_id} -> {self.friend_id} ({self.status})>"
