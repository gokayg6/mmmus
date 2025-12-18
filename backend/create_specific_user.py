
import sys
sys.path.insert(0, '.')

from app.database import get_session_local
from app.models.user import User
from app.services.auth import get_password_hash

def create_user():
    SessionLocal = get_session_local()
    db = SessionLocal()
    
    email = "gokaygulustan1@gmail.com"
    username = "gokay"
    password = "gokay777"
    
    try:
        # Check if user exists
        existing_user = db.query(User).filter((User.email == email) | (User.username == username)).first()
        if existing_user:
            print(f"User already exists: {existing_user.email} / {existing_user.username}")
            # Optional: Update password if exists?
            # existing_user.password_hash = get_password_hash(password)
            # db.commit()
            # print("Password updated.")
            return

        new_user = User(
            email=email,
            username=username,
            password_hash=get_password_hash(password),
            is_active=True
        )
        
        db.add(new_user)
        db.commit()
        print(f"User created successfully: {email} / {username}")
        
    except Exception as e:
        print(f"Error creating user: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_user()
