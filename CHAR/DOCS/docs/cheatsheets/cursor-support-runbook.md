# Cursor Support Runbook

Codex Agent drop-in checklist for escalating Cursor `ConnectError [internal]` incidents.
Aligns with BossCat ECRR: **Examine → Clean → Report → Role**.

## 1. Quick Sanity Checks

### 1.1 Network & DNS

- `nslookup api.cursor.sh`
- `tracert cursor.sh`
- `Test-NetConnection cursor.sh -Port 443`
- `curl -I https://api.cursor.sh` (Windows built-in `curl` works)

### 1.2 Proxy / VPN / Firewall

- `netsh winhttp show proxy` (capture the output)
- If on VPN, retry with it **off**. If VPN is mandatory, add an outbound allow rule for `*.cursor.sh:443`.
- Temporarily disable third-party firewall/AV web shields to rule out TLS interception.

### 1.3 Clock & Certificates

- Ensure system time and timezone are accurate (TLS rejects clock drift).
- If corporate TLS interception exists, note it and capture the root CA name.

### 1.4 Clean App Restart

- In Cursor: `Ctrl+Shift+P` → **Reload Window**.
- Fully quit Cursor (confirm no background processes), then relaunch.
- Run one clean session with no extensions or custom MCP servers enabled, if applicable.

### 1.5 Update / Repair

- `Help → About → Check for Updates`. If update fails or the cache looks corrupted, reinstall Cursor in place.

## 2. Collect Diagnostics

### 2.1 Required Artifacts

- Logs: `C:\Users\<you>\AppData\Roaming\Cursor\logs\`
- State DB: `C:\Users\<you>\AppData\Roaming\Cursor\User\globalStorage\state.vscdb`
- Local config (if relevant): `C:\Users\fubum\.codex\config.toml`

### 2.2 PowerShell Bundle Script

```powershell
$logs = "$env:APPDATA\Cursor\logs"
$state = "$env:APPDATA\Cursor\User\globalStorage\state.vscdb"
$cfg   = "C:\Users\fubum\.codex\config.toml"
$dest  = "$env:USERPROFILE\Desktop\cursor-support-bundle.zip"
Compress-Archive -Path $logs,$state,$cfg -DestinationPath $dest -Force
Write-Host "Bundle: $dest"
```

### 2.3 Minimal Network Probe Output

```powershell
nslookup api.cursor.sh
tracert cursor.sh
Test-NetConnection cursor.sh -Port 443
netsh winhttp show proxy
curl -I https://api.cursor.sh
```

### 2.4 Redaction Reminder

Before sharing, open the `.log` files and redact API keys, tokens, or sensitive hostnames.
Support needs timestamps, request IDs, errors, and network/proxy context—not secrets.

## 3. Support Escalation Package

### 3.1 Email Template

**To:** `support@cursor.sh`  
**Subject:** `Request ID 3797d78f-d191-4760-98fb-9285a6748649 – ConnectError [internal]`

```text
Issue: Cursor fails with ConnectError [internal]. It occurs [immediately on app open / only when invoking Codex], on Windows 11.

Request ID: 3797d78f-d191-4760-98fb-9285a6748649
Cursor version: (Help → About) [paste here]
Happens since: [approx date & time, local timezone]

Actions tried:
- Reload Window / full app restart
- Updated to latest
- Toggled VPN off / added allow rule for *.cursor.sh:443
- Verified no corporate proxy or listed it below
- Clean start without extensions/MCP

Environment:
- OS: Windows 11 [build number]
- Network: Home/Corp [select]; wired/wifi
- Proxy (winhttp): [paste `netsh winhttp show proxy` output]
- Clock/timezone: [correct / was off by X min, now corrected]
- TLS interception: [Yes/No]. If Yes: root CA “[name]”

Diagnostics attached:
- cursor-support-bundle.zip (logs + state.vscdb + .codex\config.toml)
- Network probes:
  - nslookup api.cursor.sh: [paste]
  - tracert cursor.sh: [paste first/last hops]
  - Test-NetConnection cursor.sh -Port 443: [True/False]
  - netsh winhttp show proxy: [paste or note “Direct access”]
  - curl -I https://api.cursor.sh: [status/headers]
- Screenshot or text of the full stack trace, if available

Please check the internal trace for the Request ID above. Let me know if this is an account token/session issue, an upstream outage, or a local environment fault. If it’s auth/token: I can do Help → Sign Out, sign back in, and re-run a single Codex query to regenerate the session.
```

### 3.2 Runbook Notes

- Attach the `cursor-support-bundle.zip` from the PowerShell script.
- Keep the email/body ready as a template for future incidents; update the Request ID per case.
- Store a copy of the sent package under `CHAR/ECRR/ECRR_REPORTS/` for audit traceability.

## 4. Follow-Up Scenarios

- **Auth / Token Issue:** `Help → Sign Out`, close the app completely, reopen, sign in,
  execute one Codex prompt. If the error persists, request that Cursor support invalidate
  the session on their end.
- **Proxy / TLS Issue:** Update WinHTTP proxy settings or remove stale entries, and ensure
  `*.cursor.sh` bypasses interception. If TLS inspection is mandatory, coordinate with IT
  to whitelist Cursor domains or provide a compatible CA chain.
- **Upstream Incident:** Note support’s incident number and add it to `docs/IONA_ERRORS.md`
  with the status and resolution timestamp.

## 5. Evidence Logging

- Record the completed steps, probe results, and support ticket reference in an ECRR report (`CHAR/ECRR/ECRR_REPORTS/`).
- Add a one-line entry to `docs/BossCat/BOSSCAT_LOG.md` with the ticket status (the queue-steward tracker belonged to
  the site lane, split out in Pack 3B).
- Inform BossCat OEM if repeated failures occur (there is no nightly governance check — review is per change).


