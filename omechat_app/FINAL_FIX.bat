@echo off
echo ========================================
echo FINAL FIX - Java 21 + Gradle 8.5 + AGP 8.3
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Cleaning everything...
call flutter clean
if exist "%USERPROFILE%\.gradle\caches" (
    echo Cleaning Gradle cache...
    rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
    echo Gradle cache cleaned!
)

echo.
echo Step 2: Getting packages...
call flutter pub get

echo.
echo Step 3: Building...
echo Configuration:
echo   - Java: JDK 21 (Android Studio JBR)
echo   - Gradle: 8.5 (supports Java 21)
echo   - Android Gradle Plugin: 8.3.0
echo   - All plugins configured for Java 17
echo.

call flutter run

pause

