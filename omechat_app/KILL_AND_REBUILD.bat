@echo off
chcp 65001 >nul
echo ========================================
echo BUILD DURDUR VE YENİDEN BAŞLAT
echo ========================================
echo.

cd /d "%~dp0"

echo [1/6] Tüm Java process'leri zorla durduruluyor...
taskkill /F /IM java.exe /T 2>nul
timeout /t 2 /nobreak >nul
echo    ✅ Tamamlandı!
echo.

echo [2/6] Gradle daemon durduruluyor...
cd android
if exist gradlew.bat (
    call gradlew.bat --stop 2>nul
)
cd ..
echo    ✅ Tamamlandı!
echo.

echo [3/6] Tüm cache'ler temizleniyor...
if exist "%USERPROFILE%\.gradle\caches" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
)
if exist "%USERPROFILE%\.gradle\daemon" (
    rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
)
echo    ✅ Tamamlandı!
echo.

echo [4/6] Flutter clean...
call flutter clean
echo    ✅ Tamamlandı!
echo.

echo [5/6] Flutter pub get...
call flutter pub get
echo    ✅ Tamamlandı!
echo.

echo [6/6] Yeni build başlatılıyor...
echo.
echo ========================================
echo Build başladı, lütfen bekleyin...
echo Bu işlem 3-5 dakika sürebilir.
echo ========================================
echo.

call flutter run -d "sdk gphone64 x86 64"

pause

