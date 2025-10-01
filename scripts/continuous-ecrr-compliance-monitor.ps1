[CmdletBinding()]
param(
    [switch]$Verbose,
    [switch]$GenerateReport,
    [string]$OutputPath = "artifacts/ecrr-compliance-monitor.json",
    [string]$ReportsPath = "docs/ECRR_REPORTS"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-ECRRLog {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')][string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'ERROR'   { 'Red' }
        'WARN'    { 'Yellow' }
        'SUCCESS' { 'Green' }
        default   { 'White' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-FourSectionStructure {
    param([string]$Content)

    $sections = @(
        '(?im)^##\s+.*(1\.\s*)?Examine',
        '(?im)^##\s+.*(2\.\s*)?Clean',
        '(?im)^##\s+.*(3\.\s*)?Report',
        '(?im)^##\s+.*(4\.\s*)?Role'
    )

    $matches = 0
    foreach ($pattern in $sections) {
        if ($Content -match $pattern) { $matches++ }
    }

    return ($matches -eq 4)
}

function Test-ECRRGate {
    param([string]$Content)
    return ($Content -match '(?im)^##\s+.*ECRR Gate')
}

function Test-ProductionMarker {
    param([string]$Content)
    return ($Content -match '(?im)✅\s*\*\*PRODUCTION READY\*\*' -or $Content -match '(?im)PRODUCTION\s+READY')
}

function Test-ActorDeclaration {
    param([string]$Content)
    return ($Content -match '(?im)^\*\*Actor\*\*\s*:' -or $Content -match '(?im)^Actor\s*:')
}

function Test-EvidenceReferences {
    param([string]$Content)

    $patterns = @('(?i)Evidence','(?i)Artifacts','(?i)Verification','(?i)Logs','(?i)Results','(?i)Screenshots')
    $matches = 0
    foreach ($pattern in $patterns) {
        if ($Content -match $pattern) { $matches++ }
    }

    return ($matches -ge 2)
}

function Test-StatusDeclaration {
    param([string]$Content)
    return ($Content -match '(?im)^\*\*Status\*\*\s*:')
}

function Get-Actor {
    param([string]$Content)

    $match = [regex]::Match($Content, '(?im)^\*\*(Actor|Agent)\*\*\s*:\s*(?<actor>.+?)\s*$')
    if ($match.Success) { return $match.Groups['actor'].Value.Trim() }

    $fallback = [regex]::Match($Content, '(?im)^Actor\s*:\s*(?<actor>.+?)\s*$')
    if ($fallback.Success) { return $fallback.Groups['actor'].Value.Trim() }

    return 'Unknown'
}

function Get-ReportCategory {
    param([string]$FileName)

    $name = $FileName.ToLowerInvariant()
    if ($name -match '(verification|validate|validation|audit)') { return 'Verification' }
    if ($name -match '(implementation|rollout|deploy|launch|integration|setup)') { return 'Implementation' }
    if ($name -match '(complete|completion|final|summary)') { return 'Completion' }
    return 'Other'
}

function Get-ReportDate {
    param([string]$FileName, [string]$Content)

    $nameMatch = [regex]::Match($FileName, '(?<date>\d{4}-\d{2}-\d{2})')
    if ($nameMatch.Success) { return $nameMatch.Groups['date'].Value }

    $contentMatch = [regex]::Match($Content, '(?im)^\*\*Date\*\*\s*:\s*(?<date>\d{4}-\d{2}-\d{2})')
    if ($contentMatch.Success) { return $contentMatch.Groups['date'].Value }

    return $null
}

try {
    Write-ECRRLog 'Starting ECRR Compliance Monitor...' 'INFO'
    Write-ECRRLog ("Configuration: {0}" -f (@{
        ReportsPath = $ReportsPath
        OutputPath  = $OutputPath
        GenerateReport = $GenerateReport.IsPresent
    } | ConvertTo-Json -Compress)) 'INFO'

    if (-not (Test-Path -Path $ReportsPath)) {
        throw "Reports path '$ReportsPath' not found."
    }

    $reportsRoot = (Resolve-Path -Path $ReportsPath).ProviderPath
    Write-ECRRLog "Starting ECRR compliance analysis..." 'INFO'

    $excludeDirectories = @('archive','backup','backups')
    $reportFiles = @(Get-ChildItem -Path $reportsRoot -Filter '*.md' -Recurse | Where-Object {
        if ($_.Name -eq '.gitkeep') { return $false }
        foreach ($skip in $excludeDirectories) {
            if ($_.FullName -match "(?i)[\\/]$skip[\\/]") { return $false }
        }
        return ($_.Name -match '\d{4}-\d{2}-\d{2}')
    })

    $totalReports = $reportFiles.Count
    Write-ECRRLog "Found $totalReports ECRR reports to analyze" 'INFO'

    if ($totalReports -eq 0) {
        Write-ECRRLog 'No reports available to evaluate.' 'WARN'
        return 0
    }

    $compliantCount = 0
    $nonCompliant = @()
    $metrics = [ordered]@{
        FourSectionStructure = @{ Checked = 0; Compliant = 0 }
        ECRRGate             = @{ Checked = 0; Compliant = 0 }
        ProductionMarker     = @{ Checked = 0; Compliant = 0 }
        ActorDeclaration     = @{ Checked = 0; Compliant = 0 }
        EvidenceReferences   = @{ Checked = 0; Compliant = 0 }
        StatusDeclaration    = @{ Checked = 0; Compliant = 0 }
    }

    foreach ($file in $reportFiles) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        if (-not $content) { continue }

        $issues = @()

        $hasSections = Test-FourSectionStructure -Content $content
        $metrics.FourSectionStructure.Checked++
        if ($hasSections) { $metrics.FourSectionStructure.Compliant++ } else { $issues += 'Missing four-section structure' }

        $hasGate = Test-ECRRGate -Content $content
        $metrics.ECRRGate.Checked++
        if ($hasGate) { $metrics.ECRRGate.Compliant++ } else { $issues += 'Missing ECRR Gate' }

        $hasProd = Test-ProductionMarker -Content $content
        $metrics.ProductionMarker.Checked++
        if ($hasProd) { $metrics.ProductionMarker.Compliant++ } else { $issues += 'Missing production marker' }

        $hasActor = Test-ActorDeclaration -Content $content
        $metrics.ActorDeclaration.Checked++
        if ($hasActor) { $metrics.ActorDeclaration.Compliant++ } else { $issues += 'Missing actor declaration' }

        $hasEvidence = Test-EvidenceReferences -Content $content
        $metrics.EvidenceReferences.Checked++
        if ($hasEvidence) { $metrics.EvidenceReferences.Compliant++ } else { $issues += 'Missing evidence references' }

        $hasStatus = Test-StatusDeclaration -Content $content
        $metrics.StatusDeclaration.Checked++
        if ($hasStatus) { $metrics.StatusDeclaration.Compliant++ } else { $issues += 'Missing status declaration' }

        if ($issues.Count -eq 0) {
            $compliantCount++
            continue
        }

        $nonCompliant += [ordered]@{
            File = $file.Name
            Path = $file.FullName
            Date = Get-ReportDate -FileName $file.Name -Content $content
            Agent = Get-Actor -Content $content
            Category = Get-ReportCategory -FileName $file.Name
            Issues = $issues
        }
    }

    $complianceRate = if ($totalReports -eq 0) { 0 } else { [math]::Round(($compliantCount / $totalReports) * 100, 2) }

    Write-ECRRLog "Compliance analysis complete. Rate: $complianceRate%" 'SUCCESS'

    if ($GenerateReport) {
        $report = [ordered]@{
            GeneratedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
            ReportsPath = $reportsRoot
            TotalReports = $totalReports
            CompliantReports = $compliantCount
            ComplianceRate = $complianceRate
            NonCompliantReports = $nonCompliant
            Metrics = $metrics
        }

        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not [string]::IsNullOrWhiteSpace($outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        $report | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-ECRRLog "Compliance report saved to: $OutputPath" 'SUCCESS'
    }

    Write-Output $complianceRate
    Write-ECRRLog 'ECRR Compliance Monitor completed successfully' 'SUCCESS'

} catch {
    Write-ECRRLog "Error in ECRR Compliance Monitor: $($_.Exception.Message)" 'ERROR'
    if (\System.Management.Automation.PSBoundParametersDictionary.ContainsKey('Verbose')) {
        Write-Host $_.Exception.ToString() -ForegroundColor DarkGray
    }
    exit 1
}

