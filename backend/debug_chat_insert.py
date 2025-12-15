
import sys
import os
import uuid
from datetime import datetime

# Setup path
sys.path.append(os.getcwd())

from app.database import get_db, create_tables
from app.models.user import User
from app.models.message import Message
from app.services.auth import get_password_hash

def test_insert_message():
    print(">>> Testing Message Insert...")
    
    # Get DB session
    db = next(get_db())
    
    try:
        # 1. Create two test users
        u1_id = uuid.uuid4()
        u2_id = uuid.uuid4()
        
        user1 = User(
            id=u1_id,
            email=f"test1_{u1_id.hex[:8]}@example.com",
            username=f"user1_{u1_id.hex[:8]}",
            password_hash=get_password_hash("secret"),
            active_character_id="default"
        )
        
        user2 = User(
            id=u2_id,
            email=f"test2_{u2_id.hex[:8]}@example.com",
            username=f"user2_{u2_id.hex[:8]}",
            password_hash=get_password_hash("secret"),
            active_character_id="default"
        )
        
        print(">>> Adding users...")
        db.add(user1)
        db.add(user2)
        db.commit()
        print(">>> Users added.")
        
        # 2. Try to add message
        print(">>> Adding message...")
        msg = Message(
            sender_id=u1_id,
            receiver_id=u2_id,
            content="Hello World Test"
        )
        db.add(msg)
        db.commit()
        db.refresh(msg)
        print(f">>> Message added successfully: {msg.id}")
        
    except Exception as e:
        import traceback
        with open("debug_error.log", "w") as f:
            f.write(traceback.format_exc())
            f.write(f"\nERROR: {e}")
        print(f">>> ERROR: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    test_insert_message()
