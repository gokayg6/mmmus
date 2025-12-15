@echo off
REM OmeChat Backend - Windows Firewall Rule (Netsh Method)
REM Run this script as ADMINISTRATOR

echo OmeChat Backend - Adding Windows Firewall rule...

netsh advfirewall firewall delete rule name="OmeChat Backend Port 8000" >nul 2>&1

netsh advfirewall firewall add rule name="OmeChat Backend Port 8000" dir=in action=allow protocol=TCP localport=8000

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Firewall rule added successfully!
    echo.
    echo Backend is now accessible from all networks:
    echo   - Local: http://localhost:8000
    echo   - Network: http://192.168.1.103:8000
) else (
    echo.
    echo Error: Firewall rule could not be added.
    echo Make sure you run this script as Administrator!
)

pause

