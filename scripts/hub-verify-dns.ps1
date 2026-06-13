#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    BossCat Hub — DNS Verification
.DESCRIPTION
    Checks DNS configuration for hub.resonai.uk
#>

param(
    [string]$Domain = "hub.resonai.uk",
    [string]$ExpectedTarget = "moneycat-inc.github.io"
)

Write-Host "`n🌐 Checking DNS for $Domain`n" -ForegroundColor Cyan

# Check CNAME
Write-Host "🔍 Looking up CNAME record..." -ForegroundColor Gray
try {
    $cname = Resolve-DnsName -Name $Domain -Type CNAME -ErrorAction Stop | Where-Object { $_.Type -eq "CNAME" }
    
    if ($cname) {
        Write-Host "  ✅ CNAME found: $($cname.NameHost)" -ForegroundColor Green
        
        if ($cname.NameHost -like "*$ExpectedTarget*") {
            Write-Host "  ✅ Points to correct target: $ExpectedTarget" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Points to: $($cname.NameHost)" -ForegroundColor Yellow
            Write-Host "     Expected: $ExpectedTarget" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ❌ No CNAME record found" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ DNS lookup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n💡 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Add CNAME record at your DNS provider" -ForegroundColor Gray
    Write-Host "   2. Name: hub" -ForegroundColor Gray
    Write-Host "   3. Target: $ExpectedTarget" -ForegroundColor Gray
    Write-Host "   4. Wait 5-30 minutes for propagation`n" -ForegroundColor Gray
}

# Check A records
Write-Host "`n🔍 Looking up A records..." -ForegroundColor Gray
try {
    $aRecords = Resolve-DnsName -Name $Domain -Type A -ErrorAction Stop | Where-Object { $_.Type -eq "A" }
    
    if ($aRecords) {
        foreach ($record in $aRecords) {
            Write-Host "  📍 $($record.IPAddress)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ℹ️  No A records (expected if using CNAME)" -ForegroundColor DarkGray
}

Write-Host ""

