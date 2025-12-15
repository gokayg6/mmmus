@echo off
chcp 65001 >nul
color 0A
cls

echo ╔════════════════════════════════════════════════════════════╗
echo ║         OMECHAT BACKEND SERVER - BASIT BAŞLATICI           ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Get local IP address
echo [1/3] Yerel IP adresi tespit ediliyor...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set "IP=%%a"
    goto :found_ip
)
:found_ip
set IP=%IP:~1%
echo     ✓ IP Adresi: %IP%
echo.

REM Check if Python is available
echo [2/3] Python kontrol ediliyor...
python --version >nul 2>&1
if errorlevel 1 (
    echo     ✗ HATA: Python bulunamadı!
    echo     Python'u yükleyin: https://www.python.org/downloads/
    pause
    exit /b 1
)
echo     ✓ Python bulundu
echo.

REM Start the backend server
echo [3/3] Backend sunucusu başlatılıyor...
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                   SUNUCU BİLGİLERİ                         ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  YEREL:   http://localhost:8000                            ║
echo ║  AĞ:      http://%IP%:8000                    ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  ÖNEMLİ: Flutter uygulamanızda bu IP'yi kullanın:          ║
echo ║           http://%IP%:8000                    ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Flutter app_config.dart dosyasını güncelleyin:
echo   developmentBackendUrl = 'http://%IP%:8000'
echo.
echo Sunucu durdurmak için CTRL+C tuşlarına basın.
echo.
echo ════════════════════════════════════════════════════════════
echo.

python server.py

echo.
echo Sunucu durduruldu.
pause
