# Post-process consolidated ECRR reports: redact tokens and normalize markers
param(
    [string[]]$Files = @(
        "CHAR/ECRR/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md",
        "CHAR/ECRR/ECRR_REPORTS/2025-09-29-ecrr-01-consolidated.md",
        "CHAR/ECRR/ECRR_REPORTS/2025-09-29-compliance-automation-consolidated.md"
    )
)

$ErrorActionPreference = "Stop"

foreach ($f in $Files) {
    if (-not (Test-Path $f)) { Write-Host "Skip (missing): $f" -ForegroundColor DarkGray; continue }
    $c = Get-Content -Path $f -Raw -Encoding UTF8

    # Redact any API token backticked value
    $c = $c -replace '(?im)(\*\*API Token\*\*:\s*)`[^`]+`', '$1[REDACTED]'

    # Redact any long backticked token-like strings
    $c = $c -replace '(?m)`[A-Za-z0-9+/=_-]{24,}`', '[REDACTED]'

    # Normalize headings with stray ? or replacement chars
    $c = $c -replace '(?m)^(#{2,}\s*)([\?\uFFFD\s]+)', '$1'

    # Normalize lines like ": ? **TEXT**" -> ": **TEXT**"
    $c = $c -replace '(?m)(:)\s*[\?\uFFFD]+\s*(\*\*)', '$1 $2'

    # Normalize checklist bullets starting with "- ?"
    $c = $c -replace '(?m)^-\s*[\?\uFFFD]+\s+', '- '

    # Remove isolated replacement chars near bold markers
    $c = $c -replace '(?m)[\?\uFFFD]+\s*(\*\*)', '$1'

    # Replace common mojibake arrow separators with ASCII arrow
    $c = $c -replace '[\u001a\uFFFD]+', ''

    Set-Content -Path $f -Encoding UTF8 -Value $c
    Write-Host "Normalized & redacted: $f" -ForegroundColor Green
}

