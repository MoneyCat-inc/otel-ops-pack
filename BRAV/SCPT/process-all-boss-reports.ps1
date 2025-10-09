# BossCat Reports Processing Script - Complete Analysis
param(
    [string]$ReportsDir = "docs/BossCat/reports",
    [string]$OutputDir = "artifacts",
    [int]$MaxParallel = 8
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 BossCat Reports Processing - Complete Analysis" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

if (-not (Test-Path $ReportsDir)) {
    Write-Host "No BossCat reports directory found: $ReportsDir" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$files = Get-ChildItem -Path $ReportsDir -Filter "*.md" -File -Recurse

Write-Host ("📊 Found {0} BossCat reports to process" -f $files.Count) -ForegroundColor Green

$an = @{
    TotalReports = $files.Count
    ProcessedReports = 0
    Metrics = @{
        HasGate = 0
        HasStatus = 0
        HasEvidence = 0
        HasActionItems = 0
    }
    Issues = @()
}

function Get-BossReportInfo {
    param([System.IO.FileInfo]$file)

    $result = [ordered]@{
        Name = $file.Name
        Path = $file.FullName.Replace("\\","/")
        Timestamp = $null
        HasGate = $false
        HasStatus = $false
        HasEvidence = $false
        HasActionItems = $false
        Error = $null
    }

    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        $result.HasGate = [regex]::IsMatch($content, "ECRR Gate|##\s+ECRR Gate", 'IgnoreCase')
        $result.HasStatus = [regex]::IsMatch($content, "Status|FINAL|COMPLETE|SUCCESS", 'IgnoreCase')
        $result.HasEvidence = [regex]::IsMatch($content, "Evidence|Artifacts|Screenshots|Logs", 'IgnoreCase')
        $result.HasActionItems = [regex]::IsMatch($content, "Action Items|Next Steps", 'IgnoreCase')

        # Extract first ISO-like timestamp if present, else infer from name
        $m = [regex]::Match($content, "\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}[:\d{2}]?")
        if ($m.Success) {
            $result.Timestamp = $m.Value
        } else {
            $nameDate = [regex]::Match($file.Name, "(20\d{2}-\d{2}-\d{2})")
            if ($nameDate.Success) { $result.Timestamp = "$($nameDate.Groups[1].Value) 00:00:00" }
        }
    } catch {
        $result.Error = $_.Exception.Message
    }

    [pscustomobject]$result
}

$processor = { param($f) Get-BossReportInfo -file $f }

if ($files.Count -gt 0) {
    if ($MaxParallel -gt 1) {
        Write-Host "Parallel mode not supported for this processor yet; running sequentially" -ForegroundColor Yellow
    }
    $results = foreach ($f in $files) { & $processor $f }
    $results = @($results)
} else {
    $results = @()
}

$an.ProcessedReports = $results.Count
$an.Metrics.HasGate = ($results | Where-Object { $_.HasGate }).Count
$an.Metrics.HasStatus = ($results | Where-Object { $_.HasStatus }).Count
$an.Metrics.HasEvidence = ($results | Where-Object { $_.HasEvidence }).Count
$an.Metrics.HasActionItems = ($results | Where-Object { $_.HasActionItems }).Count
$an.Issues = @($results | Where-Object { $_.Error } | ForEach-Object { "Error processing $($_.Name): $($_.Error)" })

$summary = @{
    ProcessingDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    Totals = $an
    Reports = $results
}

$outJson = Join-Path $OutputDir "boss-processing-summary.json"
($summary | ConvertTo-Json -Depth 8) | Out-File -Encoding UTF8 $outJson
Write-Host "✅ Generated BossCat processing summary: $outJson" -ForegroundColor Green

$okPct = if ($an.TotalReports -gt 0) { [math]::Round(($an.Metrics.HasStatus / $an.TotalReports) * 100, 1) } else { 0 }
$md = @(
    "# BossCat Reports Processing - Summary",
    "",
    "Generated: $($summary.ProcessingDate)",
    "",
    "## Metrics",
    "- Total Reports: $($an.TotalReports)",
    "- With Gate: $($an.Metrics.HasGate)",
    "- With Status: $($an.Metrics.HasStatus) ($okPct%)",
    "- With Evidence: $($an.Metrics.HasEvidence)",
    "- With Action Items: $($an.Metrics.HasActionItems)"
)

$outMd = Join-Path $OutputDir "boss-processing-summary.md"
$md | Out-File -Encoding UTF8 $outMd
Write-Host "✅ Generated BossCat processing markdown: $outMd" -ForegroundColor Green

Write-Host "\n🎉 BossCat Processing Complete!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ("📊 Reports Processed: {0}/{1}" -f $an.ProcessedReports,$an.TotalReports) -ForegroundColor Cyan
Write-Host "📈 Summary exported: boss-processing-summary.json/.md" -ForegroundColor Cyan

