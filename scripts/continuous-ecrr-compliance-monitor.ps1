[CmdletBinding()]
param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [string]$ArtifactsDir = "artifacts",
    [switch]$GenerateReport,
    [switch]$IncludeArchived
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

    $patterns = @(
        '(?im)^##\s+.*(1\.\s*)?Examine',
        '(?im)^##\s+.*(2\.\s*)?Clean',
        '(?im)^##\s+.*(3\.\s*)?Report',
        '(?im)^##\s+.*(4\.\s*)?Role'
    )

    $matches = 0
    foreach ($pattern in $patterns) {
        if ($Content -match $pattern) { $matches = $matches + 1 }
    }
    return ($matches -eq 4)
}

function Test-Pattern {
    param([string]$Content, [string]$Pattern)
    return ($Content -match $Pattern)
}

function Test-EvidenceReferences {
    param([string]$Content)
    $patterns = @('Evidence','Artifacts','Verification','Logs','Results','Screenshots')
    $matches = 0
    foreach ($pattern in $patterns) {
        if ($Content -match "(?i)$pattern") { $matches = $matches + 1 }
    }
    return ($matches -ge 2)
}

function Test-ActorDeclaration {
    param([string]$Content)
    return ($Content -match '(?im)^\*\*Actor\*\*\s*:' -or $Content -match '(?im)^Actor\s*:')
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
        ArtifactsDir = $ArtifactsDir
        GenerateReport = $GenerateReport.IsPresent
    } | ConvertTo-Json -Compress)) 'INFO'

    if (-not (Test-Path -Path $ReportsPath)) {
        throw "Reports path '$ReportsPath' not found."
    }

    $reportsRoot = (Resolve-Path -Path $ReportsPath).ProviderPath
    Write-ECRRLog "Starting ECRR compliance analysis..." 'INFO'

    $excludeNames = @('archive', 'backup')
    $files = Get-ChildItem -Path $reportsRoot -Filter '*.md' -Recurse | Where-Object {
        if ($_.Name -eq '.gitkeep') { return $false }
        if (-not $IncludeArchived) {
            foreach ($skip in $excludeNames) {
                if ($_.FullName -match "(?i)[\\/]$skip[\\/]") { return $false }
            }
        }
        return ($_.Name -match '\d{4}-\d{2}-\d{2}')
    }
    $reportFiles = @($files)

    $totalReports = $reportFiles.Count
    Write-ECRRLog "Found $totalReports ECRR reports to analyze" 'INFO'

    if ($totalReports -eq 0) {
        Write-ECRRLog 'No reports available to evaluate.' 'WARN'
        return 0
    }

    $metrics = @{
        FourSectionChecked = 0; FourSectionCompliant = 0
        GateChecked = 0; GateCompliant = 0
        ProductionChecked = 0; ProductionCompliant = 0
        ActorChecked = 0; ActorCompliant = 0
        EvidenceChecked = 0; EvidenceCompliant = 0
        StatusChecked = 0; StatusCompliant = 0
    }

    $compliantCount = 0
    $nonCompliant = New-Object System.Collections.Generic.List[object]

    foreach ($file in $reportFiles) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        if (-not $content) { continue }

        $issues = New-Object System.Collections.Generic.List[string]

        $hasSections = Test-FourSectionStructure -Content $content
        $metrics.FourSectionChecked = $metrics.FourSectionChecked + 1
        if ($hasSections) { $metrics.FourSectionCompliant = $metrics.FourSectionCompliant + 1 } else { $null = $issues.Add('Missing four-section structure') }

        $hasGate = Test-Pattern -Content $content -Pattern '(?im)^##\s+.*ECRR Gate'
        $metrics.GateChecked = $metrics.GateChecked + 1
        if ($hasGate) { $metrics.GateCompliant = $metrics.GateCompliant + 1 } else { $null = $issues.Add('Missing ECRR Gate') }

        $hasProduction = Test-Pattern -Content $content -Pattern '(?im)✅\s*\*\*PRODUCTION READY\*\*|(?im)PRODUCTION\s+READY'
        $metrics.ProductionChecked = $metrics.ProductionChecked + 1
        if ($hasProduction) { $metrics.ProductionCompliant = $metrics.ProductionCompliant + 1 } else { $null = $issues.Add('Missing production marker') }

        $hasActor = Test-ActorDeclaration -Content $content
        $metrics.ActorChecked = $metrics.ActorChecked + 1
        if ($hasActor) { $metrics.ActorCompliant = $metrics.ActorCompliant + 1 } else { $null = $issues.Add('Missing actor declaration') }

        $hasEvidence = Test-EvidenceReferences -Content $content
        $metrics.EvidenceChecked = $metrics.EvidenceChecked + 1
        if ($hasEvidence) { $metrics.EvidenceCompliant = $metrics.EvidenceCompliant + 1 } else { $null = $issues.Add('Missing evidence references') }

        $hasStatus = Test-Pattern -Content $content -Pattern '(?im)^\*\*Status\*\*\s*:'
        $metrics.StatusChecked = $metrics.StatusChecked + 1
        if ($hasStatus) { $metrics.StatusCompliant = $metrics.StatusCompliant + 1 } else { $null = $issues.Add('Missing status declaration') }

        if ($issues.Count -eq 0) {
            $compliantCount = $compliantCount + 1
            continue
        }

        $entry = @{
            File = $file.Name
            Path = $file.FullName
            Date = Get-ReportDate -FileName $file.Name -Content $content
            Agent = Get-Actor -Content $content
            Category = Get-ReportCategory -FileName $file.Name
            Issues = $issues.ToArray()
        }
        $null = $nonCompliant.Add($entry)
    }

    $complianceRate = [math]::Round(($compliantCount / $totalReports) * 100, 2)
    Write-ECRRLog "Compliance analysis complete. Rate: $complianceRate%" 'SUCCESS'

    $result = @{
        GeneratedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
        ReportsPath = $reportsRoot
        TotalReports = $totalReports
        CompliantReports = $compliantCount
        ComplianceRate = $complianceRate
        NonCompliantReports = $nonCompliant.ToArray()
        Metrics = @{
            FourSection = @{ Checked = $metrics.FourSectionChecked; Compliant = $metrics.FourSectionCompliant; Rate = [math]::Round(($metrics.FourSectionCompliant / [Math]::Max(1, $metrics.FourSectionChecked)) * 100, 2) }
            ECRRGate    = @{ Checked = $metrics.GateChecked; Compliant = $metrics.GateCompliant; Rate = [math]::Round(($metrics.GateCompliant / [Math]::Max(1, $metrics.GateChecked)) * 100, 2) }
            Production  = @{ Checked = $metrics.ProductionChecked; Compliant = $metrics.ProductionCompliant; Rate = [math]::Round(($metrics.ProductionCompliant / [Math]::Max(1, $metrics.ProductionChecked)) * 100, 2) }
            Actor       = @{ Checked = $metrics.ActorChecked; Compliant = $metrics.ActorCompliant; Rate = [math]::Round(($metrics.ActorCompliant / [Math]::Max(1, $metrics.ActorChecked)) * 100, 2) }
            Evidence    = @{ Checked = $metrics.EvidenceChecked; Compliant = $metrics.EvidenceCompliant; Rate = [math]::Round(($metrics.EvidenceCompliant / [Math]::Max(1, $metrics.EvidenceChecked)) * 100, 2) }
            Status      = @{ Checked = $metrics.StatusChecked; Compliant = $metrics.StatusCompliant; Rate = [math]::Round(($metrics.StatusCompliant / [Math]::Max(1, $metrics.StatusChecked)) * 100, 2) }
        }
    }

    if ($GenerateReport) {
        $jsonPath = Join-Path -Path $ArtifactsDir -ChildPath 'ecrr-compliance-monitor.json'
        ($result | ConvertTo-Json -Depth 6) | Out-File -Encoding utf8 $jsonPath

        $reportLines = @(
            "ECRR Compliance Monitor Summary",
            "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            "",
            "Total Reports Analyzed: $totalReports",
            "Compliant Reports: $compliantCount",
            "Compliance Rate: $complianceRate%",
            "",
            "Metrics Breakdown:",
            "  Four-Section Structure: $($result.Metrics.FourSection.Rate)% ($($result.Metrics.FourSection.Compliant)/$($result.Metrics.FourSection.Checked))",
            "  ECRR Gate: $($result.Metrics.ECRRGate.Rate)% ($($result.Metrics.ECRRGate.Compliant)/$($result.Metrics.ECRRGate.Checked))",
            "  Production Marker: $($result.Metrics.Production.Rate)% ($($result.Metrics.Production.Compliant)/$($result.Metrics.Production.Checked))",
            "  Actor Declaration: $($result.Metrics.Actor.Rate)% ($($result.Metrics.Actor.Compliant)/$($result.Metrics.Actor.Checked))",
            "  Evidence References: $($result.Metrics.Evidence.Rate)% ($($result.Metrics.Evidence.Compliant)/$($result.Metrics.Evidence.Checked))",
            "  Status Declaration: $($result.Metrics.Status.Rate)% ($($result.Metrics.Status.Compliant)/$($result.Metrics.Status.Checked))",
            ""
        )

        if ($nonCompliant.Count -gt 0) {
            $reportLines += "Non-Compliant Reports:"
            foreach ($nc in $nonCompliant) {
                $reportLines += "  - $($nc.File): $($nc.Issues -join ', ')"
            }
        } else {
            $reportLines += "All reports are compliant! ✅"
        }

        $txtPath = Join-Path -Path $ArtifactsDir -ChildPath 'ecrr-compliance-summary.txt'
        $reportLines | Out-File -Encoding utf8 $txtPath
        Write-Host "Artifacts written to $jsonPath and $txtPath" -ForegroundColor Green
    }

    return $result
    Write-ECRRLog 'ECRR Compliance Monitor completed successfully' 'SUCCESS'

} catch {
    Write-ECRRLog "Error in ECRR Compliance Monitor: $($_.Exception.Message)" 'ERROR'
    if ($PSBoundParameters.ContainsKey('Verbose')) {
        Write-Host $_.Exception.ToString() -ForegroundColor DarkGray
    }
    exit 1
}