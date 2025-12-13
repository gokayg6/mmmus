# OmeChat Backend - Windows Firewall Rule
# Run this script as ADMINISTRATOR

Write-Host "OmeChat Backend - Adding Windows Firewall rule..." -ForegroundColor Yellow

# Remove existing rule if exists
Get-NetFirewallRule -DisplayName "OmeChat Backend Port 8001" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Add new firewall rule
New-NetFirewallRule `
    -DisplayName "OmeChat Backend Port 8001" `
    -Direction Inbound `
    -LocalPort 8001 `
    -Protocol TCP `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Description "OmeChat Backend API - Port 8001"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Firewall rule added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backend is now accessible from all networks:" -ForegroundColor Cyan
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    Write-Host "  - Local: http://localhost:8001" -ForegroundColor White
    Write-Host "  - Network: http://$ip:8001" -ForegroundColor White
} else {
    Write-Host "Error: Firewall rule could not be added. Make sure you run as Administrator." -ForegroundColor Red
}

