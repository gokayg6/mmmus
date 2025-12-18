"""
User Model - Registered user accounts
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Uuid, Integer
from sqlalchemy.orm import relationship

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
    
    # Premium fields
    is_premium = Column(Boolean, default=False, nullable=False)
    premium_until = Column(DateTime, nullable=True)
    credits = Column(Integer, default=0, nullable=False)
    
    # User preferences
    language_code = Column(String(5), default='en', nullable=False)  # ISO 639-1 language code
    
    # Profile fields (Real-time updates)
    bio = Column(String(500), nullable=True)
    gender = Column(String(20), nullable=True)
    birthdate = Column(DateTime, nullable=True)
    location = Column(String(100), nullable=True)
    
    # Unlocked features (purchased with credits)
    gender_filter_unlocked = Column(Boolean, default=False, nullable=False)  # 30 credits
    country_filter_unlocked = Column(Boolean, default=False, nullable=False)  # 20 credits
    reconnect_unlocked = Column(Boolean, default=False, nullable=False)  # 40 credits
    hd_quality_unlocked = Column(Boolean, default=False, nullable=False)  # 15 credits
    face_filters_unlocked = Column(Boolean, default=False, nullable=False)  # 10 credits
    vip_badge_unlocked = Column(Boolean, default=False, nullable=False)  # 50 credits
    
    # Stats
    last_login_at = Column(DateTime, nullable=True)
    is_banned = Column(Boolean, default=False, nullable=False)

    # Relationships
    points_history = relationship("PointsHistory", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User {self.email} ({self.username})>"
    
    def can_use_gender_filter(self) -> bool:
        """Check if user can use gender filter (premium or unlocked)"""
        if self.is_premium and self.premium_until and self.premium_until > datetime.utcnow():
            return True
        return self.gender_filter_unlocked
    
    def can_use_country_filter(self) -> bool:
        """Check if user can use country filter (premium or unlocked)"""
        if self.is_premium and self.premium_until and self.premium_until > datetime.utcnow():
            return True
        return self.country_filter_unlocked
