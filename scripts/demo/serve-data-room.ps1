# Investor Demo: Serve Data Room via HTTP (CORS workaround)
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Serve Data Room on localhost:3000 to enable metrics fetch

param(
    [int]$Port = 3000
)

Write-Host "=== Starting Data Room HTTP Server ===" -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor White
Write-Host ""

# Check if http-server is available (npx will download if needed)
Write-Host "Starting server (may download http-server on first run)..." -ForegroundColor Yellow

try {
    Set-Location C:\otel\docs\demo
    npx --yes http-server . -p $Port --cors -o /data-room.html
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

