"""
Connection Model - Matched video chat sessions between two users
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, ForeignKey, Boolean, DateTime, Enum as SQLEnum
from sqlalchemy import Column, String, DateTime, ForeignKey, Uuid
from sqlalchemy.orm import relationship
import enum

from app.database import Base


class EndedReason(str, enum.Enum):
    NORMAL = "NORMAL"
    NEXTED = "NEXTED"
    DISCONNECTED = "DISCONNECTED"
    BANNED = "BANNED"
    ERROR = "ERROR"


class Connection(Base):
    __tablename__ = "connections"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_a_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("user_sessions.id", ondelete="CASCADE"), 
        nullable=False,
        index=True
    )
    session_b_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("user_sessions.id", ondelete="CASCADE"), 
        nullable=False,
        index=True
    )
    started_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    ended_at = Column(DateTime, nullable=True)
    ended_reason = Column(SQLEnum(EndedReason, name="ended_reason_enum", create_constraint=True), nullable=True)
    reported = Column(Boolean, default=False, nullable=False)
    
    # Relationships
    session_a = relationship(
        "UserSession", 
        foreign_keys=[session_a_id],
        back_populates="connections_as_a"
    )
    session_b = relationship(
        "UserSession", 
        foreign_keys=[session_b_id],
        back_populates="connections_as_b"
    )
    reports = relationship("Report", back_populates="connection", lazy="dynamic")
    
    @property
    def duration_seconds(self):
        if self.ended_at and self.started_at:
            return int((self.ended_at - self.started_at).total_seconds())
        return None
    
    def __repr__(self):
        return f"<Connection {self.id}>"
