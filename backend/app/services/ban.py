"""
Ban Service - Check and manage bans
"""
from datetime import datetime, timedelta
from typing import Optional, List
from uuid import UUID

from sqlalchemy.orm import Session
from sqlalchemy import or_, and_


def check_ban(db: Session, ip_address: str = None, device_fingerprint: str = None):
    """
    IP veya device fingerprint için aktif ban var mı kontrol et.
    Aktif ban varsa Ban objesi döner, yoksa None.
    """
    from app.models.ban import Ban
    
    if not ip_address and not device_fingerprint:
        return None
    
    now = datetime.utcnow()
    
    # Query koşullarını oluştur
    conditions = []
    if ip_address:
        conditions.append(Ban.ip_address == ip_address)
    if device_fingerprint:
        conditions.append(Ban.device_fingerprint == device_fingerprint)
    
    # Aktif ve süresi dolmamış banları bul
    ban = db.query(Ban).filter(
        and_(
            Ban.is_active == True,
            or_(*conditions),
            or_(
                Ban.expires_at.is_(None),  # Kalıcı ban
                Ban.expires_at > now  # Süresi dolmamış
            )
        )
    ).first()
    
    return ban


def create_ban(
    db: Session,
    admin_id: UUID,
    reason: str,
    ip_address: str = None,
    device_fingerprint: str = None,
    expires_in_hours: int = None
):
    """Yeni ban oluştur"""
    from app.models.ban import Ban
    
    expires_at = None
    if expires_in_hours:
        expires_at = datetime.utcnow() + timedelta(hours=expires_in_hours)
    
    ban = Ban(
        ip_address=ip_address,
        device_fingerprint=device_fingerprint,
        reason=reason,
        expires_at=expires_at,
        created_by_admin_id=admin_id
    )
    db.add(ban)
    db.commit()
    db.refresh(ban)
    return ban


def deactivate_ban(db: Session, ban_id: UUID):
    """Ban'ı deaktif et"""
    from app.models.ban import Ban
    
    ban = db.query(Ban).filter(Ban.id == ban_id).first()
    if ban:
        ban.is_active = False
        db.commit()
        db.refresh(ban)
    return ban


def list_bans(
    db: Session,
    active_only: bool = True,
    skip: int = 0,
    limit: int = 50
) -> List:
    """Banları listele"""
    from app.models.ban import Ban
    
    query = db.query(Ban)
    if active_only:
        query = query.filter(Ban.is_active == True)
    return query.order_by(Ban.created_at.desc()).offset(skip).limit(limit).all()
