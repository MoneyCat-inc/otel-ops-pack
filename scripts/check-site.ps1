Param(
  [string]$Root = 'docs',
  [switch]$Strict,
  [string]$OutJson = 'DELT/ARTF/site-csp-gate.json'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir($p){ $d=Split-Path -Parent $p; if($d -and -not(Test-Path $d)){ New-Item -ItemType Directory -Force -Path $d|Out-Null } }
Ensure-Dir $OutJson

if (-not (Test-Path -LiteralPath $Root)) { Write-Error "Root not found: $Root"; exit 20 }

$allowedScriptHosts = @('self','cdn.jsdelivr.net')

$files = Get-ChildItem -LiteralPath $Root -Recurse -File -Include *.html -ErrorAction SilentlyContinue
$results = @()
$violations = 0

foreach ($f in $files) {
  $html = Get-Content -Raw -LiteralPath $f.FullName

  $cspPresent = ($html -match 'Content-Security-Policy')
  $cspConnectSelf = ($html -match "connect-src 'self'")
  $hasInlineStyle = ($html -match '<style(>|\s)')
  $hasInlineScript = ($html -match '<script(?![^>]*\bsrc=)')
  $hasInlineHandlers = ($html -match '\son[a-zA-Z]+\s*=')

  $scriptTags = [regex]::Matches($html, '<script[^>]*>', 'IgnoreCase') | ForEach-Object { $_.Value }
  $scriptsInfo = @()
  foreach ($tag in $scriptTags) {
    if ($tag -match 'src="([^"]+)"') {
      $src = $Matches[1]
      $uri = $null
      $shost = 'self'
      if ($src -match '^https?://') {
        try { $uri = [uri]$src; $shost = $uri.Host } catch { $shost = 'unknown' }
      }
      $hasSri = ($tag -match 'integrity="sha384-')
      $scriptsInfo += [pscustomobject]@{ src=$src; host=$shost; sri=$hasSri }
      if ($shost -ne 'self' -and -not $allowedScriptHosts.Contains($shost)) { $violations++; }
      if ($shost -ne 'self' -and -not $hasSri) { $violations++ }
    }
  }

  # Mermaid specific rule: if mermaid appears, require >=10.9.4 when using CDN
  $mermaidMatch = Select-String -InputObject $html -Pattern 'mermaid@([0-9]+)\.([0-9]+)\.([0-9]+)' -AllMatches | ForEach-Object { $_.Matches } | Select-Object -First 1
  $mermaidOk = $true
  if ($mermaidMatch) {
    $maj=[int]$mermaidMatch.Groups[1].Value; $min=[int]$mermaidMatch.Groups[2].Value; $pat=[int]$mermaidMatch.Groups[3].Value
    if ($maj -lt 10 -or ($maj -eq 10 -and ($min -lt 9 -or ($min -eq 9 -and $pat -lt 4)))) { $mermaidOk=$false }
    if (-not $mermaidOk) { $violations++ }
  }

  if (-not $cspPresent) { $violations++ }
  if (-not $cspConnectSelf) { $violations++ }
  if ($Strict) {
    if ($hasInlineStyle) { $violations++ }
    if ($hasInlineScript) { $violations++ }
    if ($hasInlineHandlers) { $violations++ }
  }

  $results += [pscustomobject]@{
    path = $f.FullName.Substring((Resolve-Path ".").Path.Length+1)
    cspPresent = $cspPresent
    cspConnectSelf = $cspConnectSelf
    inlineStyle = $hasInlineStyle
    inlineScript = $hasInlineScript
    inlineHandlers = $hasInlineHandlers
    scripts = $scriptsInfo
    mermaidOk = $mermaidOk
  }
}

$status = if ($violations -le 0) { 'PASS' } else { 'FAIL' }
$out = [pscustomobject]@{
  gate = 'SITE_HTML_CSP'
  status = $status
  violations = $violations
  files = $results
  timestamp = (Get-Date).ToString('o')
}
$out | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutJson -Encoding utf8
if ($status -ne 'PASS') { Write-Error "SITE_HTML_CSP violations: $violations"; exit 21 }
exit 0
