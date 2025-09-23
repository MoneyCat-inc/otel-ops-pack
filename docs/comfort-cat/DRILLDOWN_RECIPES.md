# Comfort Cat — Drilldown Recipes

## High-severity drilldown (15m)

Purpose: Turn high-volume logs into calm, actionable findings.

Steps (SigNoz UI)
- Time: Last 15 minutes (adjust as needed)
- Filter: `severity_text` is in `ERROR, WARN`
- Optional keyword: `severity_text in ["ERROR","WARN"] AND message contains "login"`
- Group by: `service.name`, `severity_text`
- Inspect: expand a log → Attributes (`service.name`, `host.name`, `log.file.path`, `exception.*`, `http.*`)
- Trace pivot: if `traceId` present → "View related trace"

Saved view name
- Comfort Cat — High-severity drilldown (15m)

Notes
- Keep keyword filters minimal (one focused term)
- Color-safe indicators; avoid noisy alerts until patterns repeat
- Cat Nap Control Room aesthetic: serene, efficient, sub‑second navigation


