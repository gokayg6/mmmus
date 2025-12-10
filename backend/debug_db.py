import sys
import os

# Add the current directory to sys.path so we can import 'app'
sys.path.append(os.getcwd())

from app.database import get_session_local, create_tables
from app.models.user import User
from app.schemas.user import UserCreate
from app.services.auth_service import create_user
from sqlalchemy.exc import SQLAlchemyError

def test_db_insert():
    print("Testing Database Insertion...")
    
    # 1. Initialize DB (make sure tables exist)
    try:
        create_tables()
        print("Database initialized successfully.")
    except Exception as e:
        print(f"CRITICAL: Failed to initialize database: {e}")
        import traceback
        traceback.print_exc()
        return

    # 2. Try to create a user
    SessionLocal = get_session_local()
    db = SessionLocal()
    try:
        # Create a dummy user data
        user_input = UserCreate(
            email="test_debug@example.com",
            username="debug_user",
            password="password123"
        )
        
        # Check if user exists first to clean up
        existing = db.query(User).filter(User.email == "test_debug@example.com").first()
        if existing:
            print("User already exists, deleting...")
            db.delete(existing)
            db.commit()

        print("Attempting to create user...")
        user = create_user(db, user_input)
        print(f"SUCCESS: User created with ID: {user.id}")
        
    except SQLAlchemyError as e:
        print(f"SQLALCHEMY ERROR: {e}")
        import traceback
        traceback.print_exc()
    except Exception as e:
        print(f"GENERAL ERROR: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    with open("debug_result.txt", "w", encoding="utf-8") as f:
        sys.stdout = f
        sys.stderr = f
        test_db_insert()
