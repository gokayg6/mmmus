@echo off
chcp 65001 >nul
echo ========================================
echo BACKEND BAŞLATICI
echo ========================================
echo.

cd /d "%~dp0\..\backend"

echo [1] Virtual environment kontrol ediliyor...
if not exist "venv\Scripts\activate.bat" (
    echo ❌ Virtual environment bulunamadı!
    echo Lütfen önce virtual environment oluşturun:
    echo   python -m venv venv
    pause
    exit /b 1
)

echo ✅ Virtual environment bulundu
echo.

echo [2] Virtual environment aktif ediliyor...
call venv\Scripts\activate.bat
echo.

echo [3] Backend başlatılıyor...
echo Backend http://0.0.0.0:8000 adresinde çalışacak
echo.
echo NOT: Bu pencereyi açık tutun!
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause



