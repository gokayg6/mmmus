@echo off
REM OmeChat Backend - Universal Start Script
REM Tüm cihazlardan erişilebilir

echo ============================================================
echo OmeChat Backend Starting...
echo ============================================================
echo Host: 0.0.0.0 (All interfaces)
echo Port: 8000
echo.
echo Accessible from:
echo   - Local: http://localhost:8000
echo   - Network: http://192.168.1.103:8000
echo   - All devices on same network
echo ============================================================
echo.

cd /d %~dp0
set PYTHONPATH=%~dp0;%PYTHONPATH%
python start_backend.py

pause

