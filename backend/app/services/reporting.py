"""
Reporting Service - Handle user reports
"""
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session


def create_report(
    db: Session,
    reporter_session_id: UUID,
    reason: str,
    connection_id: UUID = None,
    reported_session_id: UUID = None,
    description: str = None
):
    """Yeni rapor oluştur"""
    from app.models.report import Report, ReportReason
    from app.models.connection import Connection
    
    report = Report(
        connection_id=connection_id,
        reporter_session_id=reporter_session_id,
        reported_session_id=reported_session_id,
        reason=ReportReason(reason),
        description=description
    )
    db.add(report)
    
    # Bağlantıyı raporlandı olarak işaretle
    if connection_id:
        connection = db.query(Connection).filter(Connection.id == connection_id).first()
        if connection:
            connection.reported = True
    
    db.commit()
    db.refresh(report)
    return report


def get_report(db: Session, report_id: UUID):
    """ID ile rapor bul"""
    from app.models.report import Report
    return db.query(Report).filter(Report.id == report_id).first()


def list_reports(
    db: Session,
    status: str = None,
    reason: str = None,
    start_date: datetime = None,
    end_date: datetime = None,
    skip: int = 0,
    limit: int = 50
) -> List:
    """Raporları listele (filtreli)"""
    from app.models.report import Report, ReportStatus, ReportReason
    
    query = db.query(Report)
    
    if status:
        query = query.filter(Report.status == ReportStatus(status))
    if reason:
        query = query.filter(Report.reason == ReportReason(reason))
    if start_date:
        query = query.filter(Report.created_at >= start_date)
    if end_date:
        query = query.filter(Report.created_at <= end_date)
    
    return query.order_by(Report.created_at.desc()).offset(skip).limit(limit).all()


def update_report_status(
    db: Session,
    report_id: UUID,
    status: str,
    moderator_id: UUID = None
):
    """Rapor durumunu güncelle"""
    from app.models.report import Report, ReportStatus
    
    report = db.query(Report).filter(Report.id == report_id).first()
    if report:
        report.status = ReportStatus(status)
        if moderator_id:
            report.moderator_id = moderator_id
        if status in ["RESOLVED", "REJECTED"]:
            report.processed_at = datetime.utcnow()
        db.commit()
        db.refresh(report)
    return report


def count_pending_reports(db: Session) -> int:
    """Bekleyen rapor sayısı"""
    from app.models.report import Report, ReportStatus
    return db.query(Report).filter(
        Report.status.in_([ReportStatus.NEW, ReportStatus.UNDER_REVIEW])
    ).count()


def count_reports_today(db: Session) -> int:
    """Bugün oluşturulan rapor sayısı"""
    from app.models.report import Report
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    return db.query(Report).filter(Report.created_at >= today_start).count()
