"""
API Routes Package
"""
from app.routes.public import router as public_router
from app.routes.admin import router as admin_router
from app.routes.websocket import router as websocket_router
from app.routes.auth import router as auth_router

__all__ = ["public_router", "admin_router", "websocket_router", "auth_router"]
