# Validate ECRR Compliance across reports
# Outputs JSON + Markdown summaries in artifacts/

param(
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [string]$OutDir = "artifacts",
    [switch]$Verbose,
    # Aliases/new-style params used by orchestrators
    [string]$ReportsDir,
    [string]$OutJson,
    [int]$MinFourSectionPct = 0,
    [int]$MinGatePct = 0
)

$ErrorActionPreference = 'Stop'

# Reconcile parameter aliases
if ($PSBoundParameters.ContainsKey('ReportsDir') -and -not [string]::IsNullOrWhiteSpace($ReportsDir)) {
    $ReportsPath = $ReportsDir
}

if (!(Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

function Test-HasSection {
    param(
        [string]$content,
        [string]$pattern
    )
    return [regex]::IsMatch($content, $pattern, 'IgnoreCase, Multiline')
}

$files = Get-ChildItem -Path $ReportsPath -Recurse -Filter *.md | Where-Object {
    $_.FullName -notmatch "(/|\\)(archive|backup)(/|\\)" -and
    $_.Name -notmatch "^\.gitkeep$" -and
    $_.Name -ne "README.md" -and
    $_.Name -ne "EVIDENCE_TEMPLATE.md" -and
    $_.Name -ne "OTEL_SYNTH_TEMPLATE.md" -and
    $_.Name -notlike "*TEMPLATE*.md"
}

$total = 0
$ok = 0
$issues = @()

$metrics = [ordered]@{
    totalReports = 0
    hasFourSection = 0
    hasEcrrGate = 0
    hasActor = 0
    hasProductionMarker = 0
}

foreach ($f in $files) {
    $total++
    $content = Get-Content -Raw -Encoding UTF8 -Path $f.FullName

    $hasExamine = Test-HasSection $content "^\s*##+\s+.*\bExamine\b"
    $hasClean   = Test-HasSection $content "^\s*##+\s+.*\bClean\b"
    $hasReport  = Test-HasSection $content "^\s*##+\s+.*\bReport\b"
    $hasRole    = Test-HasSection $content "^\s*##+\s+.*\bRole\b"

    $four = $hasExamine -and $hasClean -and $hasReport -and $hasRole

    $gate = Test-HasSection $content "^\s*##+\s+.*ECRR\s+Gate"
    $actor = Test-HasSection $content "Actor Declaration|^\*\*Agent\*\*|\*\*Cursor Agent|\*\*Cursor-Local|\*\*Codex Agent|\*\*ChatGPT Agent"
    $prod = Test-HasSection $content "Production Readiness|PRODUCTION READY|Production Ready|Production Readiness Assessment"

    if ($four) { $metrics.hasFourSection++ }
    if ($gate) { $metrics.hasEcrrGate++ }
    if ($actor) { $metrics.hasActor++ }
    if ($prod) { $metrics.hasProductionMarker++ }

    $fileIssues = @()
    if (-not $four) { $fileIssues += "missing_four_section" }
    if (-not $gate) { $fileIssues += "missing_ecrr_gate" }
    if (-not $actor) { $fileIssues += "missing_actor_declaration" }
    if (-not $prod) { $fileIssues += "missing_production_marker" }

    if ($fileIssues.Count -eq 0) {
        $ok++
    } else {
        $issues += [ordered]@{
            file = $f.FullName.Replace("\\","/")
            issues = $fileIssues
        }
    }
}

$metrics.totalReports = $total

$result = [ordered]@{
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    metrics = $metrics
    complianceRates = [ordered]@{
        fourSection    = if ($total -gt 0) { [math]::Round(($metrics.hasFourSection/$total)*100,1) } else { 0 }
        ecrrGate       = if ($total -gt 0) { [math]::Round(($metrics.hasEcrrGate/$total)*100,1) } else { 0 }
        actor          = if ($total -gt 0) { [math]::Round(($metrics.hasActor/$total)*100,1) } else { 0 }
        production     = if ($total -gt 0) { [math]::Round(($metrics.hasProductionMarker/$total)*100,1) } else { 0 }
        fullyCompliant = if ($total -gt 0) { [math]::Round(($ok/$total)*100,1) } else { 0 }
    }
    fullyCompliantCount = $ok
    nonCompliant = $issues
}

# Orchestrator-compatible JSON schema
$schema = [ordered]@{
    total = $total
    fourSection = [ordered]@{
        count = $metrics.hasFourSection
        pct   = if ($total -gt 0) { [math]::Round(($metrics.hasFourSection/$total)*100,1) } else { 0 }
    }
    ecrrGate = [ordered]@{
        count = $metrics.hasEcrrGate
        pct   = if ($total -gt 0) { [math]::Round(($metrics.hasEcrrGate/$total)*100,1) } else { 0 }
    }
    # Map available metrics to expected fields
    actor = $metrics.hasActor
    evidence = $metrics.hasProductionMarker
    status = $metrics.hasProductionMarker
    thresholds = [ordered]@{
        minFourSectionPct = $MinFourSectionPct
        minGatePct = $MinGatePct
    }
}

$schema.passed = (($schema.fourSection.pct -ge $schema.thresholds.minFourSectionPct) -and ($schema.ecrrGate.pct -ge $schema.thresholds.minGatePct))

$jsonPath = Join-Path $OutDir 'ecrr-compliance-report.json'
($result | ConvertTo-Json -Depth 6) | Out-File -Encoding UTF8 $jsonPath

$mdPath = Join-Path $OutDir 'ecrr-compliance-report.md'
@(
    "# ECRR Compliance Report",
    "",
    "Generated: $($result.generatedAt)",
    "",
    "## Metrics",
    "- Total Reports: $($metrics.totalReports)",
    "- Four-Section Compliance: $($result.complianceRates.fourSection)%",
    "- ECRR Gate Compliance: $($result.complianceRates.ecrrGate)%",
    "- Actor Declaration Compliance: $($result.complianceRates.actor)%",
    "- Production Marker Presence: $($result.complianceRates.production)%",
    "- Fully Compliant: $($result.complianceRates.fullyCompliant)% ($ok/$total)",
    "",
    "## Top Non-compliance Samples (up to 20)",
    ($issues | Select-Object -First 20 | ForEach-Object { "- ``$($_.file)``: $([string]::Join(', ', $_.issues))" })
) | Out-File -Encoding UTF8 $mdPath

Write-Host "✅ Compliance report written to $jsonPath and $mdPath" -ForegroundColor Green

# If an explicit OutJson path is provided, emit the orchestrator schema there
if ($PSBoundParameters.ContainsKey('OutJson') -and -not [string]::IsNullOrWhiteSpace($OutJson)) {
    $outDirForJson = Split-Path -Parent $OutJson
    if (-not [string]::IsNullOrWhiteSpace($outDirForJson) -and -not (Test-Path $outDirForJson)) {
        New-Item -ItemType Directory -Path $outDirForJson -Force | Out-Null
    }
    ($schema | ConvertTo-Json -Depth 6) | Out-File -Encoding UTF8 $OutJson
    Write-Host "✅ Orchestrator JSON written to $OutJson" -ForegroundColor Green
}

return $result

