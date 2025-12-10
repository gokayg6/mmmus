"""
User Session Model - Anonymous user sessions
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum as SQLEnum
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Uuid
from sqlalchemy.orm import relationship
import enum

from app.database import Base


class DeviceType(str, enum.Enum):
    WEB = "WEB"
    IOS = "IOS"
    ANDROID = "ANDROID"


class Gender(str, enum.Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"
    OTHER = "OTHER"
    UNSPECIFIED = "UNSPECIFIED"


class UserSession(Base):
    __tablename__ = "user_sessions"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_token = Column(String(64), unique=True, nullable=False, index=True)
    ip_address = Column(String(45), nullable=False)
    country = Column(String(2), nullable=True)
    device_type = Column(SQLEnum(DeviceType, name="device_type_enum", create_constraint=True), nullable=False)
    user_agent = Column(String(500), nullable=True)
    device_fingerprint = Column(String(256), nullable=True, index=True)
    gender = Column(SQLEnum(Gender, name="gender_enum", create_constraint=True), nullable=True, default=Gender.UNSPECIFIED)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_seen_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Relationships - string references ile (circular import önlemek için)
    connections_as_a = relationship(
        "Connection", 
        foreign_keys="Connection.session_a_id",
        back_populates="session_a",
        lazy="dynamic"
    )
    connections_as_b = relationship(
        "Connection", 
        foreign_keys="Connection.session_b_id",
        back_populates="session_b",
        lazy="dynamic"
    )
    reports_made = relationship(
        "Report",
        foreign_keys="Report.reporter_session_id",
        back_populates="reporter_session",
        lazy="dynamic"
    )
    reports_received = relationship(
        "Report",
        foreign_keys="Report.reported_session_id",
        back_populates="reported_session",
        lazy="dynamic"
    )
    
    def __repr__(self):
        return f"<UserSession {self.id} ({self.device_type.value})>"
