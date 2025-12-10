"""
Public API Routes - Anonymous user endpoints
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from sqlalchemy.orm import Session
from secrets import token_urlsafe
from datetime import datetime

from app.database import get_db
from app.config import get_settings
from app.models.user_session import UserSession, DeviceType, Gender
from app.models.ban import Ban
from app.services.ban import check_ban
from app.services.reporting import create_report
from app.services.matchmaking import get_matchmaking_service
from app.schemas.session import (
    SessionStartRequest, SessionStartResponse,
    SessionHeartbeatRequest, SessionHeartbeatResponse
)
from app.schemas.report import ReportCreateRequest, ReportCreateResponse
from app.schemas.websocket import OnlineCountMessage

router = APIRouter(prefix="/public", tags=["Public"])
settings = get_settings()

@router.post("/session/start", response_model=SessionStartResponse)
def start_session(
    request: SessionStartRequest, 
    background_tasks: BackgroundTasks,
    req: Request, 
    db: Session = Depends(get_db)
):
    """
    Yeni bir anonim oturum başlat.
    IP ve varsa device fingerprint kontrolü yapılır (BAN Check).
    """
    client_ip = req.client.host
    
    # 1. Ban kontrolü
    active_ban = check_ban(db, ip_address=client_ip, device_fingerprint=request.device_fingerprint)
    if active_ban:
        raise HTTPException(
            status_code=403, 
            detail=f"Erişiminiz engellendi. Sebep: {active_ban.reason}"
        )
    
    # 2. Yeni session oluştur
    session_token = token_urlsafe(settings.SESSION_TOKEN_LENGTH // 2)  # bytes to hex string length approx
    
    new_session = UserSession(
        session_token=session_token,
        ip_address=client_ip,
        device_type=DeviceType(request.device_type),
        device_fingerprint=request.device_fingerprint,
        gender=Gender(request.gender) if request.gender else Gender.UNSPECIFIED,
        user_agent=req.headers.get("user-agent"),
        # GeoIP eklenebilir: country=get_country(client_ip)
    )
    
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    
    return SessionStartResponse(
        session_id=str(new_session.id),
        session_token=session_token,
        ice_servers=settings.STUN_SERVERS_JSON if hasattr(settings, 'STUN_SERVERS_JSON') else [{'urls': s} for s in settings.STUN_SERVERS]
    )


@router.post("/session/heartbeat", response_model=SessionHeartbeatResponse)
def session_heartbeat(
    request: SessionHeartbeatRequest,
    db: Session = Depends(get_db)
):
    """
    Session'ı canlı tut.
    """
    session = db.query(UserSession).filter(UserSession.session_token == request.session_token).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    if not session.is_active:
        raise HTTPException(status_code=400, detail="Session is inactive")
        
    session.last_seen_at = datetime.utcnow()
    db.commit()
    
    matchmaking_service = get_matchmaking_service()
    
    return SessionHeartbeatResponse(
        success=True,
        online_users=matchmaking_service.online_count
    )


@router.post("/report", response_model=ReportCreateResponse)
def submit_report(
    request: ReportCreateRequest,
    db: Session = Depends(get_db)
):
    """
    İhlal bildirimi oluştur.
    """
    # Raporlayan session'ı bul
    reporter = db.query(UserSession).filter(UserSession.session_token == request.session_token).first()
    if not reporter:
        raise HTTPException(status_code=401, detail="Invalid session token")
    
    # İlgili connection'ı bul (varsa)
    connection_id = None
    if request.connection_id:
        try:
            connection_id = uuid.UUID(request.connection_id)
        except ValueError:
            pass
            
    # Rapor oluştur
    report = create_report(
        db=db,
        reporter_session_id=reporter.id,
        reason=request.reason,
        connection_id=connection_id,
        description=request.description
    )
    
    return ReportCreateResponse(
        report_id=str(report.id),
        message="Bildiriminiz alındı."
    )


@router.get("/online-count")
def get_online_count():
    """Anlık çevrimiçi kullanıcı sayısı"""
    matchmaking_service = get_matchmaking_service()
    return {
        "online_users": matchmaking_service.online_count,
        "in_queue": matchmaking_service.queue_size,
        "active_connections": matchmaking_service.active_connections_count
    }


@router.get("/health")
def health_check():
    """Sistem sağlık kontrolü"""
    return {"status": "healthy", "timestamp": datetime.utcnow()}
