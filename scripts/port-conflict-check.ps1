# Port Conflict Check — reports listeners on key ports and overall status
# Usage:
#   pwsh -NoLogo -NoProfile -File scripts/port-conflict-check.ps1

$ErrorActionPreference = 'Stop'

$ports = @(5317, 5318, 14317, 14318, 8080)
$results = @()

foreach ($p in $ports) {
    try {
        $conns = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue
    } catch {
        $conns = @()
    }
    if (-not $conns) {
        $results += [pscustomobject]@{ port = $p; state = 'closed'; proc = ''; pid = '' }
    } else {
        foreach ($c in $conns) {
            $ownerPid = $c.OwningProcess
            $procName = ''
            try { $procName = (Get-Process -Id $ownerPid -ErrorAction SilentlyContinue).ProcessName } catch { $procName = '' }
            $results += [pscustomobject]@{ port = $p; state = 'listening'; proc = $procName; pid = $ownerPid }
        }
    }
}

# Determine a conservative ok flag: 5318 and 8080 should be listening; others optional depending on mapping.
$wantOpen = @(5318, 8080)
$ok = $true
foreach ($w in $wantOpen) {
    $row = $results | Where-Object { $_.port -eq $w -and $_.state -eq 'listening' }
    if (-not $row) { $ok = $false }
}

# Emit human readable and machine-friendly JSON
Write-Host 'Port Check (listening state):' -ForegroundColor Cyan
foreach ($r in ($results | Sort-Object port)) {
    $tag = if ($r.state -eq 'listening') { 'OK' } else { 'CLOSED' }
    Write-Host (" - {0}: {1}  pid={2} proc={3}" -f $r.port, $tag, ($r.pid | Out-String).Trim(), $r.proc)
}

$summary = [pscustomobject]@{
    ok      = $ok
    details = ($results | Sort-Object port)
}

return $summary


