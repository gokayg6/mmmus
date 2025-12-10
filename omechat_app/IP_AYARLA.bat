@echo off
chcp 65001 >nul
title IP Ayarlama
color 0A

echo.
echo ╔══════════════════════════════════════════════╗
echo ║     PC IP ADRESİNİZİ BULMA VE AYARLAMA      ║
echo ╚══════════════════════════════════════════════╝
echo.

echo PC IP adresiniz:
echo ──────────────────────────────────────────────
ipconfig | findstr /c:"IPv4"
echo ──────────────────────────────────────────────
echo.

set /p USER_IP="IP adresinizi yazın (örnek: 192.168.1.103): "

if "%USER_IP%"=="" (
    echo.
    echo ❌ IP girilmedi!
    pause
    exit /b
)

echo.
echo ⏳ IP ayarlanıyor: %USER_IP%
echo.

cd /d "%~dp0"

powershell -NoProfile -Command "& { $content = Get-Content 'lib\services\api_client.dart' -Raw -Encoding UTF8; $content = $content -replace 'http://192\.168\.\d+\.\d+:8000', 'http://%USER_IP%:8000'; $content = $content -replace 'http://10\.0\.2\.2:8000', 'http://%USER_IP%:8000'; [System.IO.File]::WriteAllText((Resolve-Path 'lib\services\api_client.dart'), $content, [System.Text.Encoding]::UTF8) }"

if errorlevel 1 (
    echo ❌ Hata oluştu!
    pause
    exit /b 1
)

echo.
echo ✅ IP adresi başarıyla ayarlandı!
echo    http://%USER_IP%:8000
echo.
echo ╔══════════════════════════════════════════════╗
echo ║              SONRAKI ADIMLAR                 ║
echo ╚══════════════════════════════════════════════╝
echo.
echo 1. Backend'i başlatın: ..\backend\START_BACKEND.bat
echo.
echo 2. Uygulamayı çalıştırın: flutter run
echo.
echo 3. Her iki telefon aynı Wi-Fi ağında olmalı!
echo.
pause



