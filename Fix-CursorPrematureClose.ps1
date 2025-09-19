# Save as: Fix-CursorPrematureClose.ps1  (run in elevated PowerShell)

Write-Host "`n=== Cursor 'Premature close' - Fix and Diagnostics ===`n"

# 0) Close Cursor cleanly
Get-Process Cursor -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# 1) Time sync (TLS hates clock skew)
w32tm /resync /force | Out-Null

# 2) Disable Electron HTTP/2 (common root cause)
#    Reversible: set to 0 or delete this env var to undo.
setx ELECTRON_DISABLE_HTTP2 1 | Out-Null

# 3) Clear WinHTTP proxy (leaves your browser proxy alone)
try { netsh winhttp reset proxy | Out-Null } catch {}

# 4) Ensure strong TLS ciphers in .NET/Electron host
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -Name "SchUseStrongCrypto" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -Name "SchUseStrongCrypto" -Value 1 -PropertyType DWord -Force | Out-Null

# 5) Quick connectivity tests
function T([string]$name,[scriptblock]$test){
  try{
    if((& $test)){Write-Host ("[OK]  {0}" -f $name) -ForegroundColor Green}
    else{Write-Host ("[FAIL] {0}" -f $name) -ForegroundColor Red}
  }catch{Write-Host ("[ERR] {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Yellow}
}

$targets = @(
  @{N="DNS api.cursor.sh" ; S={ (nslookup api.cursor.sh) -match "Address:" } },
  @{N="DNS api.openai.com"; S={ (nslookup api.openai.com) -match "Address:" } },
  @{N="443 api.cursor.sh" ; S={ (Test-NetConnection api.cursor.sh -Port 443).TcpTestSucceeded } },
  @{N="443 api.openai.com"; S={ (Test-NetConnection api.openai.com -Port 443).TcpTestSucceeded } }
)
$targets | ForEach-Object { T $_.N $_.S }

# 6) Check for TLS interception/AV proxy by grabbing headers
function Head($u){ try{ (curl.exe -I $u --max-time 8) 2>$null }catch{} }
Write-Host "`n--- api.cursor.sh headers ---" -ForegroundColor Cyan
Head "https://api.cursor.sh/"
Write-Host "`n--- api.openai.com headers ---" -ForegroundColor Cyan
Head "https://api.openai.com/"

# 7) Relaunch Cursor
$cursor = "$Env:LocalAppData\Programs\cursor\Cursor.exe"
if(Test-Path $cursor){
  Start-Process $cursor
  Write-Host "`nLaunched Cursor. If issues persist, see NEXT STEPS below." -ForegroundColor Cyan
}else{
  Write-Host "Cursor.exe not found at expected path: $cursor" -ForegroundColor Yellow
}

Write-Host "`n=== NEXT STEPS (only if still failing) ===" -ForegroundColor Magenta
@'
1) Turn off TLS interception in any security tools (Zscaler/NetSkope/AdGuard/Kaspersky/etc.).
   • Add allow-list exceptions (no HTTPS inspection) for:
     - api.cursor.sh
     - telemetry.cursor.sh
     - api.openai.com
     - api.anthropic.com
     - openrouter.ai

2) In Cursor:
   • Settings → AI: temporarily switch to Cursor's default provider.
   • Ensure the provider matches your key (OpenAI vs Anthropic, etc.).
   - Disable any custom HTTP proxy; use System or None.

3) Update Cursor (Help → Check for Updates). Older Electron builds trigger HTTP/2 'premature close' more often.

4) VPN: disconnect or switch server. Some VPNs drop HTTP/2 streams mid-flight.

5) Extensions: run Cursor with extensions disabled and retry the same action.

6) For stubborn cases:
   • netsh int ip reset & netsh winsock reset  (requires reboot)
   • Reboot to apply TLS registry changes.
'@ | Write-Host
