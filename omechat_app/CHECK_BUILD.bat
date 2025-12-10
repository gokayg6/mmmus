@echo off
echo ========================================
echo BUILD DURUM KONTROLÜ
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Çalışan Java Process'leri:
tasklist | findstr /I "java.exe"
if errorlevel 1 (
    echo    Build tamamlanmış olabilir - Java process yok
) else (
    echo    Build hala çalışıyor...
)
echo.

echo [2] APK Dosyası Kontrolü:
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo    ✅ BAŞARILI! APK oluşturuldu!
    echo    Dosya bilgileri:
    dir "build\app\outputs\flutter-apk\app-debug.apk"
) else (
    echo    ❌ APK henüz oluşmadı
    echo    Build hala devam ediyor olabilir...
)
echo.

echo [3] Build Klasörü Kontrolü:
if exist "build" (
    echo    Build klasörü mevcut
    dir "build\app\outputs\flutter-apk\" 2>nul
) else (
    echo    Build klasörü henüz oluşmadı
)
echo.

echo [4] Hata Log Kontrolü:
if exist "%TEMP%\flutter_build*.log" (
    echo    Log dosyaları bulundu, kontrol ediliyor...
    for %%f in ("%TEMP%\flutter_build*.log") do (
        findstr /C:"FAILURE" /C:"Error" /C:"gradle-1.0.0.jar" "%%~f" >nul
        if not errorlevel 1 (
            echo    HATA BULUNDU: %%~f
            findstr /C:"FAILURE" /C:"Error" /C:"gradle-1.0.0.jar" "%%~f" | findstr /N ".*"
        )
    )
) else (
    echo    Log dosyası bulunamadı
)
echo.

echo ========================================
echo NOT: Eğer build hala çalışıyorsa,
echo      birkaç dakika bekleyip tekrar çalıştırın.
echo ========================================
echo.

pause

