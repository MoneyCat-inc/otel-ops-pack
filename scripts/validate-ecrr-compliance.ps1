# Validate ECRR Compliance across reports
# Outputs JSON + Markdown summaries in artifacts/

param(
	[string]$ReportsPath = "docs/ECRR_REPORTS",
	[string]$OutDir = "artifacts",
	[switch]$Verbose
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function Test-HasSection {
	param([string]$content, [string]$pattern)
	return [regex]::IsMatch($content, $pattern, 'Singleline')
}

$files = Get-ChildItem -Path $ReportsPath -Recurse -Filter *.md | Where-Object {
	$_.FullName -notmatch "(/|\\)(archive|backup)(/|\\)" -and $_.Name -notmatch "^\.gitkeep$"
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

	$hasExamine = Test-HasSection $content "##\s*🔍[\s\S]*?Examine|##\s*1\.[\s\S]*?Examine"
	$hasClean   = Test-HasSection $content "##\s*🧹[\s\S]*?Clean|##\s*2\.[\s\S]*?Clean"
	$hasReport  = Test-HasSection $content "##\s*📝[\s\S]*?Report|##\s*3\.[\s\S]*?Report"
	$hasRole    = Test-HasSection $content "##\s*🎭[\s\S]*?Role|##\s*4\.[\s\S]*?Role"

	$four = $hasExamine -and $hasClean -and $hasReport -and $hasRole

	$gate = Test-HasSection $content "##\s*✅\s*\*\*ECRR Gate\*\*|##\s*ECRR Gate"
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

	if ($fileIssues.Count -eq 0) { $ok++ }
	else {
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
		fourSection = if ($total -gt 0) { [math]::Round(($metrics.hasFourSection/$total)*100,1) } else { 0 }
		ecrrGate    = if ($total -gt 0) { [math]::Round(($metrics.hasEcrrGate/$total)*100,1) } else { 0 }
		actor       = if ($total -gt 0) { [math]::Round(($metrics.hasActor/$total)*100,1) } else { 0 }
		production  = if ($total -gt 0) { [math]::Round(($metrics.hasProductionMarker/$total)*100,1) } else { 0 }
		fullyCompliant = if ($total -gt 0) { [math]::Round(($ok/$total)*100,1) } else { 0 }
	}
	fullyCompliantCount = $ok
	nonCompliant = $issues
}

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

return $result
 
