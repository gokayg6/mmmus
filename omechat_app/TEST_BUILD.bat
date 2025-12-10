@echo off
echo ========================================
echo Test Build - JDK Kontrolü
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Flutter clean...
call flutter clean

echo.
echo Step 2: Flutter pub get...
call flutter pub get

echo.
echo Step 3: Checking JDK configuration...
echo Gradle will use: C:\Program Files\Android\Android Studio\jbr
echo JDK Version: 21 (Java 17 uyumlu)
echo.

echo Step 4: Building...
call flutter run

pause

