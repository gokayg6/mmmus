@echo off
echo ========================================
echo Cleaning Flutter and Gradle caches...
echo ========================================

cd /d "%~dp0"

echo.
echo Step 1: Cleaning Flutter...
call flutter clean

echo.
echo Step 2: Cleaning Gradle cache...
if exist "%USERPROFILE%\.gradle\caches\transforms-3" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\transforms-3"
    echo Gradle transforms cache cleared!
) else (
    echo Gradle transforms cache not found.
)

if exist "%USERPROFILE%\.gradle\caches\modules-2" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1"
    echo Gradle modules cache cleared!
)

echo.
echo Step 3: Getting Flutter packages...
call flutter pub get

echo.
echo Step 4: Building project...
echo.
echo IMPORTANT: Make sure Android Studio is using JDK 17!
echo File > Project Structure > SDK Location > JDK Location
echo Should point to: C:\Program Files\Android\Android Studio\jbr
echo.

call flutter run

pause

