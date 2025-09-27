# MEMX Production Setup Script
# Enables MEMX feature flag and configures production environment

param(
    [switch]$EnableStreaming,
    [string]$OtlpEndpoint = "http://localhost:5318",
    [switch]$DryRun
)

Write-Host "=== MEMX Production Setup ===" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Error "Please run this script from the resonai-mock directory"
    exit 1
}

# Backup existing .env.local
if (Test-Path ".env.local") {
    $backupName = ".env.local.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item ".env.local" $backupName
    Write-Host "Backed up existing .env.local to $backupName" -ForegroundColor Yellow
}

# Create production environment configuration
$envContent = @"
# MEMX Production Configuration
NEXT_PUBLIC_FEATURE_MEMX=1
NEXT_PUBLIC_MEMX_OTLP_ENDPOINT=$OtlpEndpoint
NEXT_PUBLIC_MEMX_STREAM_DEFAULT=$($EnableStreaming ? "1" : "0")

# OTel Integration
NEXT_PUBLIC_OTEL_EXPORTER_OTLP_PROTOCOL=http/json
NEXT_PUBLIC_OTEL_EXPORTER_OTLP_ENDPOINT=$OtlpEndpoint
NEXT_PUBLIC_OTEL_SERVICE_NAME=resonai-production

# Analytics
NEXT_PUBLIC_ANALYTICS_DATASET=resonai_analytics
"@

if ($DryRun) {
    Write-Host "DRY RUN - Would create .env.local with:" -ForegroundColor Cyan
    Write-Host $envContent
} else {
    # Write the configuration
    $envContent | Out-File -FilePath ".env.local" -Encoding UTF8
    Write-Host "Created .env.local with MEMX enabled" -ForegroundColor Green
    
    if ($EnableStreaming) {
        Write-Host "MEMX streaming enabled to: $OtlpEndpoint" -ForegroundColor Green
    } else {
        Write-Host "MEMX streaming disabled (local-only mode)" -ForegroundColor Yellow
    }
}

# Verify configuration
Write-Host "`n=== Configuration Verification ===" -ForegroundColor Green

if (-not $DryRun) {
    # Check if MEMX is enabled
    $memxEnabled = (Get-Content ".env.local" | Select-String "NEXT_PUBLIC_FEATURE_MEMX=1")
    if ($memxEnabled) {
        Write-Host "✅ MEMX feature flag enabled" -ForegroundColor Green
    } else {
        Write-Host "❌ MEMX feature flag not enabled" -ForegroundColor Red
    }
    
    # Check OTLP endpoint
    $otlpEndpoint = (Get-Content ".env.local" | Select-String "NEXT_PUBLIC_MEMX_OTLP_ENDPOINT")
    Write-Host "✅ OTLP endpoint: $otlpEndpoint" -ForegroundColor Green
    
    # Check streaming status
    $streaming = (Get-Content ".env.local" | Select-String "NEXT_PUBLIC_MEMX_STREAM_DEFAULT")
    Write-Host "✅ Streaming status: $streaming" -ForegroundColor Green
}

# Next steps
Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Restart the development server: pnpm dev" -ForegroundColor Cyan
Write-Host "2. Visit http://localhost:3001/labs/memx to verify MEMX is active" -ForegroundColor Cyan
Write-Host "3. Run tests: pnpm test:e2e" -ForegroundColor Cyan

if ($EnableStreaming) {
    Write-Host "4. Monitor SigNoz at http://localhost:8080 for MEMX metrics" -ForegroundColor Cyan
    Write-Host "5. Check OTel collector logs for MEMX events" -ForegroundColor Cyan
} else {
    Write-Host "4. To enable streaming later, run: .\scripts\setup-memx-production.ps1 -EnableStreaming" -ForegroundColor Cyan
}

Write-Host "`n=== MEMX Production Setup Complete ===" -ForegroundColor Green
