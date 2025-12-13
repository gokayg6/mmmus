"""
Features Routes - Unlock premium features with credits
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from app.database import get_db
from app.models.user import User
from app.routes.auth import get_current_user

router = APIRouter(prefix="/features", tags=["features"])


# Feature costs
FEATURE_COSTS = {
    "gender_filter": 30,
    "country_filter": 20,
    "reconnect": 40,
    "hd_quality": 15,
    "face_filters": 10,
    "vip_badge": 50,
}


class FeatureStatusResponse(BaseModel):
    feature: str
    is_unlocked: bool
    is_premium_feature: bool
    cost: int
    user_credits: int
    can_afford: bool


class UnlockFeatureResponse(BaseModel):
    success: bool
    message: str
    feature: str
    credits_spent: int
    remaining_credits: int


class UserFeaturesResponse(BaseModel):
    credits: int
    is_premium: bool
    premium_until: Optional[str]
    gender_filter_unlocked: bool
    country_filter_unlocked: bool
    reconnect_unlocked: bool
    hd_quality_unlocked: bool
    face_filters_unlocked: bool
    vip_badge_unlocked: bool
    # Computed fields - can use features if premium OR unlocked
    can_use_gender_filter: bool
    can_use_country_filter: bool
    can_use_reconnect: bool
    can_use_hd_quality: bool
    can_use_face_filters: bool
    can_use_vip_badge: bool


@router.get("/status", response_model=UserFeaturesResponse)
def get_features_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's feature unlock status and credits"""
    is_premium_active = (
        current_user.is_premium and 
        current_user.premium_until and 
        current_user.premium_until > datetime.utcnow()
    )
    
    return UserFeaturesResponse(
        credits=current_user.credits,
        is_premium=current_user.is_premium,
        premium_until=current_user.premium_until.isoformat() if current_user.premium_until else None,
        gender_filter_unlocked=current_user.gender_filter_unlocked,
        country_filter_unlocked=current_user.country_filter_unlocked,
        reconnect_unlocked=current_user.reconnect_unlocked,
        hd_quality_unlocked=current_user.hd_quality_unlocked,
        face_filters_unlocked=current_user.face_filters_unlocked,
        vip_badge_unlocked=current_user.vip_badge_unlocked,
        # Premium users can use all features
        can_use_gender_filter=is_premium_active or current_user.gender_filter_unlocked,
        can_use_country_filter=is_premium_active or current_user.country_filter_unlocked,
        can_use_reconnect=is_premium_active or current_user.reconnect_unlocked,
        can_use_hd_quality=is_premium_active or current_user.hd_quality_unlocked,
        can_use_face_filters=is_premium_active or current_user.face_filters_unlocked,
        can_use_vip_badge=is_premium_active or current_user.vip_badge_unlocked,
    )


@router.get("/check/{feature_name}", response_model=FeatureStatusResponse)
def check_feature(
    feature_name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if a specific feature is available"""
    if feature_name not in FEATURE_COSTS:
        raise HTTPException(status_code=400, detail=f"Unknown feature: {feature_name}")
    
    cost = FEATURE_COSTS[feature_name]
    
    # Check if unlocked
    is_unlocked = getattr(current_user, f"{feature_name}_unlocked", False)
    
    # Check if premium active
    is_premium_active = (
        current_user.is_premium and 
        current_user.premium_until and 
        current_user.premium_until > datetime.utcnow()
    )
    
    return FeatureStatusResponse(
        feature=feature_name,
        is_unlocked=is_unlocked or is_premium_active,
        is_premium_feature=is_premium_active,
        cost=cost,
        user_credits=current_user.credits,
        can_afford=current_user.credits >= cost,
    )


@router.post("/unlock/{feature_name}", response_model=UnlockFeatureResponse)
def unlock_feature(
    feature_name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Unlock a feature by spending credits"""
    if feature_name not in FEATURE_COSTS:
        raise HTTPException(status_code=400, detail=f"Unknown feature: {feature_name}")
    
    cost = FEATURE_COSTS[feature_name]
    field_name = f"{feature_name}_unlocked"
    
    # Check if already unlocked
    if getattr(current_user, field_name, False):
        return UnlockFeatureResponse(
            success=True,
            message="Bu özellik zaten açık!",
            feature=feature_name,
            credits_spent=0,
            remaining_credits=current_user.credits,
        )
    
    # Check if premium (premium users don't need to unlock)
    if current_user.is_premium and current_user.premium_until and current_user.premium_until > datetime.utcnow():
        return UnlockFeatureResponse(
            success=True,
            message="Premium üyeler bu özelliği ücretsiz kullanır!",
            feature=feature_name,
            credits_spent=0,
            remaining_credits=current_user.credits,
        )
    
    # Check if user has enough credits
    if current_user.credits < cost:
        raise HTTPException(
            status_code=400, 
            detail=f"Yetersiz kredi! {cost} kredi gerekli, {current_user.credits} krediniz var."
        )
    
    # Deduct credits and unlock feature
    current_user.credits -= cost
    setattr(current_user, field_name, True)
    
    db.commit()
    db.refresh(current_user)
    
    return UnlockFeatureResponse(
        success=True,
        message=f"{feature_name.replace('_', ' ').title()} özelliği açıldı!",
        feature=feature_name,
        credits_spent=cost,
        remaining_credits=current_user.credits,
    )


@router.get("/costs")
def get_feature_costs():
    """Get all feature costs"""
    return {
        "features": [
            {"name": "gender_filter", "display_name": "Cinsiyet Filtresi", "cost": 30, "description": "Kadın veya erkek seçimi"},
            {"name": "country_filter", "display_name": "Ülke Filtresi", "cost": 20, "description": "Belirli ülkelerle eşleş"},
            {"name": "reconnect", "display_name": "Yeniden Bağlan", "cost": 40, "description": "Aynı kişiyle tekrar bağlan"},
            {"name": "hd_quality", "display_name": "HD Kalite", "cost": 15, "description": "Yüksek çözünürlüklü video"},
            {"name": "face_filters", "display_name": "Yüz Filtreleri", "cost": 10, "description": "Eğlenceli yüz efektleri"},
            {"name": "vip_badge", "display_name": "VIP Rozet", "cost": 50, "description": "Özel VIP rozeti"},
        ]
    }

