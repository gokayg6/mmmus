from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from ..database import get_db
from ..models.user import User
from ..dependencies import get_current_user

router = APIRouter(prefix="/user", tags=["settings"])

# ═══════════════════════════════════════════════════════════
# REQUEST/RESPONSE MODELS
# ═══════════════════════════════════════════════════════════

class UserSettingsResponse(BaseModel):
    language_code: str
    
    class Config:
        from_attributes = True

class UpdateUserSettingsRequest(BaseModel):
    language_code: Optional[str] = None

# ═══════════════════════════════════════════════════════════
# ENDPOINTS
# ═══════════════════════════════════════════════════════════

@router.get("/settings", response_model=UserSettingsResponse)
async def get_user_settings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user settings including language preference
    """
    return UserSettingsResponse(
        language_code=current_user.language_code
    )

@router.patch("/settings")
async def update_user_settings(
    settings: UpdateUserSettingsRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update user settings (language, etc)
    """
    # Update language if provided
    if settings.language_code is not None:
        # Validate language code (optional: add more validation)
        if settings.language_code not in ['en', 'tr']:
            raise HTTPException(status_code=400, detail="Unsupported language code")
        
        current_user.language_code = settings.language_code
    
    db.commit()
    db.refresh(current_user)
    
    return {
        "success": True,
        "message": "Settings updated successfully",
        "language_code": current_user.language_code
    }
