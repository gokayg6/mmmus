"""
Admin Model - Admin and moderator accounts
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum as SQLEnum
from sqlalchemy import Column, String, Boolean, DateTime, Uuid
from sqlalchemy.orm import relationship
import enum

from app.database import Base


class AdminRole(str, enum.Enum):
    ADMIN = "ADMIN"
    MODERATOR = "MODERATOR"


class Admin(Base):
    __tablename__ = "admins"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(100), nullable=True)
    role = Column(
        SQLEnum(AdminRole, name="admin_role_enum", create_constraint=True), 
        nullable=False, 
        default=AdminRole.MODERATOR
    )
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_login_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    processed_reports = relationship("Report", back_populates="moderator", lazy="dynamic")
    created_bans = relationship("Ban", back_populates="created_by_admin", lazy="dynamic")
    
    def __repr__(self):
        return f"<Admin {self.email} ({self.role.value})>"
