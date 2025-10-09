# BossCat OEM - Security Remediation Script
# Removes hardcoded secrets and implements secure environment variable management

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$CreateEnvTemplate
)

Write-Host "🔒 BossCat OEM - Security Remediation Protocol" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Define critical files with hardcoded secrets
$CriticalFiles = @(
    @{
        File = "lib/observability/signoz.ts"
        Pattern = "YMJnm6c+/poKMuEGsjOQZCKrOealu8NjX22QE66VdnQ="
        Replacement = "process.env['SIGNOZ_API_KEY'] || process.env['OTEL_EXPORTER_OTLP_HEADERS']?.split('=')[1] || ''"
        Description = "SigNoz API Key"
    },
    @{
        File = "docs/INTEGRATION_POINTS.md"
        Pattern = "YMJnm6c+/poKMuEGsjOQZCKrOealu8NjX22QE66VdnQ="
        Replacement = "`${SIGNOZ_API_KEY}"
        Description = "SigNoz API Key in documentation"
    },
    @{
        File = "docs/INTEGRATION_POINTS.md"
        Pattern = "eE5syxJUco90j8vq34YPlbHaUg3NpS0UUEYYCzgE7mc="
        Replacement = "`${SIGNOZ_API_TOKEN}"
        Description = "SigNoz API Token in documentation"
    }
)

# Define files to remove or sanitize
$FilesToSanitize = @(
    "docs/INTEGRATION_POINTS.md",
    "docs/environment-configuration.md",
    "docs/backend-implementation-guide.md"
)

# Function to backup file
function Backup-File {
    param($FilePath)
    
    if (Test-Path $FilePath) {
        $BackupPath = "$FilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $FilePath $BackupPath
        Write-Host "📁 Backed up: $FilePath -> $BackupPath" -ForegroundColor Cyan
        return $BackupPath
    }
    return $null
}

# Function to replace secrets in file
function Replace-SecretsInFile {
    param($FilePath, $Replacements)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "⚠️  File not found: $FilePath" -ForegroundColor Yellow
        return $false
    }
    
    $Content = Get-Content $FilePath -Raw
    $Modified = $false
    
    foreach ($Replacement in $Replacements) {
        if ($Content -match $Replacement.Pattern) {
            Write-Host "🔧 Replacing $($Replacement.Description) in $FilePath" -ForegroundColor Green
            
            if (-not $DryRun) {
                $Content = $Content -replace [regex]::Escape($Replacement.Pattern), $Replacement.Replacement
                $Modified = $true
            } else {
                Write-Host "   Would replace: $($Replacement.Pattern)" -ForegroundColor Yellow
                Write-Host "   With: $($Replacement.Replacement)" -ForegroundColor Yellow
            }
        }
    }
    
    if ($Modified -and -not $DryRun) {
        Set-Content $FilePath $Content -Encoding UTF8
        Write-Host "✅ Updated: $FilePath" -ForegroundColor Green
        return $true
    }
    
    return $false
}

# Function to create secure environment template
function Create-SecureEnvTemplate {
    $EnvTemplate = @"
# BossCat OEM - Environment Configuration Template
# Copy this file to .env.local and fill in your actual values
# NEVER commit .env.local to version control

# SigNoz Configuration
SIGNOZ_API_KEY=your-signoz-api-key-here
SIGNOZ_API_URL=http://localhost:8080/api/v1
SIGNOZ_JWT_SECRET=your-jwt-secret-here

# OpenTelemetry Configuration
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:14317
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer your-signoz-api-key-here
OTEL_SERVICE_NAME=resonai-backend
OTEL_SERVICE_VERSION=1.0.0
OTEL_ENVIRONMENT=development

# Authentication & Security
NEXTAUTH_SECRET=your-nextauth-secret-key-here
NEXTAUTH_URL=http://localhost:3000

# Magic Link Configuration
MAGIC_LINK_SECRET=your-magic-link-secret-here

# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Webhook Configuration
SIGNOZ_WEBHOOK_SECRET=your-secure-webhook-secret-here

# Development Settings
NODE_ENV=development
DEBUG=signoz:*

# Vercel Configuration (if deploying to Vercel)
VERCEL_REGION=iad1
VERCEL_URL=http://localhost:3000

# Cron Jobs Secret (for Vercel Cron)
CRON_SECRET=your-cron-secret-here
"@

    $EnvPath = ".env.example"
    
    if (-not $DryRun) {
        Set-Content $EnvPath $EnvTemplate -Encoding UTF8
        Write-Host "✅ Created: $EnvPath" -ForegroundColor Green
    } else {
        Write-Host "🔍 Would create: $EnvPath" -ForegroundColor Yellow
    }
}

# Function to update .gitignore
function Update-GitIgnore {
    $GitIgnorePath = ".gitignore"
    $GitIgnoreEntries = @(
        "",
        "# BossCat OEM - Security",
        ".env.local",
        ".env.production",
        ".env.staging",
        ".env.development",
        "*.key",
        "*.pem",
        "*.p12",
        "secrets/",
        "keys/"
    )
    
    if (Test-Path $GitIgnorePath) {
        $GitIgnoreContent = Get-Content $GitIgnorePath -Raw
        
        foreach ($Entry in $GitIgnoreEntries) {
            if ($Entry -and $GitIgnoreContent -notmatch [regex]::Escape($Entry)) {
                if (-not $DryRun) {
                    Add-Content $GitIgnorePath $Entry
                    Write-Host "✅ Added to .gitignore: $Entry" -ForegroundColor Green
                } else {
                    Write-Host "🔍 Would add to .gitignore: $Entry" -ForegroundColor Yellow
                }
            }
        }
    } else {
        if (-not $DryRun) {
            Set-Content $GitIgnorePath ($GitIgnoreEntries -join "`n")
            Write-Host "✅ Created: $GitIgnorePath" -ForegroundColor Green
        } else {
            Write-Host "🔍 Would create: $GitIgnorePath" -ForegroundColor Yellow
        }
    }
}

# Main remediation process
Write-Host "`n🔍 Scanning for hardcoded secrets..." -ForegroundColor Cyan

$RemediatedFiles = 0
$TotalFiles = $CriticalFiles.Count

# Process critical files
foreach ($FileInfo in $CriticalFiles) {
    Write-Host "`n📄 Processing: $($FileInfo.File)" -ForegroundColor White
    
    $BackupPath = Backup-File $FileInfo.File
    
    if (Replace-SecretsInFile $FileInfo.File @($FileInfo)) {
        $RemediatedFiles++
    }
}

# Create environment template
if ($CreateEnvTemplate) {
    Write-Host "`n🔧 Creating secure environment template..." -ForegroundColor Cyan
    Create-SecureEnvTemplate
}

# Update .gitignore
Write-Host "`n🔧 Updating .gitignore..." -ForegroundColor Cyan
Update-GitIgnore

# Summary
Write-Host "`n📊 REMEDIATION SUMMARY" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Files processed: $TotalFiles" -ForegroundColor White
Write-Host "Files remediated: $RemediatedFiles" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN COMPLETE" -ForegroundColor Yellow
    Write-Host "To apply changes, run without -DryRun flag" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ SECURITY REMEDIATION COMPLETE" -ForegroundColor Green
    
    Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Create .env.local file from .env.example" -ForegroundColor White
    Write-Host "2. Fill in your actual secret values" -ForegroundColor White
    Write-Host "3. Test your application with environment variables" -ForegroundColor White
    Write-Host "4. Commit the remediated code" -ForegroundColor White
    Write-Host "5. Set up pre-commit hooks for ongoing security" -ForegroundColor White
    
    Write-Host "`n🔒 SECURITY NOTES:" -ForegroundColor Red
    Write-Host "- Never commit .env.local to version control" -ForegroundColor White
    Write-Host "- Rotate secrets regularly (every 90 days)" -ForegroundColor White
    Write-Host "- Use different secrets for different environments" -ForegroundColor White
    Write-Host "- Monitor for secret leaks with GitGuardian" -ForegroundColor White
}

Write-Host "`n🐾 BossCat OEM - Security Remediation Protocol Complete" -ForegroundColor Green
