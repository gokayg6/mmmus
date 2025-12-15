# OmeChat Backend - Windows Firewall Rule (Fixed)
# Run this script as ADMINISTRATOR

Write-Host "OmeChat Backend - Adding Windows Firewall rule..." -ForegroundColor Yellow

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Remove existing rule if exists
$existingRule = Get-NetFirewallRule -DisplayName "OmeChat Backend Port 8000" -ErrorAction SilentlyContinue
if ($existingRule) {
    Write-Host "Removing existing rule..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName "OmeChat Backend Port 8000" -ErrorAction SilentlyContinue
}

# Add new firewall rule
try {
    New-NetFirewallRule `
        -DisplayName "OmeChat Backend Port 8000" `
        -Direction Inbound `
        -LocalPort 8000 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private,Public `
        -Description "OmeChat Backend API - Port 8000" `
        -ErrorAction Stop
    
    Write-Host "Firewall rule added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backend is now accessible from all networks:" -ForegroundColor Cyan
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    Write-Host "  - Local: http://localhost:8000" -ForegroundColor White
    Write-Host "  - Network: http://$ip:8000" -ForegroundColor White
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Use netsh command:" -ForegroundColor Yellow
    Write-Host "  netsh advfirewall firewall add rule name=`"OmeChat Backend Port 8000`" dir=in action=allow protocol=TCP localport=8000" -ForegroundColor White
}

