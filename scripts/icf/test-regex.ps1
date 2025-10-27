# Debug script to test BOSSCAT_LOG regex extraction

$logPath = "docs\BossCat\BOSSCAT_LOG.md"
$lines = Get-Content $logPath | Where-Object { $_ -match "GATE #" }

Write-Host "=== Testing Regex Extraction ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Sample lines:" -ForegroundColor Yellow
$lines | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

Write-Host ""
Write-Host "Testing regex patterns:" -ForegroundColor Yellow

$pattern1 = "\[GATE #([\dA-Z\+]+)\s+([^\]]+)\]\*\*\s*(.+?)\s*—"
$pattern2 = "\*\*\[GATE #([\dA-Z\+]+)\s+([^\]]+)\]\*\*\s*(.+?)\s+—"
$pattern3 = "\[GATE #(\d+[\w\+]*)[^\]]*\]"

foreach ($line in ($lines | Select-Object -First 3)) {
    Write-Host ""
    Write-Host "Line: $($line.Substring(0, [Math]::Min(80, $line.Length)))..." -ForegroundColor Cyan
    
    if ($line -match $pattern1) {
        Write-Host "  Pattern 1 MATCH: Gate=$($matches[1]), Status=$($matches[2])" -ForegroundColor Green
    } else {
        Write-Host "  Pattern 1 NO MATCH" -ForegroundColor Red
    }
    
    if ($line -match $pattern2) {
        Write-Host "  Pattern 2 MATCH: Gate=$($matches[1]), Status=$($matches[2])" -ForegroundColor Green
    } else {
        Write-Host "  Pattern 2 NO MATCH" -ForegroundColor Red
    }
    
    if ($line -match $pattern3) {
        Write-Host "  Pattern 3 MATCH: Gate=$($matches[1])" -ForegroundColor Green
    } else {
        Write-Host "  Pattern 3 NO MATCH" -ForegroundColor Red
    }
}

