@echo off
echo Cleaning Gradle cache...
rmdir /s /q "%USERPROFILE%\.gradle\caches\transforms-3" 2>nul
echo Cleaned!

echo.
echo Please ensure Android Studio is using JDK 17:
echo 1. Open Android Studio
echo 2. Go to File ^> Project Structure ^> SDK Location
echo 3. Set JDK location to a JDK 17 installation
echo.
echo If Android Studio JBR is JDK 17, the build should work now.
echo Try: flutter run

pause

