"""Debug script to test auth endpoints"""
import sys
sys.path.insert(0, '.')

from app.database import get_engine, Base, get_session_local
from app.models.user import User
from app.services.auth_service import get_password_hash, create_user
from app.schemas.user import UserCreate

# Create tables
print("Creating tables...")
from app.models import user_session, connection, report, ban, admin, metrics, user
Base.metadata.create_all(bind=get_engine())

# Test user creation
print("Testing user creation...")
SessionLocal = get_session_local()
db = SessionLocal()

try:
    # Create user directly
    hashed = get_password_hash("test123456")
    print(f"Password hashed: {hashed[:20]}...")
    
    test_user = User(
        email="debug@test.com",
        username="debuguser",
        password_hash=hashed
    )
    db.add(test_user)
    db.commit()
    db.refresh(test_user)
    print(f"User created: {test_user.id}")
    print("SUCCESS!")
except Exception as e:
    print(f"ERROR: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
