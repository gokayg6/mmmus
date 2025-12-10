"""
Daily Metrics Model - Aggregated statistics
"""
from datetime import date
from sqlalchemy import Column, Integer, Date

from app.database import Base


class DailyMetrics(Base):
    __tablename__ = "daily_metrics"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    date = Column(Date, unique=True, nullable=False, index=True)
    active_users = Column(Integer, default=0, nullable=False)
    total_sessions = Column(Integer, default=0, nullable=False)
    avg_session_duration_sec = Column(Integer, default=0, nullable=False)
    new_reports = Column(Integer, default=0, nullable=False)
    peak_concurrent_users = Column(Integer, default=0, nullable=False)
    
    def __repr__(self):
        return f"<DailyMetrics {self.date}>"
