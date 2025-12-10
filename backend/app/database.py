"""
Database Configuration and Session Management
NOTE: PostgreSQL bağlantı hatası alırsanız:
  1) PostgreSQL servisinin çalıştığından emin olun
  2) .env dosyasındaki DATABASE_URL'yi kontrol edin
  3) 'omechat' veritabanının oluşturulduğundan emin olun
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Base'i burada tanımlıyoruz - modeller bunu import edecek
Base = declarative_base()

# Engine ve SessionLocal'ı lazy olarak oluşturuyoruz (circular import önlemek için)
_engine = None
_SessionLocal = None


def get_engine():
    """Engine'i lazy olarak oluştur"""
    global _engine
    if _engine is None:
        from app.config import get_settings
        settings = get_settings()
        _engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            pool_size=10,
            max_overflow=20,
            echo=settings.DEBUG,
            connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
        )
    return _engine


def get_session_local():
    """SessionLocal'ı lazy olarak oluştur"""
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(
            autocommit=False, 
            autoflush=False, 
            bind=get_engine()
        )
    return _SessionLocal


def get_db():
    """FastAPI dependency - her request için yeni session"""
    SessionLocal = get_session_local()
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_tables():
    """Tüm tabloları oluştur (development için)"""
    # Tüm modelleri import et ki Base.metadata dolu olsun
    from app.models import user_session, connection, report, ban, admin, metrics, user
    Base.metadata.create_all(bind=get_engine())
