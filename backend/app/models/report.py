"""
Report Model - User reports for inappropriate content/behavior
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, ForeignKey, DateTime, Enum as SQLEnum
from sqlalchemy import Column, String, DateTime, ForeignKey, Uuid
from sqlalchemy.orm import relationship
import enum

from app.database import Base


class ReportReason(str, enum.Enum):
    NUDITY = "NUDITY"
    HARASSMENT = "HARASSMENT"
    SPAM = "SPAM"
    BOT = "BOT"
    OTHER = "OTHER"


class ReportStatus(str, enum.Enum):
    NEW = "NEW"
    UNDER_REVIEW = "UNDER_REVIEW"
    RESOLVED = "RESOLVED"
    REJECTED = "REJECTED"


class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    connection_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("connections.id", ondelete="SET NULL"), 
        nullable=True,
        index=True
    )
    reporter_session_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("user_sessions.id", ondelete="CASCADE"), 
        nullable=False,
        index=True
    )
    reported_session_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("user_sessions.id", ondelete="SET NULL"), 
        nullable=True,
        index=True
    )
    reason = Column(SQLEnum(ReportReason, name="report_reason_enum", create_constraint=True), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    processed_at = Column(DateTime, nullable=True)
    status = Column(
        SQLEnum(ReportStatus, name="report_status_enum", create_constraint=True), 
        default=ReportStatus.NEW, 
        nullable=False, 
        index=True
    )
    moderator_id = Column(Uuid(as_uuid=True), ForeignKey("admins.id", ondelete="SET NULL"), nullable=True)
    
    # Relationships
    connection = relationship("Connection", back_populates="reports")
    reporter_session = relationship(
        "UserSession", 
        foreign_keys=[reporter_session_id],
        back_populates="reports_made"
    )
    reported_session = relationship(
        "UserSession", 
        foreign_keys=[reported_session_id],
        back_populates="reports_received"
    )
    moderator = relationship("Admin", back_populates="processed_reports")
    
    def __repr__(self):
        return f"<Report {self.id} ({self.reason.value})>"
