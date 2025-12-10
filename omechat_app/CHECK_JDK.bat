@echo off
echo ========================================
echo Checking Java/JDK Installation...
echo ========================================
echo.

echo Checking JAVA_HOME...
if defined JAVA_HOME (
    echo JAVA_HOME is set to: %JAVA_HOME%
    if exist "%JAVA_HOME%\bin\java.exe" (
        "%JAVA_HOME%\bin\java.exe" -version
    ) else (
        echo WARNING: java.exe not found in JAVA_HOME!
    )
) else (
    echo JAVA_HOME is NOT set.
)
echo.

echo Checking Android Studio JBR...
set AS_JBR="C:\Program Files\Android\Android Studio\jbr"
if exist %AS_JBR%\bin\java.exe (
    echo Android Studio JBR found at: %AS_JBR%
    %AS_JBR%\bin\java.exe -version
    echo.
    echo Checking version...
    for /f "tokens=3" %%i in ('%AS_JBR%\bin\java.exe -version 2^>^&1 ^| findstr /i "version"') do (
        echo Java version: %%i
        echo %%i | findstr /i "17" >nul
        if errorlevel 1 (
            echo.
            echo ========================================
            echo ERROR: Android Studio is NOT using JDK 17!
            echo ========================================
            echo.
            echo Please do the following:
            echo 1. Open Android Studio
            echo 2. Go to File ^> Project Structure ^> SDK Location
            echo 3. Set JDK location to: %AS_JBR%
            echo 4. Or install JDK 17 and point to it
        ) else (
            echo.
            echo ========================================
            echo SUCCESS: Android Studio is using JDK 17!
            echo ========================================
        )
    )
) else (
    echo WARNING: Android Studio JBR not found at default location!
    echo Please check if Android Studio is installed.
)
echo.

echo Checking system Java...
where java >nul 2>&1
if errorlevel 1 (
    echo Java not found in PATH.
) else (
    java -version
)
echo.

pause

