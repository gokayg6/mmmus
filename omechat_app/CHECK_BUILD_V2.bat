@echo off
chcp 65001 >nul
echo ========================================
echo BUILD DURUM KONTROLÜ v2
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Çalışan Java Process'leri:
tasklist | findstr /I "java.exe"
echo.

echo [2] APK Dosyası Kontrolü:
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo    ✅ BAŞARILI! APK oluşturuldu!
    dir "build\app\outputs\flutter-apk\app-debug.apk"
) else (
    echo    ❌ APK henüz oluşmadı
)
echo.

echo [3] Gradle Build Durumu:
cd android
if exist gradlew.bat (
    echo    Gradle durumu kontrol ediliyor...
    gradlew.bat tasks --all 2>nul | findstr /C:"assembleDebug" | findstr /V "help"
)
cd ..
echo.

echo [4] Son Hatalar (PowerShell ile okunuyor):
powershell -Command "Get-ChildItem '%TEMP%' -Filter 'flutter_build*.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Get-Content $_.FullName -Encoding UTF8 -Tail 30 | Select-String -Pattern 'FAILURE|Error|gradle-1.0.0.jar|What went wrong' -Context 2 }"
echo.

echo ========================================
echo Build devam ediyorsa birkaç dakika bekleyin
echo veya STOP_AND_REBUILD.bat ile yeniden başlatın
echo ========================================
echo.

pause

