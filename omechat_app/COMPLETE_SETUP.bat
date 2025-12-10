@echo off
chcp 65001 >nul
echo ========================================
echo TAM KURULUM - Hızlı Başlangıç
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] IP Adresi Ayarlama
echo.
echo PC IP adresiniz: 
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set ip=%%a
    set ip=!ip:~1!
    echo   !ip!
)

echo.
echo Yukarıdaki IP adreslerinden birini seçin veya kendi IP'nizi girin:
echo (Örnek: 192.168.1.103)
set /p USER_IP="IP adresi: "

if "!USER_IP!"=="" (
    echo ⚠️ IP girilmedi, varsayılan kullanılacak: 192.168.1.103
    set USER_IP=192.168.1.103
)

echo.
echo IP ayarlanıyor: !USER_IP!
powershell -Command "$content = Get-Content 'lib\services\api_client.dart' -Raw; $content = $content -replace 'http://192\.168\.\d+\.\d+:8000', 'http://!USER_IP!:8000'; $content = $content -replace 'http://10\.0\.2\.2:8000', 'http://!USER_IP!:8000'; Set-Content 'lib\services\api_client.dart' -Value $content"
echo ✅ IP ayarlandı!

echo.
echo [2/4] Flutter packages güncelleniyor...
call flutter pub get
echo ✅ Packages güncellendi!

echo.
echo [3/4] Backend kontrolü...
if exist "..\backend\venv\Scripts\activate.bat" (
    echo ✅ Backend klasörü bulundu
    echo Backend'i başlatmak için START_BACKEND.bat çalıştırın
) else (
    echo ⚠️ Backend klasörü bulunamadı
)

echo.
echo [4/4] Kurulum tamamlandı!
echo.
echo ========================================
echo SONRAKI ADIMLAR:
echo ========================================
echo 1. Backend'i başlatın: ..\backend\START_BACKEND.bat
echo    (VEYA: cd ..\backend ^&^& venv\Scripts\activate ^&^& python -m uvicorn app.main:app --host 0.0.0.0 --port 8000)
echo.
echo 2. Uygulamayı çalıştırın: flutter run
echo.
echo 3. Her iki telefon aynı Wi-Fi ağında olmalı!
echo.
echo ========================================
pause



