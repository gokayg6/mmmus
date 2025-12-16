
# OmeChat Backend - Consolidated Entry Point
# Bu dosya tüm yapılandırmayı ve başlatma işlemini tek yerden yönetir.
import os
import sys
import socket

# Backend dizinini ayarla
backend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(backend_dir)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Local imports
try:
    from app.config import get_settings
    from app.routes import public, admin, websocket, auth, features, chat, friends, settings
    from app.database import create_tables, get_db
except ImportError as e:
    print(f"CRITICAL ERROR: Import failed - {e}")
    print("Ensure you are running this from the 'backend' directory.")
    sys.exit(1)

settings = get_settings()

def get_local_ip():
    try:
        # Dummy connection to determine IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

# --- LIFESPAN (Startup/Shutdown) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print(">>> OmeChat Backend Initializing...")
    try:
        print(">>> Checking Database...")
        create_tables()
        print(">>> Database OK.")
    except Exception as e:
        print(f">>> DATABASE ERROR: {e}")
    yield
    print(">>> Shutting down...")

# --- APP DEFINITION ---
app = FastAPI(
    title="OmeChat Backend",
    version="2.0.0",
    lifespan=lifespan,
    description="Consolidated OmeChat Backend"
)

# --- CORS & MIDDLEWARE ---
# En geniş izinleri veriyoruz (Development için)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    # Basit logging middleware
    print(f"REQ: {request.method} {request.url}")
    try:
        response = await call_next(request)
        print(f"RES: {response.status_code}")
        return response
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"ERR: {e}")
        # Don't handle here - let global exception handler catch it
        raise

# Global exception handler - NEVER return 500 for user errors
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Catch ALL unhandled exceptions.
    CRITICAL: Return 503 (Service Unavailable) instead of 500 for server errors.
    This signals temporary failure (retryable) instead of code bug.
    """
    import traceback
    import logging
    
    logger = logging.getLogger(__name__)
    
    # Log full traceback for debugging
    logger.error(f"Unhandled exception at {request.method} {request.url}")
    logger.error(f"Exception type: {type(exc).__name__}")
    logger.error(traceback.format_exc())
    
    # Return 503 with retry indicator
    return JSONResponse(
        status_code=503,
        content={
            "detail": "Service temporarily unavailable. Please retry.",
            "type": "server_error",
            "retryable": True
        }
    )

# --- ROUTERS ---
app.include_router(public.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(features.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(friends.router, prefix="/api/v1")
app.include_router(settings.router, prefix="/api/v1")
app.include_router(websocket.router)

@app.get("/")
def read_root():
    return {
        "status": "online", 
        "message": "OmeChat Backend is Running",
        "access": "public"
    }

# --- ENTRY POINT ---
if __name__ == "__main__":
    local_ip = get_local_ip()
    port = 8001
    
    print("\n" + "="*60)
    print("   OMECHAT BACKEND - UNIVERSAL SERVER")
    print("   Rewritten for Stability & Connection Fixes")
    print("="*60)
    print(f"   STATUS:  Starting...")
    print(f"   HOST:    0.0.0.0 (All Interfaces)")
    print(f"   PORT:    {port}")
    print(f"   LOCAL:   http://localhost:{port}")
    print(f"   NETWORK: http://{local_ip}:{port}")
    print("-" * 60)
    print("   Make sure your Flutter App Config matches the NETWORK IP!")
    print("="*60 + "\n")
    
    try:
        uvicorn.run(
            app,  # Pass the app object directly
            host="0.0.0.0",
            port=port,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n>>> Server stopped by user.")
    except Exception as e:
        print(f"\n>>> CRITICAL SERVER ERROR: {e}")
        input("Press Enter to exit...")
