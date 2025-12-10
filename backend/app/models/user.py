"""
User Model - Registered user accounts
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Uuid

from app.database import Base


class User(Base):
    """User model for registered accounts"""
    __tablename__ = "users"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    avatar_url = Column(String(512), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True, nullable=False)
    
    def __repr__(self):
        return f"<User {self.email} ({self.username})>"
