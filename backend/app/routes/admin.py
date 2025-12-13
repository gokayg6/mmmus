"""
Admin API Routes - Protected endpoints for moderation
Full CRUD for users, credits, premium, bans, reports
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from fastapi.security import OAuth2PasswordBearer
from typing import List, Optional
from datetime import datetime, timedelta
from uuid import UUID

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
from app.models.user import User
from app.models.report import Report

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
    
    # Update last login
    admin.last_login_at = datetime.utcnow()
    db.commit()
    
    access_token = create_access_token(data={"sub": str(admin.id), "role": admin.role.value})
    
    return AdminLoginResponse(
        access_token=access_token,
        expires_in=60 * 60 * 24,
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

@router.get("/stats/overview")
def get_stats_overview(
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    mm_service = get_matchmaking_service()
    
    # Get real user counts
    total_users = db.query(func.count(User.id)).scalar() or 0
    premium_users = db.query(func.count(User.id)).filter(User.is_premium == True).scalar() or 0
    banned_users = db.query(func.count(User.id)).filter(User.is_banned == True).scalar() or 0
    
    # Today's stats
    today = datetime.utcnow().date()
    today_start = datetime.combine(today, datetime.min.time())
    
    users_today = db.query(func.count(User.id)).filter(User.created_at >= today_start).scalar() or 0
    pending_reports = count_pending_reports(db)
    total_reports = db.query(func.count(Report.id)).scalar() or 0
    
    # Revenue calculation (mock for now - would come from payment system)
    today_revenue = 4589.50
    monthly_revenue = 125789.00
    
    return {
        "total_users": total_users,
        "online_users": mm_service.online_count,
        "premium_users": premium_users,
        "banned_users": banned_users,
        "active_connections": mm_service.active_connections_count,
        "users_today": users_today,
        "pending_reports": pending_reports,
        "total_reports": total_reports,
        "today_revenue": today_revenue,
        "monthly_revenue": monthly_revenue,
        "premium_revenue": monthly_revenue * 0.71,
        "credits_revenue": monthly_revenue * 0.23,
        "ads_revenue": monthly_revenue * 0.06,
    }


# --- User Management Routes ---

@router.get("/users")
def get_users(
    search: Optional[str] = None,
    is_premium: Optional[bool] = None,
    is_banned: Optional[bool] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    query = db.query(User)
    
    if search:
        query = query.filter(
            (User.username.ilike(f"%{search}%")) |
            (User.email.ilike(f"%{search}%"))
        )
    
    if is_premium is not None:
        query = query.filter(User.is_premium == is_premium)
    
    if is_banned is not None:
        query = query.filter(User.is_banned == is_banned)
    
    total = query.count()
    users = query.order_by(desc(User.created_at)).offset(skip).limit(limit).all()
    
    return {
        "total": total,
        "users": [
            {
                "id": str(u.id),
                "email": u.email,
                "username": u.username,
                "avatar_url": u.avatar_url,
                "is_premium": u.is_premium,
                "premium_until": u.premium_until.isoformat() if u.premium_until else None,
                "credits": u.credits,
                "is_banned": u.is_banned,
                "is_active": u.is_active,
                "created_at": u.created_at.isoformat(),
                "last_login_at": u.last_login_at.isoformat() if u.last_login_at else None,
            }
            for u in users
        ]
    }


@router.get("/users/{user_id}")
def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    try:
        from uuid import UUID as UUIDType
        uid = UUIDType(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(User).filter(User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": str(user.id),
        "email": user.email,
        "username": user.username,
        "avatar_url": user.avatar_url,
        "is_premium": user.is_premium,
        "premium_until": user.premium_until.isoformat() if user.premium_until else None,
        "credits": user.credits,
        "is_banned": user.is_banned,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat(),
        "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
    }


@router.post("/users/{user_id}/credits")
def give_credits(
    user_id: str,
    amount: int = Query(..., gt=0),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    try:
        from uuid import UUID as UUIDType
        uid = UUIDType(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(User).filter(User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.credits += amount
    db.commit()
    
    return {"message": f"{amount} credits added", "new_balance": user.credits}


@router.post("/users/{user_id}/premium")
def give_premium(
    user_id: str,
    days: int = Query(..., gt=0),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    try:
        from uuid import UUID as UUIDType
        uid = UUIDType(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(User).filter(User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    now = datetime.utcnow()
    if user.premium_until and user.premium_until > now:
        user.premium_until = user.premium_until + timedelta(days=days)
    else:
        user.premium_until = now + timedelta(days=days)
    
    user.is_premium = True
    db.commit()
    
    return {
        "message": f"{days} days premium added",
        "premium_until": user.premium_until.isoformat()
    }


@router.post("/users/{user_id}/ban")
def ban_user(
    user_id: str,
    reason: str = Query(...),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    try:
        from uuid import UUID as UUIDType
        uid = UUIDType(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(User).filter(User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_banned = True
    user.is_active = False
    db.commit()
    
    return {"message": f"User {user.username} banned", "reason": reason}


@router.post("/users/{user_id}/unban")
def unban_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    try:
        from uuid import UUID as UUIDType
        uid = UUIDType(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(User).filter(User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_banned = False
    user.is_active = True
    db.commit()
    
    return {"message": f"User {user.username} unbanned"}


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
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    reports = list_reports(db, status=status, skip=skip, limit=limit)
    return [
        {
            "id": str(r.id),
            "reporter_session_id": str(r.reporter_session_id) if r.reporter_session_id else None,
            "reported_session_id": str(r.reported_session_id) if r.reported_session_id else None,
            "reason": r.reason.value if r.reason else "OTHER",
            "description": r.description,
            "status": r.status.value if r.status else "PENDING",
            "created_at": r.created_at.isoformat(),
            "resolved_at": r.resolved_at.isoformat() if r.resolved_at else None,
        }
        for r in reports
    ]


@router.post("/reports/{report_id}/resolve")
def resolve_report(
    report_id: str,
    action: str = Query(..., regex="^(approve|reject)$"),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    from app.models.report import ReportStatus
    report.status = ReportStatus.RESOLVED if action == "approve" else ReportStatus.DISMISSED
    report.resolved_at = datetime.utcnow()
    report.moderator_id = current_admin.id
    db.commit()
    
    return {"message": f"Report {action}d"}


# --- Broadcast Routes ---

@router.post("/broadcast")
def send_broadcast(
    message: str = Query(...),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    # In real implementation, this would send push notifications or websocket messages
    return {"message": "Broadcast sent", "content": message}
