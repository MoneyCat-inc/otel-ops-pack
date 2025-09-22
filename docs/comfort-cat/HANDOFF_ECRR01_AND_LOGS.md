# Comfort Cat Handoff — Expanded Walkthrough

*A verbose guide to calm log sleuthing and ECRR-01 evidence rituals*

---

## Purpose

This handoff gives you a **step-by-step, plain English path** for two critical tasks:

1. **Logs Drilldown** — how to calmly filter and explore logs in SigNoz so you can spot errors without drowning in noise.
2. **ECRR-01 Evidence Regeneration** — how to prove that your system enforces *Cross-Origin Isolation* (COOP/COEP headers) and works *offline* without errors.

The style is intentionally slow, clear, and kind — imagine sitting in a **Cat Nap Control Room** with low lights and no unnecessary clicks.

---

## What You’ll Use

- **SigNoz Logs UI** — the web interface where logs are filtered, grouped, and inspected.
- **Helper scripts** for generating ECRR-01 evidence:
  - On **Windows**: `scripts/ecrr/collect-evidence.ps1` (PowerShell script)
  - On **POSIX (Linux/Mac)**: `scripts/ecrr/collect-evidence.sh` (Shell script)

---

## Part A — Logs Drilldown (≈15 minutes)

The goal is to reduce log noise and highlight the errors and warnings that matter.

### 1. Set the Time Window

- **Do:** In SigNoz, go to **Logs**. At the top right, find the **Time Range** dropdown. Select **Last 15 minutes**. If you are investigating a specific incident, set the window to exactly that time span.
- **Why:** Smaller time slices mean less clutter. You’re looking at the freshest activity, not ancient noise.
- **Expect:** The total number of logs shown should drop. You may also notice spikes or bursts of activity become easier to see in charts.

---

### 2. Focus on Severity

- **Do:** Add a filter:
  - Field: `severity_text`
  - Condition: `is in`
  - Values: `ERROR`, `WARN`
- **Why:** You want claws, not purrs. INFO and DEBUG logs are often background chatter; Errors and Warnings reveal actual issues.
- **Expect:** The logs list shrinks to only those with meaningful problems.

---

### 3. (Optional) Add a Keyword

- **Do:** In the **search bar**, type something like:

```sql
severity_text in ["ERROR","WARN"] AND message contains "login"
```

  Replace `"login"` with whatever keyword matches the issue you’re chasing.
- **Why:** This lets you zoom in on a specific feature, endpoint, or error code.
- **Expect:** A smaller, more focused set of logs that tell a tighter story.

---

### 4. Surface Patterns

- **Do:** Use the **Group By** option to group logs by:
  - `service.name`
  - `severity_text`
- **Why:** Grouping shows patterns. You’ll see which services are producing the most problems, and at what severity.
- **Expect:** A panel displaying counts per service, sorted by error/warning volume.

---

### 5. Inspect Details

- **Do:** Click on a log row to expand it. Then go to the **Attributes** tab.
- **Why:** Attributes give context:
  - `service.name` → Which service emitted the log.
  - `host.name` → Which machine or container it came from.
  - `log.file.path` → Where in the code/logs it originated.
  - `exception.*` → Error type and stack trace if available.
  - `http.*` → HTTP details if it was a web request.
- **Expect:** You see a structured breakdown of the log. If `traceId` exists, you’ll see a “View related trace” button.

---

### 6. Pivot to Trace (when available)

- **Do:** If “View related trace” appears, click it.
- **Why:** This shows the trace timeline: upstream and downstream calls, spans, and how the log fits into the bigger picture.
- **Expect:** A timeline visualization, with your log highlighted.

---

### 7. Save the View

- **Do:** Save this layout with the name:

```
Comfort Cat — High-severity drilldown (15m)
```

- **Why:** So next time you can return with one click to a calm, focused setup.

---

## Part B — Prove Isolation + Offline (ECRR-01 Evidence)

Now we switch from logs to evidence. This process checks:

- **COOP/COEP headers** → proving cross-origin isolation.
- **Offline continuity** → proving the app still works offline.

### On Windows (PowerShell)

**Step 1 — Verify Headers**

```powershell
pwsh -NoLogo -File scripts/ecrr/verify-headers.ps1 -Url http://localhost:3003 -WriteLog
```

- **Why:** This confirms the HTTP headers *Cross-Origin-Opener-Policy (COOP)* and *Cross-Origin-Embedder-Policy (COEP)* are set. It saves a short log snapshot.
- **Expect:** A file appears at:

```
artifacts/ecrr-01-verification.log
```

  Inside, you should see lines mentioning **COOP** and **COEP**.

**Step 2 — Collect Evidence Bundle**

```powershell
pwsh -NoLogo -File scripts/ecrr/collect-evidence.ps1 -BaseUrl http://localhost:3003
```

- **Why:** This runs automated Playwright tests and assembles a full bundle of evidence.
- **Expect:** Several new files appear (see “What you should see” below).

---

### On POSIX (Linux/Mac)

**Step 1 — Run the Collection Script**

```bash
scripts/ecrr/collect-evidence.sh
```

- **Why:** Same purpose as Windows flow. Attempts to capture headers if PowerShell is available; otherwise focuses on Playwright tests.
- **Expect:** The same evidence bundle files are created.

---

### What You Should See (Files)

- `artifacts/ecrr-01-verification.log` → Contains COOP/COEP lines.
- `artifacts/ecrr-01-playwright-isolation.json` → Should show `"unexpected": 0`.
- `artifacts/ecrr-01-playwright-offline.json` → Should show `"unexpected": 0`.
- `ECRR-01-SMOKE-TEST-RESULTS.md` → A readable summary of results.
- `docs/ECRR_REPORTS/2025-09-22-terminal-session-ecrr-01.md` → A session note file with test details.

---

## Acceptance (Thumb-check)

- **Logs drilldown:**
  - ERROR/WARN filter visible.
  - Grouped counts by service name.
  - At least one log expanded with attributes shown.
  - “View related trace” works if a trace exists.

- **Evidence bundle:**
  - Both JSON files report `unexpected = 0`.
  - Header log contains both COOP and COEP.
  - Both markdown files exist and look clean.

---

## When to Alert

- If a **single service** produces more than **5 ERROR logs in 5 minutes**, consider alerting.
- Keep alerts **gentle**: don’t wake the household for one scratch. Wait until a pattern repeats.

---

## Troubleshooting

- **No logs?** Check your time window and clear keywords.
- **No header lines?** Re-run `verify-headers.ps1` with the correct URL.
- **Unexpected > 0?** Re-run once — tests can be flaky. If it persists, capture the JSON files and share.

---

## That’s It

This process should feel **predictable, calm, and light.**
If anything feels noisy or confusing, simplify — Comfort Cat prefers a smooth nap over tangled yarn.

---

🐾
