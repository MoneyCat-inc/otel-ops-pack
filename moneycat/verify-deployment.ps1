# MoneyCat Website Deployment Verification Script
# Verifies accessibility for /moneycat subdirectory deployments, with optional custom domain DNS check

param(
    [string]$BaseUrl = "https://hub.resonai.uk/moneycat",
    [string]$CustomDomain,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$baseUrl = $BaseUrl.TrimEnd("/")
$issues = @()

Write-Host "✅ MoneyCat Website Deployment Verification" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# 1) Custom domain DNS (optional)
Write-Host "[1/5] Custom domain DNS..." -ForegroundColor Yellow
if ($CustomDomain) {
    try {
        $dnsResult = Resolve-DnsName -Name $CustomDomain -Type CNAME -ErrorAction Stop
        if ($dnsResult.NameHost) {
            Write-Host "  ✅ CNAME found: $($dnsResult.NameHost)" -ForegroundColor Green
            if ($Verbose) {
                Write-Host "     TTL: $($dnsResult.TTL)" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "  ⚠️  DNS resolution failed: $_" -ForegroundColor Yellow
        $issues += "Custom domain DNS not resolving"
    }
} else {
    Write-Host "  ↪ Skipped (no custom domain provided)" -ForegroundColor Gray
}

# 2) HTTP
Write-Host "`n[2/5] Checking HTTP..." -ForegroundColor Yellow
try {
    $httpResponse = Invoke-WebRequest -Uri $baseUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "  ✅ HTTP accessible (Status: $($httpResponse.StatusCode))" -ForegroundColor Green
    if ($Verbose) {
        Write-Host "     Server: $($httpResponse.Headers.Server)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ HTTP not accessible: $_" -ForegroundColor Red
    $issues += "HTTP not accessible"
}

# 3) HTTPS/SSL
Write-Host "`n[3/5] Checking HTTPS/SSL..." -ForegroundColor Yellow
try {
    $httpsResponse = Invoke-WebRequest -Uri $baseUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    if ($httpsResponse.BaseResponse.IsSecureConnection) {
        Write-Host "  ✅ HTTPS working (SSL certificate valid)" -ForegroundColor Green
        if ($Verbose) {
            Write-Host "     Secure connection established" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠️  HTTPS not secure" -ForegroundColor Yellow
        $issues += "HTTPS not secure"
    }
} catch {
    Write-Host "  ❌ HTTPS not accessible: $_" -ForegroundColor Red
    $issues += "HTTPS not accessible"
}

# 4) Main pages
Write-Host "`n[4/5] Checking main pages..." -ForegroundColor Yellow
$pages = @(
    @{ Name = "Homepage"; Path = "" },
    @{ Name = "About"; Path = "about.html" },
    @{ Name = "Services"; Path = "services.html" },
    @{ Name = "Contact"; Path = "contact.html" }
)

foreach ($page in $pages) {
    $url = if ($page.Path) { "$baseUrl/$($page.Path)" } else { $baseUrl }
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ $($page.Name): OK" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $($page.Name): Status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ $($page.Name): Failed" -ForegroundColor Red
        $issues += "$($page.Name) not accessible"
    }
}

# 5) Assets
Write-Host "`n[5/5] Checking assets..." -ForegroundColor Yellow
$assets = @("styles.css", "script.js")
foreach ($asset in $assets) {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/$asset" -Method Head -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ $asset: OK" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $asset: Status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ $asset: Failed" -ForegroundColor Red
        $issues += "$asset not accessible"
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "✅ All checks passed! Website is fully operational." -ForegroundColor Green
    Write-Host "`n🔗 Website: $baseUrl" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "⚠️  Issues found:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "   - $issue" -ForegroundColor Yellow
    }
    Write-Host "`nℹ️  Check DEPLOYMENT.md for troubleshooting steps." -ForegroundColor Cyan
    exit 1
}
