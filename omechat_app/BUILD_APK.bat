@echo off
echo ============================================
echo     OmeChat - APK Olustur
echo ============================================
echo.

cd /d "%~dp0"

echo [1] Proje temizleniyor...
flutter clean

echo.
echo [2] Bagimliliklar yukleniyor...
flutter pub get

echo.
echo [3] Release APK olusturuluyor...
echo Bu islem birkaç dakika surebilir...
echo.
flutter build apk --release

echo.
echo ============================================
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo [✓] APK basariyla olusturuldu!
    echo.
    echo APK Konumu:
    echo %cd%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo APK dosyasini telefonunuza kopyalayip kurabilirsiniz.
    explorer "build\app\outputs\flutter-apk"
) else (
    echo [X] APK olusturulamadi. Hatalari kontrol edin.
)
echo ============================================
echo.
pause
