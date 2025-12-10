@echo off
echo ========================================
echo BUILD DURUM KONTROLÜ
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Çalışan process'ler kontrol ediliyor...
tasklist | findstr /I "java.exe gradle.exe flutter.exe"
if errorlevel 1 (
    echo Build process'i bulunamadı - build tamamlanmış olabilir
) else (
    echo Build hala çalışıyor...
)
echo.

echo [2] APK dosyası kontrol ediliyor...
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ✅ BAŞARILI! APK oluşturuldu!
    dir "build\app\outputs\flutter-apk\app-debug.apk"
) else (
    echo ❌ APK henüz oluşmadı
)
echo.

echo [3] Son build log'ları kontrol ediliyor...
if exist "%TEMP%\flutter_build*.log" (
    echo Son log dosyası bulundu
    for %%f in ("%TEMP%\flutter_build*.log") do (
        echo Dosya: %%~f
        findstr /C:"FAILURE" /C:"SUCCESSFUL" /C:"Error" "%%~f" | findstr /N ".*"
    )
) else (
    echo Log dosyası bulunamadı
)
echo.

pause

