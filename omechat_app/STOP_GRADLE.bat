@echo off
echo ========================================
echo Gradle Daemon'ları Durduruluyor...
echo ========================================
echo.

cd /d "%~dp0\android"

if exist gradlew.bat (
    echo Gradle daemon durduruluyor...
    call gradlew.bat --stop
    echo Daemon durduruldu!
) else (
    echo gradlew.bat bulunamadı!
)

echo.
echo Cache temizleniyor...
if exist "%USERPROFILE%\.gradle\caches\jars-9" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\jars-9" 2>nul
    echo jars-9 cache temizlendi!
)

if exist "%USERPROFILE%\.gradle\daemon" (
    rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
    echo Gradle daemon cache temizlendi!
)

echo.
echo TAMAMLANDI!
echo Şimdi tekrar deneyin: flutter run
echo.
pause

