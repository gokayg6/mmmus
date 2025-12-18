"""
Auth Routes - User authentication endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.user import (
    UserCreate, 
    UserLogin, 
    UserUpdate, 
    UserResponse, 
    AuthResponse
)
from app.services.auth_service import (
    create_user,
    authenticate_user,
    create_access_token,
    decode_access_token,
    get_user_by_email,
    get_user_by_username,
    get_user_by_id,
)
from app.models.user import User

router = APIRouter()
security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user from JWT token"""
    token = credentials.credentials
    
    token_data = decode_access_token(token)
    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz veya süresi dolmuş token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = get_user_by_id(db, token_data.sub)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Kullanıcı bulunamadı",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Hesap devre dışı",
        )
    
    return user


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user account.
    
    - **email**: Valid email address (unique)
    - **username**: 3-50 characters, alphanumeric and underscore only (unique)
    - **password**: Minimum 8 characters
    """
    # Check if email already exists
    existing_email = get_user_by_email(db, user_data.email)
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu e-posta adresi zaten kullanılıyor"
        )
    
    # Check if username already exists
    existing_username = get_user_by_username(db, user_data.username)
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu kullanıcı adı zaten kullanılıyor"
        )
    
    # Create user
    user = create_user(db, user_data)
    
    # Create access token
    access_token = create_access_token(user)
    
    return AuthResponse(
        access_token=access_token,
        user=UserResponse(
            id=str(user.id),
            email=user.email,
            username=user.username,
            avatar_url=user.avatar_url,
            created_at=user.created_at,
            is_active=user.is_active,
            is_premium=user.is_premium,
            premium_until=user.premium_until,
            credits=user.credits,
        )
    )


@router.post("/login", response_model=AuthResponse)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """
    Login with email and password.
    
    Returns access token and user profile.
    """
    user = authenticate_user(db, credentials.email, credentials.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta veya şifre hatalı",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token = create_access_token(user)
    
    return AuthResponse(
        access_token=access_token,
        user=UserResponse(
            id=str(user.id),
            email=user.email,
            username=user.username,
            avatar_url=user.avatar_url,
            created_at=user.created_at,
            is_active=user.is_active,
            is_premium=user.is_premium,
            premium_until=user.premium_until,
            credits=user.credits,
        )
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Get current user profile.
    
    Requires valid access token in Authorization header.
    """
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        username=current_user.username,
        avatar_url=current_user.avatar_url,
        created_at=current_user.created_at,
        is_active=current_user.is_active,
        is_premium=current_user.is_premium,
        premium_until=current_user.premium_until,
        credits=current_user.credits,
    )


@router.put("/me", response_model=UserResponse)
def update_me(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update current user profile.
    
    - **username**: New username (optional, must be unique)
    - **avatar_url**: New avatar URL (optional)
    """
    # Update all provided fields
    update_data_dict = update_data.model_dump(exclude_unset=True)
    
    if 'username' in update_data_dict:
        new_username = update_data_dict['username']
        if new_username != current_user.username:
            existing_username = get_user_by_username(db, new_username)
            if existing_username:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Bu kullanıcı adı zaten kullanılıyor"
                )
            current_user.username = new_username.lower()
        del update_data_dict['username']
        
    for field, value in update_data_dict.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return current_user
