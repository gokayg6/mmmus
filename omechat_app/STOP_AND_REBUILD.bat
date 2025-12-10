@echo off
echo ========================================
echo DURDUR VE YENİDEN BUILD
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Tüm Java process'leri durduruluyor...
taskkill /F /IM java.exe /T 2>nul
timeout /t 2 /nobreak >nul
echo    Tamamlandı!
echo.

echo [2] Gradle daemon durduruluyor...
cd android
if exist gradlew.bat (
    call gradlew.bat --stop 2>nul
)
cd ..
echo    Tamamlandı!
echo.

echo [3] Cache temizleniyor...
if exist "%USERPROFILE%\.gradle\caches\jars-9" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\jars-9" 2>nul
)
echo    Tamamlandı!
echo.

echo [4] Flutter clean...
call flutter clean
echo    Tamamlandı!
echo.

echo [5] Flutter pub get...
call flutter pub get
echo    Tamamlandı!
echo.

echo [6] Build başlatılıyor...
echo    Build başladı, lütfen bekleyin...
echo.
call flutter run -d "sdk gphone64 x86 64"

pause

