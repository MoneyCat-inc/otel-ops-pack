# Security Alert Operations Runbook

Mechanics for managing GitHub code-scanning alerts on this repo: dismissing alerts
with reasons, and purging analyses left behind by retired scanner configurations.
Distilled from the 2026-08-27 security burn-down (PRs #630–#639), which took the
security tab from ~3,470 open alerts to 16 note-level findings with the
`security-extended` CodeQL suite enabled.

All commands use `gh api` against `repos/MoneyCat-inc/otel-ops-pack`.

---

## 1. Diagnosing zombie alerts

An alert is a **zombie** when it is held open by a scanner configuration that no
longer runs. It will never auto-close, no matter what you fix. Symptoms:

- The alert stays open although the flagged code was fixed and the live scanner
  has re-analyzed main.
- `most_recent_instance.commit_sha` points at an old commit and never advances.

**Diagnostic tell** — list the alert's instances and compare per-config state:

```bash
gh api "repos/MoneyCat-inc/otel-ops-pack/code-scanning/alerts/<N>/instances?per_page=20" \
  --jq '.[] | "\(.ref) \(.analysis_key) state=\(.state)"' | sort -u
```

If the live config's main-ref instance says `state=fixed` while a retired
`analysis_key` (a workflow that no longer runs, or a deleted one) says
`state=open`, the alert is a zombie. Fixing more code will not help; the retired
config's analyses must be deleted (§3) — or the alert dismissed (§2) if there
are only a handful.

Live configs as of 2026-08-27: `codeql.yml` (CodeQL, security-extended),
`trivy-security-scan.yml` (Trivy), `powershell.yml` (PSScriptAnalyzer),
`osv-scanner.yml`, `gitleaks.yml`.

## 2. Dismissing alerts with reasons

Dismissal is **reversible** (alerts can be reopened) and leaves an audit trail —
prefer it over deletion when the count is small.

```bash
gh api -X PATCH "repos/MoneyCat-inc/otel-ops-pack/code-scanning/alerts/<N>" \
  -f state=dismissed \
  -f dismissed_reason="won't fix" \
  -f dismissed_comment="<why, max 280 chars>"
```

- `dismissed_reason` must be one of: `false positive`, `won't fix`, `used in tests`.
- **`dismissed_comment` is capped at 280 characters** — the API 422s above that.
- Always write a comment. House precedents:
  - *By-design data flow* (telemetry file→http, ingest http→file): `won't fix`,
    name the feature and where its inputs are hardened.
  - *Console output in CI scripts* (log-injection): `won't fix`, note there is
    no structured sink or downstream parser.
  - *Validated-before-use* (e.g. enum-checked value CodeQL can't model):
    `false positive`, cite the validating line.
  - *Sanitizer CodeQL doesn't model* (e.g. same-origin URL check): `won't fix`,
    cite the fixing PR and describe the residual behavior.
  - *Math.random in test/load scripts*: `used in tests`.

## 3. Purging analyses of retired scanner configs

Deleting a retired config's analyses removes the alerts only it reported.
**This is irreversible** — get explicit operator approval first, and never touch
a live config's analyses.

### 3.1 Inventory the defunct categories

```bash
gh api "repos/MoneyCat-inc/otel-ops-pack/code-scanning/analyses?tool_name=<Tool>&per_page=100" \
  --paginate --jq '.[] | "\(.analysis_key)\t\(.ref)"' | sort | uniq -c | sort -rn
```

Any `analysis_key` whose workflow is deleted or retired (dispatch-only) is a
candidate. Cross-check the workflow file's header for the `RETIRED` marker.

### 3.2 Deletion mechanics (hard-won facts)

- Endpoint: `DELETE /repos/{o}/{r}/code-scanning/analyses/{id}?confirm_delete=true`.
- **Deletion order is per-(ref, category) set, newest-first — across
  `analysis_key`s.** Categories are strings like `/language:javascript`; two
  different workflows reporting the same category on the same ref share one
  set and block each other's older analyses.
- **Do not trust the listing's `deletable` flag** — it lags reality by minutes.
  Filtering on it converges at ~1 deletion per listing pass. Instead:
  precompute the order (sort each set's ids by `created_at` descending) and
  issue DELETEs sequentially; they succeed even while the flag still says false.
- `next_analysis_url` in the DELETE response is usually `null` here — don't
  build a chain-walker around it.
- The already-deleted error message is **"No analysis found"**, not "not found"
  — match both in retry logic.
- "Analysis specified is not deletable" (400) means a newer set member still
  exists — skip and retry on a later pass, or fix your ordering.
- **Undeletable residue is expected**: a retired config's analyses whose
  (ref, category) set is shared with a live config are pinned behind the live
  config's newer history. They hold no alerts once the rest is purged. Leave
  them; deleting them would require deleting live history.

### 3.3 Rate limits

- The REST core budget (5,000/hr) is **shared across everything using the
  BossCat OEM Bot token** — the whole automation fleet. Keep a reserve
  (~800 calls) and check `gh api rate_limit` periodically.
- A **secondary write throttle** engages after roughly 500 rapid deletes;
  lockouts last tens of minutes and outlive the hourly reset. Pace deletes
  (~1/s), and when locked out, probe with a *single* DELETE every few minutes
  rather than hammering. `/rate_limit` itself is free to poll but does not
  reflect the secondary throttle.

### 3.4 Reference implementation

The scripts used for the 2026-08-27 purge (chunked, resumable, quota-guarded,
set-ordered) are described in the burn-down PRs; the approach in short:

1. List all defunct-category analyses; group by `(ref, category)`; sort each
   group by `created_at` descending into one ordered file.
2. Delete sequentially through the file. On "not deletable": short retries,
   then skip the rest of that group (it is pinned by a live config).
3. Time-guard each run and relaunch until the listing comes back empty.

## 4. Related repo conventions

- **Branch cascade**: this repo requires up-to-date branches; after each merge,
  update the next queued PR with
  `gh api -X PUT repos/MoneyCat-inc/otel-ops-pack/pulls/<N>/update-branch`.
- **Lane purity**: the `kiro_lane_purity` pre-commit hook rejects commits mixing
  docs-lane (`docs/**`) with code-lane files — split fixes into separate PRs.
- **Coverage caveat**: alert cleanliness is only meaningful relative to what the
  scanners run. `codeql.yml` runs `queries: security-extended` (enabled in
  #636); removing that would silently untrack a whole class of findings, not
  fix them.
