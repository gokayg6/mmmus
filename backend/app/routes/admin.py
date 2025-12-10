"""
Admin API Routes - Protected endpoints for moderation
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer
from typing import List

from app.database import get_db
from app.services.auth import verify_password, create_access_token, decode_access_token, authenticate_admin, get_admin_by_id
from app.services.ban import list_bans, create_ban, deactivate_ban
from app.services.reporting import list_reports, update_report_status, count_pending_reports
from app.services.matchmaking import get_matchmaking_service
from app.schemas.admin import (
    AdminLoginRequest, AdminLoginResponse,
    BanCreateRequest, BanResponse, BanUpdateRequest,
    StatsOverviewResponse
)
from app.models.admin import Admin

router = APIRouter(prefix="/admin", tags=["Admin"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/admin/auth/login")


# --- Dependencies ---

def get_current_admin(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    admin_id = payload.get("sub")
    if not admin_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")
        
    admin = get_admin_by_id(db, admin_id)
    if not admin:
        raise HTTPException(status_code=401, detail="Admin user not found")
        
    return admin


# --- Auth Routes ---

@router.post("/auth/login", response_model=AdminLoginResponse)
def login(request: AdminLoginRequest, db: Session = Depends(get_db)):
    admin = authenticate_admin(db, request.email, request.password)
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": str(admin.id), "role": admin.role.value})
    
    return AdminLoginResponse(
        access_token=access_token,
        expires_in=60 * 60 * 24, # 1 day
        admin_id=str(admin.id),
        role=admin.role.value
    )


@router.get("/me")
def read_users_me(current_admin: Admin = Depends(get_current_admin)):
    return {
        "id": str(current_admin.id),
        "email": current_admin.email,
        "name": current_admin.name,
        "role": current_admin.role.value
    }


# --- Stats Routes ---

@router.get("/stats/overview", response_model=StatsOverviewResponse)
def get_stats_overview(
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    mm_service = get_matchmaking_service()
    
    return StatsOverviewResponse(
        online_users=mm_service.online_count,
        active_connections=mm_service.active_connections_count,
        sessions_today=0, # TODO: Implement metrics
        reports_today=0, # TODO: Implement metrics
        reports_pending=count_pending_reports(db)
    )


# --- Ban Routes ---

@router.get("/bans", response_model=List[BanResponse])
def get_bans(
    skip: int = 0, 
    limit: int = 50, 
    active_only: bool = True,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    bans = list_bans(db, active_only, skip, limit)
    return bans


@router.post("/bans", response_model=BanResponse)
def create_new_ban(
    request: BanCreateRequest,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    ban = create_ban(
        db=db,
        admin_id=current_admin.id,
        reason=request.reason,
        ip_address=request.ip_address,
        device_fingerprint=request.device_fingerprint,
        expires_in_hours=request.expires_in_hours
    )
    return ban


# --- Report Routes ---

@router.get("/reports")
def get_reports(
    status: str = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    reports = list_reports(db, status=status, skip=skip, limit=limit)
    return reports
