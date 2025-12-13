"""
Admin Seed Script - Creates default admin user
Run: python seed_admin.py
"""
import sys
sys.path.insert(0, '.')

from app.database import get_session_local, create_tables
from app.services.auth import create_admin, get_password_hash
from app.models.admin import Admin

def seed_admin():
    """Create default admin user if not exists"""
    create_tables()
    
    SessionLocal = get_session_local()
    db = SessionLocal()
    
    try:
        # Check if admin exists
        existing = db.query(Admin).filter(Admin.email == "admin@omechat.com").first()
        
        if existing:
            print(f"Admin already exists: {existing.email}")
            return existing
        
        # Create admin
        admin = Admin(
            email="admin@omechat.com",
            password_hash=get_password_hash("admin123"),
            name="Admin",
            role="ADMIN"
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)
        
        print(f"✅ Admin created successfully!")
        print(f"   Email: admin@omechat.com")
        print(f"   Password: admin123")
        print(f"   Role: ADMIN")
        
        return admin
        
    finally:
        db.close()


if __name__ == "__main__":
    seed_admin()

