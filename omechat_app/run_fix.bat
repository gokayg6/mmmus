@echo off
echo ==================================================
echo   OmeChat Safe Runner (Fixes Shader & APK Errors)
echo ==================================================

:: 1. Create Junction if it doesn't exist (Force check)
if not exist "C:\OmeChat" (
    echo Creating safe path link C:\OmeChat...
    mklink /J "C:\OmeChat" "C:\Users\gokay\Desktop\Yeni klasör\omechat_app"
)

:: 2. Switch to safe path
cd /d "C:\OmeChat"
echo Working directory: %CD%

:: 3. Clean environment (Important!)
echo.
echo Cleaning stale build artifacts...
call flutter clean

:: 4. Run Flutter
echo.
echo Running App...
echo (If asked to choose a device, type the number and press Enter)
call flutter run

echo.
pause
