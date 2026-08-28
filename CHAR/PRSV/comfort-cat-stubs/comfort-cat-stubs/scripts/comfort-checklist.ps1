#Requires -Version 7
$root = "C:\otel\docs\comfort cat"
$must = "README.md","palette.md","type.md","motion.md","copy.md","proofpoints.md","accessibility.md","success-criteria.md"
$missing = @()
foreach($m in $must){ if(-not (Test-Path (Join-Path $root $m))){ $missing += $m } }
if($missing.Count -gt 0){
  Write-Host "Missing in ${root}:`n - $($missing -join "`n - ")" -ForegroundColor Yellow
  exit 1
}
Write-Host "Comfort Cat guidelines present & accounted for." -ForegroundColor Green
