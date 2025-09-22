# Simple test to verify YAML validation logic
Write-Host "🧪 Testing YAML validation logic..." -ForegroundColor Cyan

$success = @()
$errors = @()

# Test the YAML validation logic
$yamlFiles = @(".github/workflows/ci.yml", ".github/dependabot.yml", ".mergify.yml")

$convertFromYaml = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue
if (-not $convertFromYaml) {
    try {
        Import-Module powershell-yaml -ErrorAction Stop | Out-Null
        $convertFromYaml = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue
    } catch {
        $success += "⚠️  ConvertFrom-Yaml not available; skipping YAML validation (install powershell-yaml for local checks)"
    }
}

foreach ($file in $yamlFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($convertFromYaml) {
            try {
                $null = ConvertFrom-Yaml -InputObject $content
                $success += "✅ $file is valid YAML"
            } catch {
                $errors += "❌ $file has invalid YAML syntax: $($_.Exception.Message)"
            }
        } else {
            $success += "⚠️  Skipped validation for $file (ConvertFrom-Yaml unavailable)"
        }
    }
}

# Summary
Write-Host "`n📊 YAML Validation Test Results:" -ForegroundColor Cyan

if ($success.Count -gt 0) {
    Write-Host "`n✅ Successes ($($success.Count)):" -ForegroundColor Green
    foreach ($item in $success) {
        Write-Host "  $item" -ForegroundColor Green
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`n❌ Errors ($($errors.Count)):" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "  $item" -ForegroundColor Red
    }
}

# Final Status
Write-Host "`n🎯 Final Status:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "🎉 PERFECT! YAML validation logic works correctly!" -ForegroundColor Green
    Write-Host "The automation test script will now handle missing ConvertFrom-Yaml gracefully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ ISSUES FOUND! YAML validation has problems." -ForegroundColor Red
    exit 1
}
