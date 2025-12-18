"""
OmeChat Backend - Main Application Entry Point
"""
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import get_settings
from app.config import get_settings
from fastapi.staticfiles import StaticFiles

# ... imports ...
from app.routes import public, admin, websocket, auth, features, friends, chat, points, upload

from app.database import create_tables

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Tabloları oluştur (Development için)
    # Production'da Alembic kullanılmalı
    if settings.DEBUG:
        print("Creating database tables...")
        create_tables()
        
    yield
    
    # Shutdown: Kaynakları temizle (varsa Redis connection vs.)
    print("Shutting down...")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
    description="OmeChat Backend API & Signaling Server"
)

# CORS Configuration - Tüm cihazlar için açık
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tüm origin'lere izin (development)
    allow_credentials=True,
    allow_methods=["*"],  # Tüm HTTP metodları
    allow_headers=["*"],  # Tüm header'lar
    expose_headers=["*"],  # Tüm header'ları expose et
)

# Mount uploads directory to /uploads
# Ensure directories exist first
import os
os.makedirs("uploads", exist_ok=True)
os.makedirs("static", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/static", StaticFiles(directory="static", html=True), name="static")

# Register Routers
app.include_router(public.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(points.router, prefix="/api/v1")
app.include_router(features.router, prefix="/api/v1")
app.include_router(friends.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(upload.router, prefix="/api/v1")
app.include_router(websocket.router)


@app.get("/")
def read_root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running"
    }


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=settings.DEBUG
    )
