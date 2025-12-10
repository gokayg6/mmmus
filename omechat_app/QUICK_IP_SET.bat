@echo off
chcp 65001 >nul
echo ========================================
echo HIZLI IP AYARLAMA
echo ========================================
echo.

echo PC IP adresiniz: 
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set ip=%%a
    set ip=!ip:~1!
    echo   !ip!
)

echo.
echo IP adresinizi yazın (örnek: 192.168.1.103):
set /p USER_IP="> "

if "!USER_IP!"=="" (
    echo IP girilmedi, iptal edildi.
    pause
    exit /b
)

echo.
echo IP ayarlanıyor: !USER_IP!

powershell -Command "$content = Get-Content 'lib\services\api_client.dart' -Raw; $content = $content -replace 'http://192\.168\.\d+\.\d+:8000', 'http://!USER_IP!:8000'; $content = $content -replace 'http://10\.0\.2\.2:8000', 'http://!USER_IP!:8000'; Set-Content 'lib\services\api_client.dart' -Value $content"

echo.
echo ✅ IP adresi başarıyla ayarlandı: http://!USER_IP!:8000
echo.
echo Şimdi uygulamayı yeniden derleyin:
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.
pause



