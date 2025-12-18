
import os
import shutil
import uuid
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/upload", tags=["upload"])

UPLOAD_DIR = Path("uploads")
AVATAR_DIR = UPLOAD_DIR / "avatars"

# Ensure directories exist
AVATAR_DIR.mkdir(parents=True, exist_ok=True)

@router.post("/avatar")
async def upload_avatar(file: UploadFile = File(...)):
    """
    Upload user avatar. Returns the public URL.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only image files are allowed"
        )
    
    # Generate unique filename
    file_extension = os.path.splitext(file.filename)[1]
    if not file_extension:
        file_extension = ".jpg" # Default fallback
        
    filename = f"{uuid.uuid4()}{file_extension}"
    file_path = AVATAR_DIR / filename
    
    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Return public URL (assuming /static mount point)
        # In production this might be an S3 URL
        return {"url": f"/static/avatars/{filename}"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not save file: {str(e)}"
        )
