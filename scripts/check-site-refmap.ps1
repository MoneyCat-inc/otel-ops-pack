Param(
  [string]$HtmlPath = 'docs/status.html',
  [string]$OutJson = 'DELT/ARTF/refmap-gate.json'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function New-Result([string]$status,[string[]]$reasons){[pscustomobject]@{gate='SITE_REFMAP_PREVIEW';status=$status;reasons=$reasons;timestamp=(Get-Date).ToString('o')}}
function Ensure-Dir($p){ $d=Split-Path -Parent $p; if($d -and -not(Test-Path $d)){ New-Item -ItemType Directory -Force -Path $d|Out-Null } }
Ensure-Dir $OutJson

$reasons = New-Object System.Collections.ArrayList
$status = 'PASS'

if (-not (Test-Path -LiteralPath $HtmlPath)) { [void]$reasons.Add("missing: $HtmlPath"); $status='FAIL' }
else {
  $h = Get-Content -Raw -LiteralPath $HtmlPath
  # CSP present and contains connect-src 'self'
  if ($h -notmatch 'Content-Security-Policy') { [void]$reasons.Add('missing: CSP meta'); $status='FAIL' }
  if ($h -notmatch "connect-src 'self'") { [void]$reasons.Add("CSP connect-src must be 'self'"); $status='FAIL' }
  # No inline <style> or <script> blocks
  if ($h -match '<style>') { [void]$reasons.Add('inline <style> not allowed'); $status='FAIL' }
  if ($h -match '<script(?![^>]*\bsrc=)') { [void]$reasons.Add('inline <script> not allowed'); $status='FAIL' }
  # Mermaid version >= 10.9.4 and SRI if CDN
  $mermaidCdn = Select-String -InputObject $h -Pattern 'cdn.jsdelivr.*mermaid@([0-9]+)\.([0-9]+)\.([0-9]+)' -AllMatches | ForEach-Object { $_.Matches } | Select-Object -First 1
  $mermaidLocal = $h -match 'assets/.*/mermaid-10\.9\.4\.min\.js'
  if ($mermaidCdn) {
    $maj=[int]$mermaidCdn.Groups[1].Value; $min=[int]$mermaidCdn.Groups[2].Value; $pat=[int]$mermaidCdn.Groups[3].Value
    if ($maj -lt 10 -or ($maj -eq 10 -and ($min -lt 9 -or ($min -eq 9 -and $pat -lt 4)))) { [void]$reasons.Add('Mermaid version < 10.9.4'); $status='FAIL' }
    if ($h -notmatch 'integrity="sha384-') { [void]$reasons.Add('CDN mermaid requires SRI'); $status='FAIL' }
  } elseif (-not $mermaidLocal) {
    [void]$reasons.Add('Mermaid not found (CDN or local)'); $status='FAIL'
  }
}

$out = New-Result $status @($reasons)
$out | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutJson -Encoding utf8
if ($status -ne 'PASS') { Write-Error "SITE_REFMAP_PREVIEW: $($reasons -join '; ')"; exit 20 }
exit 0

