"""
Message Model
"""
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Boolean, Uuid
from sqlalchemy.orm import relationship
import uuid

from app.database import Base

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sender_id = Column(Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    
    # Relationships
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

    def __repr__(self):
        return f"<Message {self.id} from {self.sender_id} to {self.receiver_id}>"
