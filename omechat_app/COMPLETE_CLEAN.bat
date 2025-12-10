@echo off
echo ========================================
echo COMPLETE CLEAN - Tüm cache'leri temizle
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Flutter clean...
call flutter clean

echo.
echo Step 2: Temizleniyor Gradle cache...
if exist "%USERPROFILE%\.gradle\caches" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches"
    echo Gradle cache tamamen temizlendi!
)

echo.
echo Step 3: Temizleniyor Gradle wrapper cache...
if exist "%USERPROFILE%\.gradle\wrapper" (
    rmdir /s /q "%USERPROFILE%\.gradle\wrapper"
    echo Gradle wrapper cache temizlendi!
)

echo.
echo Step 4: Android build klasörü temizleniyor...
if exist "android\.gradle" (
    rmdir /s /q "android\.gradle"
)
if exist "android\build" (
    rmdir /s /q "android\build"
)
if exist "android\app\build" (
    rmdir /s /q "android\app\build"
)

echo.
echo Step 5: Flutter packages alınıyor...
call flutter pub get

echo.
echo Step 6: Gradle wrapper'ı yeniden indiriyor...
cd android
call gradlew.bat wrapper --gradle-version 8.5
cd ..

echo.
echo ========================================
echo TEMİZLİK TAMAMLANDI!
echo ========================================
echo.
echo Şimdi projeyi derleyebilirsiniz:
echo   flutter run
echo.
pause

