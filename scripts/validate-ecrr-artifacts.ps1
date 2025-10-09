# ECRR Artifacts Validation Script
# Validates JSON evidence files and checks artifact references

$ErrorActionPreference = "Continue"

Write-Host "`n🔍 ECRR Artifacts Validation" -ForegroundColor Cyan
Write-Host "=" * 60

# Validate JSON files
$jsonFiles = Get-ChildItem -Path "docs\ecrr\ECRR_REPORTS" -Recurse -Include "*.json" -File
Write-Host "`n📋 JSON Evidence Validation:" -ForegroundColor Yellow
Write-Host "   Total JSON files: $($jsonFiles.Count)"

$validJson = 0
$invalidJson = 0
$invalidFiles = @()

foreach ($file in $jsonFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $null = $content | ConvertFrom-Json -ErrorAction Stop
        $validJson++
    }
    catch {
        $invalidJson++
        $invalidFiles += $file.Name
        Write-Host "   ❌ Invalid: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "   ✅ Valid JSON: $validJson" -ForegroundColor Green
Write-Host "   ❌ Invalid JSON: $invalidJson" -ForegroundColor $(if ($invalidJson -gt 0) { "Red" } else { "Green" })

if ($invalidJson -gt 0) {
    Write-Host "`n   Invalid files:" -ForegroundColor Red
    $invalidFiles | ForEach-Object { Write-Host "      - $_" }
}

$validationRate = [math]::Round(($validJson / $jsonFiles.Count) * 100, 1)
Write-Host "   📊 Validation Rate: $validationRate%" -ForegroundColor $(if ($validationRate -eq 100) { "Green" } else { "Yellow" })

# Check artifact references
Write-Host "`n📦 Artifact References:" -ForegroundColor Yellow

$mdFiles = Get-ChildItem -Path "docs\ecrr\ECRR_REPORTS" -Recurse -Include "*.md" -File
$reportsWithArtifacts = 0
$totalArtifactReferences = 0

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # Look for artifact references
        $artifactMatches = [regex]::Matches($content, '(?i)(artifact|evidence|report|dashboard).*\.(json|pdf|html|png)')
        if ($artifactMatches.Count -gt 0) {
            $reportsWithArtifacts++
            $totalArtifactReferences += $artifactMatches.Count
        }
    }
}

Write-Host "   Reports with artifact references: $reportsWithArtifacts/$($mdFiles.Count)"
Write-Host "   Total artifact references: $totalArtifactReferences"

$artifactRate = [math]::Round(($reportsWithArtifacts / $mdFiles.Count) * 100, 1)
Write-Host "   📊 Artifact Reference Rate: $artifactRate%"

# Check for orphaned artifacts
Write-Host "`n🔗 Artifact Linking:" -ForegroundColor Yellow

$referencedJsonFiles = @()
foreach ($mdFile in $mdFiles) {
    $content = Get-Content $mdFile.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($jsonFile in $jsonFiles) {
        if ($content -match [regex]::Escape($jsonFile.Name)) {
            $referencedJsonFiles += $jsonFile.Name
        }
    }
}

$referencedJsonFiles = $referencedJsonFiles | Select-Object -Unique
$orphanedJson = $jsonFiles | Where-Object { $referencedJsonFiles -notcontains $_.Name }

Write-Host "   Referenced JSON files: $($referencedJsonFiles.Count)/$($jsonFiles.Count)"
Write-Host "   Orphaned JSON files: $($orphanedJson.Count)"

if ($orphanedJson.Count -gt 0 -and $orphanedJson.Count -le 5) {
    Write-Host "`n   Orphaned files:" -ForegroundColor Yellow
    $orphanedJson | Select-Object -First 5 | ForEach-Object { Write-Host "      - $($_.Name)" }
}

# File size statistics
Write-Host "`n📏 File Size Statistics:" -ForegroundColor Yellow

$totalJsonSize = ($jsonFiles | Measure-Object -Property Length -Sum).Sum / 1KB
$avgJsonSize = ($jsonFiles | Measure-Object -Property Length -Average).Average / 1KB

Write-Host "   Total JSON size: $([math]::Round($totalJsonSize, 2)) KB"
Write-Host "   Average JSON size: $([math]::Round($avgJsonSize, 2)) KB"

$totalMdSize = ($mdFiles | Measure-Object -Property Length -Sum).Sum / 1KB
$avgMdSize = ($mdFiles | Measure-Object -Property Length -Average).Average / 1KB

Write-Host "   Total MD size: $([math]::Round($totalMdSize, 2)) KB"
Write-Host "   Average MD size: $([math]::Round($avgMdSize, 2)) KB"

# Summary
Write-Host "`n" + ("=" * 60)
Write-Host "📊 Validation Summary" -ForegroundColor Cyan
Write-Host "=" * 60

$overallStatus = if ($validationRate -eq 100 -and $invalidJson -eq 0) { "✅ PASS" } else { "⚠️ ATTENTION REQUIRED" }

Write-Host "   JSON Validation: $validJson/$($jsonFiles.Count) valid ($validationRate%)" -ForegroundColor $(if ($validationRate -eq 100) { "Green" } else { "Yellow" })
Write-Host "   Artifact References: $reportsWithArtifacts/$($mdFiles.Count) reports ($artifactRate%)"
Write-Host "   Orphaned Artifacts: $($orphanedJson.Count) files"
Write-Host "   Overall Status: $overallStatus" -ForegroundColor $(if ($validationRate -eq 100) { "Green" } else { "Yellow" })
Write-Host "`n"

# Export validation report
$validationReport = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    json_validation = @{
        total_files = $jsonFiles.Count
        valid = $validJson
        invalid = $invalidJson
        validation_rate = $validationRate
        invalid_files = $invalidFiles
    }
    artifact_references = @{
        reports_with_artifacts = $reportsWithArtifacts
        total_references = $totalArtifactReferences
        reference_rate = $artifactRate
    }
    artifact_linking = @{
        referenced_json = $referencedJsonFiles.Count
        orphaned_json = $orphanedJson.Count
        orphaned_files = $orphanedJson | ForEach-Object { $_.Name }
    }
    file_statistics = @{
        total_json_size_kb = [math]::Round($totalJsonSize, 2)
        avg_json_size_kb = [math]::Round($avgJsonSize, 2)
        total_md_size_kb = [math]::Round($totalMdSize, 2)
        avg_md_size_kb = [math]::Round($avgMdSize, 2)
    }
    status = if ($validationRate -eq 100) { "PASS" } else { "ATTENTION_REQUIRED" }
}

$reportPath = "artifacts\ecrr-artifact-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$validationReport | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding utf8
Write-Host "📁 Validation report exported to: $reportPath" -ForegroundColor Cyan

