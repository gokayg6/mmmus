"""
Debug script to check database and authentication
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app.database import get_session_local
from app.models.user import User
from app.services.auth_service import verify_password, get_password_hash

SessionLocal = get_session_local()
db = SessionLocal()

print("=" * 60)
print("DATABASE DEBUG")
print("=" * 60)

# Check all users
users = db.query(User).all()
print(f"\nTotal users in database: {len(users)}")

for user in users:
    print(f"\n--- User ---")
    print(f"ID: {user.id}")
    print(f"Email: {user.email}")
    print(f"Username: {user.username}")
    print(f"Password Hash: {user.password_hash[:50]}...")
    print(f"Is Active: {user.is_active}")
    print(f"Created: {user.created_at}")
    
    # Test password verification
    test_password = "testpass123"
    is_valid = verify_password(test_password, user.password_hash)
    print(f"Password '{test_password}' valid: {is_valid}")

# Test password hashing
print("\n" + "=" * 60)
print("PASSWORD HASHING TEST")
print("=" * 60)
test_pass = "testpass123"
hashed = get_password_hash(test_pass)
print(f"Original: {test_pass}")
print(f"Hashed: {hashed[:50]}...")
print(f"Verification: {verify_password(test_pass, hashed)}")

db.close()
