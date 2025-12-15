
import sys
import os
import traceback

# Backend dizinini ayarla
backend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(backend_dir)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

log_file = open("startup_error.log", "w", encoding="utf-8")

def log(msg):
    print(msg)
    log_file.write(msg + "\n")
    log_file.flush()

try:
    log("1. Importing app.config...")
    from app.config import get_settings
    
    log("2. Importing app.database...")
    from app.database import create_tables, get_db
    
    log("3. Importing app.services.auth...")
    from app.services import auth
    
    log("4. Importing app.services.auth_service...")
    try:
        from app.services import auth_service
    except Exception as e:
        log(f"Warning: auth_service import failed: {e}")

    log("5. Importing app.routes.public...")
    from app.routes import public
    
    log("6. Importing app.routes.friends...")
    from app.routes import friends
    
    log("7. Importing app.routes.chat...")
    from app.routes import chat
    
    log("8. Importing app.main...")
    from app import main
    
    log("All imports successful!")
    
except Exception:
    log("\nCRITICAL FAILURE!")
    traceback.print_exc(file=log_file)
    traceback.print_exc()
finally:
    log_file.close()
