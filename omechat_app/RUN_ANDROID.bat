@echo off
echo ============================================
echo     OmeChat - Android Cihazda Calistir
echo ============================================
echo.

cd /d "%~dp0"

REM Android SDK yolunu ayarla
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
set PATH=%ANDROID_HOME%\emulator;%ANDROID_HOME%\platform-tools;%PATH%

echo [1] Bagli cihazlari kontrol ediliyor...
flutter devices

echo.
echo [2] Android emulator başlatılıyor (varsa)...
REM Mevcut emülatörleri listele
for /f "delims=" %%i in ('emulator -list-avds 2^>nul') do (
    echo Emulator bulundu: %%i
    echo Emulator baslatiliyor...
    start "" emulator -avd %%i
    timeout /t 30 /nobreak > nul
    goto :run_app
)

echo.
echo [!] Emulator bulunamadi. Lutfen:
echo     1. Android Studio'yu acin
echo     2. Device Manager'dan bir emulator baslatin
echo     3. veya USB ile fiziksel cihaz baglayin
echo.
pause
exit /b 1

:run_app
echo.
echo [3] Uygulama derleniyor ve yukleniyor...
flutter run -d android

pause
