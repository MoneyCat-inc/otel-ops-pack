# ECRR Report Template

Copy this file, rename it to `docs/ECRR_REPORTS/<date>-<slug>.md`, and fill in all sections with actual data.

---

```markdown
# ECRR Report — <Feature/PR Title>

- date: YYYY-MM-DD
- actor: <Cursor Agent / Human>
- severity: <info|warning|critical>
- scope: <files/flows/user-journey>
- related: [jobs/tasks/PRs/dashboard IDs]
- time_spent: <e.g., 35m>
- outcome: <resolved|partial|in-progress>

---

## Examine (facts)
- build/sha: <link or SHA>
- urls: <http://localhost:8080 (SigNoz)>, OTLP http://localhost:5318/v1/logs
- crossOriginIsolated: <true/false>
- mic settings: { echoCancellation:false, noiseSuppression:false, autoGainControl:false }, sampleRate:<value>
- flow integrity: warm-up → glide → phrase → reflection = <ok/fail>
- local footprint: <size/state; reset?>

---

## Clean (actions)
- SW/caches cleared: <yes/no>
- IndexedDB/localStorage reset: <yes/no>
- services/ports restarted: <which>
- agent state: <running/stopped>, LOCK=<present/absent>
- guardrails enforced: local-first, privacy, idempotence

---

## Verify (proof)
- How to verify in SigNoz (UI):
  - UI → Logs → filter: `message contains "canary test"` or `attributes.dataset = "resonai_analytics"`
  - UI → Metrics → query: `otelcol_*` (ingest/receiver/exporter series)
- Commands:
  - `pwsh -File scripts\\verify-wiring.ps1`
- Artifacts:
  - `artifacts/<report-slug>-verify.txt`
  - `artifacts/<report-slug>-screenshot.png` (optional)

---

## Results
- before → after: <3 bullets>
- regressions: <none/list>
- follow-ups: <tickets/TODOs/alerts/dashboards>

---

## Root cause and prevention
- cause: <1 line>
- contributing: <1–2 bullets>
- prevention: <1–2 bullets>

---

## Role
- who: <agent/human>
- responsibilities: <short>
- artifacts produced: <reports/tests/configs>
- handoff notes: <next owner/step>

---

## ✅ ECRR Gate (required)
- Examine: [ ] facts captured; [ ] env documented; [ ] evidence listed
- Clean: [ ] guardrails enforced; [ ] actions recorded
- Report: [ ] results; [ ] regressions; [ ] follow-ups
- Role: [ ] actor declared; [ ] responsibilities; [ ] handoff

## Progress Animation (operations >2s)
For long-running operations, include animated progress indicators:
```powershell
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$progress = [math]::Round(($itemIndex / $totalItems) * 100)
Write-Host "`r$($spinner[$spinnerIndex]) Processing... $itemIndex/$totalItems ($progress%)" -NoNewline -ForegroundColor Cyan
```

Note: Comfort Cat aesthetic and a11y — see docs/comfort-cat/
```

---

This pairs with `docs/ECRR.md`. Together they lock in **ECRR** as both philosophy and practice.
