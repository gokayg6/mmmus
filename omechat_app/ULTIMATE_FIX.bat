@echo off
echo ========================================
echo ULTIMATE FIX - JAR Oluşturma Hatası
echo ========================================
echo.

cd /d "%~dp0"

echo [1/7] Tüm Gradle process'leri durduruluyor...
taskkill /F /IM java.exe /T 2>nul
taskkill /F /IM gradle.exe /T 2>nul
timeout /t 2 /nobreak >nul
echo Tamamlandı!

echo.
echo [2/7] Gradle daemon durduruluyor...
cd android
if exist gradlew.bat (
    call gradlew.bat --stop 2>nul
)
cd ..
echo Tamamlandı!

echo.
echo [3/7] Problemli cache dizinleri siliniyor...
if exist "%USERPROFILE%\.gradle\caches\jars-9" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\jars-9" 2>nul
)
if exist "%USERPROFILE%\.gradle\daemon" (
    rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
)
timeout /t 1 /nobreak >nul
echo Tamamlandı!

echo.
echo [4/7] Cache dizinleri yeniden oluşturuluyor...
mkdir "%USERPROFILE%\.gradle\caches\jars-9" 2>nul
echo Tamamlandı!

echo.
echo [5/7] Flutter clean...
call flutter clean
echo Tamamlandı!

echo.
echo [6/7] Flutter pub get...
call flutter pub get
echo Tamamlandı!

echo.
echo [7/7] Build test (ilk build daha uzun sürebilir)...
echo.
echo ========================================
echo YAPILANDIRMA:
echo ========================================
echo - Gradle daemon: KAPALI
echo - Parallel build: KAPALI  
echo - Workers: 1 (tek thread)
echo - Cache: KAPALI
echo - Java: JDK 21
echo - Gradle: 8.5
echo - AGP: 8.3.0
echo.
echo NOT: İlk build uzun sürebilir, sabırlı olun!
echo.
echo Derlemeyi başlatıyorum...
call flutter run

pause

