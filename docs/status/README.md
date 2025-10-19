# 📊 Status & Registry Files

**Location:** `docs/status/`  
**Purpose:** Canonical registries and operational metadata  
**Maintained:** Automatically generated, manually triggered

---

## 📁 Files in This Directory

### Core Registries

**`REFERENCES_MAP.json`** / **`REFERENCES_MAP.md`**
- Canonical reference map with 7 buckets
- Single source of truth for all working parts
- **Update:** Manual (when adding canonical references)

**`scripts.json`**
- PowerShell scripts registry categorized by lane
- Includes file size, modification date, lane assignment
- **Regenerate:** After adding/modifying scripts in `scripts/`

**`workflows.json`**
- GitHub Actions workflows registry
- Extracted triggers from `on:` block only (YAML-aware)
- **Regenerate:** After adding/modifying workflows in `.github/workflows/`

**`orphans.md`**
- Triage list for orphaned documentation
- Keep/merge/archive decisions
- **Update:** During documentation cleanup cycles

---

## 🔄 Regeneration Commands

### Workflows Registry

**When to regenerate:**
- After adding new workflow files
- After modifying workflow triggers (`on:` block)
- After renaming/deleting workflows

**Quick command (can be run from any directory):**
```powershell
pwsh scripts/regenerate-workflows-registry.ps1
```

**Manual command (if needed):**
```powershell
cd c:\otel

$workflows = Get-ChildItem .github\workflows\*.yml,.github\workflows\*.yaml -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $name = $_.BaseName
    $triggers = @()
    
    # Extract on: block (YAML-aware)
    $lines = $content -split "`n"
    $inOnBlock = $false
    $onBlockLines = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^on:\s*$') {
            $inOnBlock = $true
            continue
        }
        if ($inOnBlock) {
            if ($line -match '^\w+:' -and $line -notmatch '^\s+') {
                break
            }
            if ($line -match '^\s+(\w+):') {
                $onBlockLines += $matches[1]
            }
        }
    }
    
    $onBlock = $onBlockLines -join ' '
    
    # Detect triggers from on: block only
    if ($onBlock -match 'push') { $triggers += 'push' }
    if ($onBlock -match 'pull_request') { $triggers += 'pull_request' }
    if ($onBlock -match 'schedule') { $triggers += 'schedule' }
    if ($onBlock -match 'workflow_dispatch') { $triggers += 'workflow_dispatch' }
    if ($onBlock -match 'workflow_call') { $triggers += 'workflow_call' }
    if ($onBlock -match 'workflow_run') { $triggers += 'workflow_run' }
    if ($onBlock -match 'release') { $triggers += 'release' }
    if ($onBlock -match 'issues') { $triggers += 'issues' }
    
    $triggerStr = if ($triggers.Count -gt 0) {
        ($triggers | Sort-Object -Unique) -join ', '
    } else {
        'none'
    }
    
    $scheduled = $triggers -contains 'schedule'
    
    [pscustomobject]@{
        name = $name
        path = $_.FullName.Replace('C:\otel\','').Replace('\','/')
        size = $_.Length
        modified = $_.LastWriteTime
        triggers = $triggerStr
        scheduled = $scheduled
    }
}

@{
    updated = (Get-Date -Format 'o')
    total = $workflows.Count
    description = 'GitHub Actions workflows registry - triggers extracted from on: block only'
    workflows = $workflows
} | ConvertTo-Json -Depth 4 | Out-File docs\status\workflows.json -Encoding UTF8

Write-Host "✅ workflows.json regenerated ($($workflows.Count) workflows)" -ForegroundColor Green
```

**Verification:**
```powershell
# Spot-check a few workflows
$json = Get-Content docs\status\workflows.json -Raw | ConvertFrom-Json
$json.workflows | Where-Object { $_.name -in @('bosscat-gate-bot-native', 'bosscat-gate-verify', 'apisec-scan') } | Format-Table name, triggers
```

---

### Scripts Registry

**When to regenerate:**
- After adding new PowerShell scripts
- After moving scripts between directories
- After lane reassignments

**Command:**
```powershell
cd c:\otel

$files = Get-Content artifacts\index\files.json -Raw | ConvertFrom-Json
$scripts = $files | Where-Object {
    $_.FullName -like "*\scripts\*" -and $_.FullName -like "*.ps1"
} | ForEach-Object {
    $name = [IO.Path]::GetFileName($_.FullName)
    $lane = if ($name -match 'gate|verify') { 'GATE' }
            elseif ($name -match 'monitor|canary|test') { 'SSOT' }
            elseif ($name -match 'benchmark|process') { 'COMP' }
            elseif ($name -match 'hub|export') { 'DOCS' }
            else { 'UTIL' }
    
    [pscustomobject]@{
        name = $name
        path = $_.FullName.Replace('C:\otel\','').Replace('\','/')
        size = $_.Length
        modified = $_.LastWriteTime
        lane = $lane
    }
}

@{
    updated = (Get-Date -Format 'o')
    total = $scripts.Count
    scripts = $scripts
} | ConvertTo-Json -Depth 4 | Out-File docs\status\scripts.json -Encoding UTF8

Write-Host "✅ scripts.json regenerated ($($scripts.Count) scripts)" -ForegroundColor Green
```

---

## 🛡️ Quality Guardrails

### Workflows Registry

**MUST extract triggers from `on:` block only**
- ❌ DO NOT search entire file (matches `permissions: issues: write`)
- ✅ DO use YAML-aware block extraction
- ✅ DO stop at next top-level key (concurrency, permissions, env, jobs)

**Validation checks:**
```powershell
# No false 'issues' triggers
$json = Get-Content docs\status\workflows.json -Raw | ConvertFrom-Json
$falseIssues = $json.workflows | Where-Object { $_.triggers -match '\bissues\b' }
if ($falseIssues.Count -gt 0) {
    Write-Host "⚠️ WARNING: Found workflows with 'issues' trigger - verify these are real" -ForegroundColor Yellow
    $falseIssues | Select-Object name, triggers
}
```

### Scripts Registry

**Lane categorization:**
- **GATE:** Verification, gate checks
- **SSOT:** Monitoring, testing, canary
- **COMP:** Benchmarking, processing, analysis
- **DOCS:** Documentation, exports
- **UTIL:** Utilities, helpers

---

## 📚 Related Documentation

- **References Map:** [`REFERENCES_MAP.md`](REFERENCES_MAP.md)
- **Orphans Triage:** [`orphans.md`](orphans.md)
- **Inventory Files:** [`../../artifacts/index/`](../../artifacts/index/)
- **BossCat Governance:** [`../BossCat/IMMUTABLE_PERSONA_v1.1.md`](../BossCat/IMMUTABLE_PERSONA_v1.1.md)

---

## 🐾 Maintenance Schedule

**After every workflow change:**
- Regenerate `workflows.json`
- Verify no false positives
- Commit with descriptive message

**Monthly:**
- Review `orphans.md` for triage
- Update `REFERENCES_MAP.json` if canonical refs change
- Regenerate full inventory (`artifacts/index/`)

**Quarterly:**
- Audit lane assignments in `scripts.json`
- Review registry structure for improvements
- Archive old snapshots per retention policy

---

**Last Updated:** 2025-10-19  
**Maintained by:** Cursor{Implementer} under BossCat OEM  
**Methodology:** ECRR (Examine → Clean → Report → Role)

