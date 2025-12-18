from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List
from pydantic import BaseModel
import uuid

from app.database import get_db
from app.models.user import User
from app.models.points import PointsHistory
from app.routes.auth import get_current_user

router = APIRouter(prefix="/points", tags=["points"])

class PointsActionRequest(BaseModel):
    action_type: str

class PointsHistoryResponse(BaseModel):
    amount: int
    action_type: str
    description: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class PointsResponse(BaseModel):
    current_credits: int
    history: List[PointsHistoryResponse]

# Point Values
POINT_VALUES = {
    "DAILY_LOGIN": 10,
    "WATCH_AD": 5,
    "INVITE_FRIEND": 50,
}

@router.get("/history", response_model=PointsResponse)
def get_points_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 20
):
    """Get user's points history"""
    history = db.query(PointsHistory)\
        .filter(PointsHistory.user_id == current_user.id)\
        .order_by(PointsHistory.created_at.desc())\
        .limit(limit)\
        .all()
        
    return PointsResponse(
        current_credits=current_user.credits,
        history=history
    )

@router.post("/claim/daily", response_model=PointsResponse)
def claim_daily_login(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Claim daily login reward"""
    # Check if already claimed today
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    existing = db.query(PointsHistory)\
        .filter(PointsHistory.user_id == current_user.id)\
        .filter(PointsHistory.action_type == "DAILY_LOGIN")\
        .filter(PointsHistory.created_at >= today_start)\
        .first()
        
    if existing:
        raise HTTPException(
            status_code=400, 
            detail="Günlük ödül zaten alındı. Yarın tekrar gel!"
        )
    
    points = POINT_VALUES["DAILY_LOGIN"]
    
    # Add points
    current_user.credits += points
    
    # Log history
    history = PointsHistory(
        user_id=current_user.id,
        amount=points,
        action_type="DAILY_LOGIN",
        description="Günlük giriş ödülü"
    )
    db.add(history)
    db.commit()
    db.refresh(current_user)
    
    return get_points_history(current_user, db, limit=5)

@router.post("/purchase/mock", response_model=PointsResponse)
def mock_purchase_credits(
    amount: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mock endpoint to purchase credits (for testing)"""
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Miktar pozitif olmalı")
        
    # Add points
    current_user.credits += amount
    
    # Log history
    history = PointsHistory(
        user_id=current_user.id,
        amount=amount,
        action_type="PURCHASE",
        description=f"{amount} kredi satın alındı"
    )
    db.add(history)
    db.commit()
    db.refresh(current_user)
    
    return get_points_history(current_user, db, limit=5)
