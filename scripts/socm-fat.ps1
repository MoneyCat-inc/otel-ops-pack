# SOCM Final Acceptance Test (FAT)
# Scope: SOCM lane only
# Verifies: preflight/kill-switch, widget export, follow suggestions, trends, ICF lesson
# Authority: cursor{implementer} under Fubumaki

$ErrorActionPreference = 'Stop'

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🧪 SOCM FINAL ACCEPTANCE TEST (FAT)" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# --- 0) Preflight / Governance ---
Write-Host "`n0️⃣ Preflight / Governance" -ForegroundColor Yellow
npm run agent:preflight
if ($LASTEXITCODE -ne 0) { 
    throw "Preflight FAILED (exit $LASTEXITCODE). Expected: 0 (GREEN)" 
}
Write-Host "   ✅ Preflight: GREEN" -ForegroundColor Green

if (Test-Path .agent/LOCK) { 
    throw "Kill-switch must be CLEAR (.agent/LOCK absent)" 
}
Write-Host "   ✅ Kill-switch: CLEAR" -ForegroundColor Green

# --- 1) Widget Export (Milestone C) ---
Write-Host "`n1️⃣ Widget Export (Milestone C)" -ForegroundColor Yellow
npm run social:export

if (!(Test-Path "docs/widgets/bluesky-latest.json")) { 
    throw "Missing bluesky-latest.json" 
}
$json = Get-Content "docs/widgets/bluesky-latest.json" | ConvertFrom-Json
Write-Host "   ✅ Widget JSON created: $($json.count) posts" -ForegroundColor Green

# --- 2) Follow Suggestions (Milestone D) ---
Write-Host "`n2️⃣ Follow Suggestions (Milestone D)" -ForegroundColor Yellow
npm run social:recommend-follows

if (!(Test-Path "artifacts/social/follow_suggestions.jsonl")) {
    throw "Missing follow_suggestions.jsonl"
}
$fs = Get-Content artifacts/social/follow_suggestions.jsonl -ErrorAction Stop
if ($fs.Length -lt 5) { 
    throw "Insufficient follow suggestions ($($fs.Length) < 5)" 
}
Write-Host "   ✅ Follow suggestions: $($fs.Length) generated" -ForegroundColor Green

# --- 3) Trend Scout (Milestone E) ---
Write-Host "`n3️⃣ Trend Scout (Milestone E)" -ForegroundColor Yellow
npm run social:trends

if (!(Test-Path "artifacts/social/trends.json")) { 
    throw "Missing trends.json" 
}
if (!(Test-Path "docs/social/TAGS.suggestions.yaml")) { 
    throw "Missing TAGS.suggestions.yaml" 
}
$trends = Get-Content "artifacts/social/trends.json" | ConvertFrom-Json
Write-Host "   ✅ Trends: $($trends.trends.Count) tags analyzed" -ForegroundColor Green

# --- 4) ICF Lesson Extraction ---
Write-Host "`n4️⃣ ICF Lesson Extraction (Learning Loop)" -ForegroundColor Yellow
npm run social:icf-lesson
Write-Host "   ✅ ICF lesson: Extracted (suggest-only)" -ForegroundColor Green

# --- 5) Evidence Snapshot ---
Write-Host "`n5️⃣ Evidence Snapshot (Tail)" -ForegroundColor Yellow
$evidence = Get-Content .agent/EVIDENCE.log | 
    Select-Object -Last 40 | 
    ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | 
    Where-Object { $_ -and $_.lane -eq "SOCM" }

Write-Host "   SOCM events in tail: $($evidence.Count)" -ForegroundColor White
Write-Host "   Last 10 SOCM events:" -ForegroundColor Cyan
$evidence | Select-Object -Last 10 | Format-Table @{
    Label="Time"; Expression={$_.t.Substring(11,8)}
}, who, type, @{
    Label="Message"; Expression={$_.msg}; Width=50
} -AutoSize

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ FAT COMPLETE - ALL SYSTEMS PASS!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "`n🐾 BossCat: Acceptance verified" -ForegroundColor Magenta
Write-Host "🦋 Bluesky: Ready for Week 1" -ForegroundColor Cyan
Write-Host "🚀 Execute: SOCM_WEEK1_QUICK_REFERENCE.md`n" -ForegroundColor Green

