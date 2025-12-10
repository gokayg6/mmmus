@echo off
chcp 65001 >nul
echo ========================================
echo BUILD BEKLEME VE KONTROL
echo ========================================
echo.

cd /d "%~dp0"

:CHECK_LOOP
echo [%TIME%] Kontrol ediliyor...
echo.

echo 1. Java Process'leri:
tasklist | findstr /I "java.exe" | find /C "java.exe"
if errorlevel 1 (
    echo    ❌ Java process yok - Build tamamlanmış veya durmuş
    goto :CHECK_APK
) else (
    echo    ✅ Build hala çalışıyor
)
echo.

:CHECK_APK
echo 2. APK Dosyası:
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo    ✅ BAŞARILI! APK oluşturuldu!
    dir "build\app\outputs\flutter-apk\app-debug.apk"
    echo.
    echo ========================================
    echo BUILD BAŞARILI! 🎉
    echo ========================================
    goto :END
) else (
    echo    ❌ APK henüz yok
)
echo.

echo 3. Build Klasörü Durumu:
if exist "build" (
    echo    ✅ Build klasörü mevcut
    for /f %%i in ('dir /s /b build 2^>nul ^| find /c /v ""') do set FILE_COUNT=%%i
    echo    Dosya sayısı: %FILE_COUNT%
) else (
    echo    ❌ Build klasörü yok
)
echo.

echo ========================================
echo 30 saniye bekleniyor, sonra tekrar kontrol edilecek...
echo Çıkmak için Ctrl+C basın
echo ========================================
echo.

timeout /t 30 /nobreak >nul
goto :CHECK_LOOP

:END
pause

