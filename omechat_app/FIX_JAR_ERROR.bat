@echo off
echo ========================================
echo JAR Oluşturma Hatası Düzeltme
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Gradle daemon'ları durduruluyor...
cd android
if exist gradlew.bat (
    call gradlew.bat --stop 2>nul
    echo Daemon durduruldu!
)
cd ..

echo.
echo Step 2: Problemli cache temizleniyor...
if exist "%USERPROFILE%\.gradle\caches\jars-9" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\jars-9" 2>nul
    echo jars-9 cache temizlendi!
)

if exist "%USERPROFILE%\.gradle\daemon" (
    rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
    echo Daemon cache temizlendi!
)

echo.
echo Step 3: Flutter clean...
call flutter clean

echo.
echo Step 4: Flutter pub get...
call flutter pub get

echo.
echo ========================================
echo YAPILANDIRMA:
echo ========================================
echo - Gradle daemon: KAPALI (file locking önlemek için)
echo - Parallel build: KAPALI
echo - Cache: KAPALI
echo - Java: JDK 21 (Android Studio JBR)
echo - Gradle: 8.5
echo - AGP: 8.3.0
echo.
echo Şimdi derlemeyi deneyin:
echo   flutter run
echo.
echo Eğer hala hata alırsanız, Gradle'ı manuel olarak çalıştırın:
echo   cd android
echo   gradlew.bat assembleDebug --no-daemon
echo.
pause

