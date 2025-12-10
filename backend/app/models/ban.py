"""
Ban Model - IP and device-based bans
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, Boolean, ForeignKey, DateTime
from sqlalchemy import Column, String, DateTime, Uuid
from sqlalchemy.orm import relationship

from app.database import Base


class Ban(Base):
    __tablename__ = "bans"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ip_address = Column(String(45), nullable=True, index=True)
    device_fingerprint = Column(String(256), nullable=True, index=True)
    reason = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    expires_at = Column(DateTime, nullable=True)  # NULL = permanent ban
    created_by_admin_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("admins.id", ondelete="SET NULL"), 
        nullable=True  # Admin silinse bile ban kalsın
    )
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    
    # Relationships
    created_by_admin = relationship("Admin", back_populates="created_bans")
    
    @property
    def is_expired(self) -> bool:
        """Ban süresi dolmuş mu?"""
        if self.expires_at is None:
            return False  # Kalıcı ban
        return datetime.utcnow() > self.expires_at
    
    @property
    def is_effective(self) -> bool:
        """Ban şu an aktif mi?"""
        return self.is_active and not self.is_expired
    
    def __repr__(self):
        return f"<Ban {self.id} (active={self.is_active})>"
