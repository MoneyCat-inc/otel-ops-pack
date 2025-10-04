# Security Remediation Script for ngrok Authtoken
# BossCat ECRR Compliance - Security Cleanup

param(
    [switch]$RotateToken,
    [switch]$StopTunnel,
    [switch]$CleanLogs
)

Write-Host "🔒 BossCat Security Remediation - ngrok Authtoken" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow

if ($StopTunnel) {
    Write-Host "🛑 Stopping ngrok tunnel..." -ForegroundColor Red
    Get-Process -Name "ngrok" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "✅ Tunnel stopped" -ForegroundColor Green
}

if ($CleanLogs) {
    Write-Host "🧹 Cleaning sensitive data from logs..." -ForegroundColor Yellow
    # Remove any files that might contain the exposed token
    $filesToCheck = @("ngrok_output.txt", "ngrok_setup_log.txt")
    foreach ($file in $filesToCheck) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $cleaned = $content -replace "33cbfflo3EJhMPGIxOTZoMtjIGq_2jZ6jBjzfnSzmULXDpV8U", "[REDACTED]"
            Set-Content $file $cleaned
            Write-Host "✅ Sanitized $file" -ForegroundColor Green
        }
    }
}

if ($RotateToken) {
    Write-Host "🔄 Token rotation instructions:" -ForegroundColor Yellow
    Write-Host "1. Go to https://dashboard.ngrok.com/get-started/your-authtoken" -ForegroundColor Cyan
    Write-Host "2. Generate a new authtoken" -ForegroundColor Cyan
    Write-Host "3. Run: ngrok config add-authtoken <NEW_TOKEN>" -ForegroundColor Cyan
    Write-Host "4. Update GitHub secret: gh secret set NGROK_AUTHTOKEN --body <NEW_TOKEN>" -ForegroundColor Cyan
    Write-Host "5. Remove old token from ngrok.yml if needed" -ForegroundColor Cyan
}

Write-Host "`n📋 Current Status:" -ForegroundColor Blue
$tunnel = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
if ($tunnel) {
    Write-Host "🚇 Tunnel Active: PID $($tunnel.Id)" -ForegroundColor Green
} else {
    Write-Host "🚇 Tunnel: Stopped" -ForegroundColor Red
}

$secret = gh secret list 2>$null | Select-String "NGROK_AUTHTOKEN"
if ($secret) {
    Write-Host "🔐 GitHub Secret: Configured" -ForegroundColor Green
} else {
    Write-Host "🔐 GitHub Secret: Not found" -ForegroundColor Red
}

Write-Host "`n✅ Security remediation complete" -ForegroundColor Green
