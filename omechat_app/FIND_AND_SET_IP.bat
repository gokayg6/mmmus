@echo off
chcp 65001 >nul
echo ========================================
echo PC IP ADRESİ BULMA VE AYARLAMA
echo ========================================
echo.

echo PC IP adresiniz bulunuyor...
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "IP=%%a"
    set "IP=!IP:~1!"
    echo Bulunan IP: !IP!
    
    if "!IP:~0,7!"=="192.168" (
        echo.
        echo ✅ IP bulundu: !IP!
        echo.
        echo Bu IP'yi api_client.dart dosyasına yazmak ister misiniz? (E/H)
        set /p CONFIRM="> "
        
        if /i "!CONFIRM!"=="E" (
            echo.
            echo IP adresi ayarlanıyor...
            powershell -Command "(Get-Content 'lib\services\api_client.dart') -replace 'http://192\.168\.\d+\.\d+:8000', 'http://!IP!:8000' | Set-Content 'lib\services\api_client.dart'"
            echo.
            echo ✅ IP adresi başarıyla ayarlandı!
            echo.
        ) else (
            echo.
            echo İptal edildi. Manuel olarak ayarlayabilirsiniz.
            echo lib\services\api_client.dart dosyasını açıp IP'yi değiştirin.
            echo.
        )
        goto :FOUND
    )
)

echo.
echo ⚠️ Uygun IP adresi bulunamadı!
echo Manuel olarak ayarlamak için:
echo   1. ipconfig çalıştırın
echo   2. IPv4 Address'i bulun
echo   3. lib\services\api_client.dart dosyasını açın
echo   4. IP adresini değiştirin
echo.

:FOUND
pause



