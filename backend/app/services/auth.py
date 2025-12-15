"""
Authentication Service - JWT handling for admin users
NOTE: JWT_SECRET_KEY'i production'da mutlaka değiştirin!
"""
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.config import get_settings

# Lazy settings (circular import önlemek için)
_settings = None

def _get_settings():
    global _settings
    if _settings is None:
        _settings = get_settings()
    return _settings

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Şifreyi hash ile karşılaştır"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Şifreyi hashle"""
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """JWT access token oluştur"""
    settings = _get_settings()
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.JWT_SECRET_KEY, 
        algorithm=settings.JWT_ALGORITHM
    )
    return encoded_jwt


def decode_access_token(token: str) -> Optional[dict]:
    """JWT token'ı decode et ve doğrula"""
    settings = _get_settings()
    try:
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        return payload
    except JWTError:
        return None


from app.models.user import User
from fastapi import WebSocket, WebSocketException
from sqlalchemy.orm import Session

async def get_current_user_ws(token: str, db: Session) -> Optional[User]:
    """WebSocket için token doğrulama ve kullanıcı alma"""
    payload = decode_access_token(token)
    if payload is None:
        return None
    
    email: str = payload.get("sub")
    if email is None:
        return None
        
    user = db.query(User).filter(User.email == email).first()
    return user


from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.database import get_db

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
    
    user_id = token_data.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Kullanıcı bulunamadı",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user


def authenticate_admin(db: Session, email: str, password: str):
    """Admin kullanıcısını doğrula"""
    from app.models.admin import Admin
    
    admin = db.query(Admin).filter(Admin.email == email).first()
    if not admin:
        return None
    if not verify_password(password, admin.password_hash):
        return None
    if not admin.is_active:
        return None
    return admin


def get_admin_by_id(db: Session, admin_id: str):
    """ID ile admin bul"""
    from app.models.admin import Admin
    try:
        from uuid import UUID
        admin_uuid = UUID(admin_id) if isinstance(admin_id, str) else admin_id
        return db.query(Admin).filter(Admin.id == admin_uuid).first()
    except (ValueError, TypeError):
        return None


def create_admin(db: Session, email: str, password: str, name: str = None, role: str = "MODERATOR"):
    """Yeni admin oluştur"""
    from app.models.admin import Admin, AdminRole
    
    admin = Admin(
        email=email,
        password_hash=get_password_hash(password),
        name=name,
        role=AdminRole(role)
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    return admin
