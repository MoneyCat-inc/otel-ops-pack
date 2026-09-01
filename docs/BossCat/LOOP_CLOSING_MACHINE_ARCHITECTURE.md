# Loop-Closing Machine: Architecture Vision

**Date:** 2025-10-10  
**Authority:** Comfort Cat Strategic Direction  
**Status:** 📌 **PARTIALLY REALIZED, PARTIALLY RETIRED** — see Status Addendum (2026-09-01) at the end of this document

---

## 🎯 The Insight: We've Been Cleaning The Floor, Not Fixing The Leak

### What We Just Did (Tactical)

- Cleaned 3,000 workflow runs manually
- Hit GitHub CLI pagination wall (1k limit)
- Found tool limitations through investigation
- Proposed overnight batch cleanup

### What We Should Build (Strategic)

**A loop-closing machine that:**

1. **Prevents** the clutter from forming (demand shaping)
2. **Accelerates** what must run (supply expansion)
3. **Learns** from failures to auto-suggest fixes
4. **Closes loops** at 4 different timescales

---

## 🔄 The Four Loop Sizes

### Loop 1: Run Loop (seconds–minutes)

**Goal:** Explain a single red/slow run and suggest the next click.

**Close by:**

- Error signature extraction
- Tiny fix hint
- Auto-rerun if flaky

**Current State:** ❌ We dump raw logs  
**Target State:** ✅ "Cache miss on line 47, rerun or check deps.lock"

---

### Loop 2: PR Loop (minutes–hours)

**Goal:** Show author only **net-new** problems.

**Close by:**

- Collapse repeats (same signature)
- Cancel superseded runs (`concurrency` group)
- Change-aware checks (only run affected)

**Current State:** ❌ Every push triggers full suite, logs stack up  
**Target State:** ✅ One card: "3 runs with same error, auto-retrying"

**Immediate Win:**

```yaml
# Add to ALL PR workflows
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

[GitHub Docs: Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)

---

### Loop 3: Workflow-Family Loop (days–weeks)

**Goal:** Reduce recurring failure types, cut median runtime.

**Close by:**

- Track top error signatures
- Identify slowest steps
- Measure cache hit rate
- File epics per signature with ownership

**Current State:** ❌ We see failures but don't track patterns  
**Target State:** ✅ "Signature #42 (pytest auth timeout) seen 47× this week, assigned to @auth-team"

---

### Loop 4: Org Loop (weeks–quarters)

**Goal:** Shape the volume - fewer wasteful triggers, better strategy.

**Close by:**

- Concurrency policies org-wide
- Retention policies (prevent 10k run pileup)
- Path filters (docs ≠ full CI)
- Capacity planning

**Current State:** ❌ Retention = forever, every change = full suite  
**Target State:** ✅ 14-day retention, smart triggers, managed queue

**Immediate Win:**

```yaml
# Set org-wide retention
Settings → Actions → Artifact and log retention: 14 days
```

[GitHub Docs: Retention Policy](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization)

---

## 🏗️ The Loop-Closing Machine Architecture

### Ingest → Normalize → Summarize → Classify → Act → Learn

```text
┌─────────────┐
│   GitHub    │
│   Actions   │
└──────┬──────┘
       │ webhook: workflow_run.completed
       ▼
┌─────────────────────────────────────────┐
│          INGEST WORKER                  │
│  • Fetch run metadata, jobs, logs       │
│  • Time-sliced for historical (1k cap)  │
│  • Redact secrets immediately           │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│         NORMALIZER                       │
│  • Extract step durations, exit codes   │
│  • Strip paths, SHAs, line numbers      │
│  • Hash → sig_id (error signature)      │
│  • Tag component (build/test/deps)      │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│        SUMMARIZER                        │
│  • 8-line synopsis (failures only)      │
│  • Write to GitHub Job Summary          │
│  • Link to 3 prior runs with same sig   │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│        CLASSIFIER                        │
│  • Flake? (same commit passes in 60m)   │
│  • Regression? (new sig in 7d)          │
│  • Known? (seen before, has playbook)   │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│           ACT (Close Loops)              │
│  • PR comment bot (one card)            │
│  • Auto-rerun (flakes, once)            │
│  • Open tracking issue (new signatures) │
│  • Hourly digest to chat                │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│          LEARN (Registry)                │
│  • signatures table (counters, owners)  │
│  • Track fixes (what resolved sig_id)   │
│  • Auto-suggest on next occurrence      │
└─────────────────────────────────────────┘
```

---

## 📁 ECRR as Filed Artifact (Before Reading)

### Folder Structure

```text
/ecrr/org=MoneyCat-inc/repo=otel-ops-pack/dt=2025/10/10/run=18397294115/
├── meta.json              # run, jobs, steps, timings, actor
├── summary.md             # 8-line human synopsis
├── signatures.json        # [{sig_id, step, tool, first_seen, count_7d}]
└── jobs/
    └── build-job-123/
        ├── step_1.log           # raw logs (redacted)
        ├── step_1.events.jsonl  # structured events
        ├── step_2.log
        └── step_2.events.jsonl
```

### Stable IDs

```python
global_run_id = f"{org}/{repo}#{run_id}.{attempt}"
sig_id = hashlib.sha256(
    normalize(error_text) + step_name + workflow_name
).hexdigest()[:16]
```

### Structured Event (JSONL)

```json
{"ts":"2025-10-10T10:12:38Z","lvl":"error","tool":"pytest","step":"test","test":"tests/api/test_user.py::test_login","msg":"AssertionError: 401 != 200"}
```

**Why file before reading?**

- Bulk operations (aggregate, GC, train)
- Don't re-parse every time
- Query with tools (jq, duckdb, pandas)
- Archive-friendly (Parquet for long-term)

---

## 🚫 Demand Shaping: Fewer, Smarter Runs

### 1. Cancel Superseded Work

**Problem:** 5 pushes to PR = 5 full CI runs, but only last matters

**Solution:**

```yaml
# Top of EVERY PR workflow
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

**Impact:** Only latest run alive, queue pressure ↓ 70-80%

[GitHub Docs: Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)

---

### 2. Path Filters & Lanes

**Problem:** Docs change triggers 45-minute test suite

**Solution:**

```yaml
on:
  pull_request:
    paths:
      - 'src/**'        # Only run tests if code changed
      - 'tests/**'
      - '!docs/**'      # Skip if only docs
```

**Lanes:**

- **Smoke lane:** Docs/config changes (5 min)
- **Fast lane:** Unit tests + build (15 min)
- **Full lane:** E2E, integration (45 min, nightly only)

---

### 3. Retention Policy

**Problem:** 10,149 runs accumulated because retention = ∞

**Solution:**

```yaml
# Org-wide: Settings → Actions → Retention
Default: 14 days (was 90)

# Per-workflow artifacts
- uses: actions/upload-artifact@v4
  with:
    retention-days: 7
```

**Impact:** Prevents future 10k pileups

[GitHub Docs: Retention](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization)

---

## ⚡ Supply Expansion: Finish Faster

### 1. Caching Discipline

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

**Check cache hit:**

```yaml
- id: cache-deps
  uses: actions/cache@v4
  # ...

- name: Install (if cache miss)
  if: steps.cache-deps.outputs.cache-hit != 'true'
  run: pip install -r requirements.txt
```

[GitHub Actions: Cache](https://github.com/actions/cache)

---

### 2. Job Summary (Human UX)

**Problem:** Developers dig through 5000-line logs

**Solution:**

```yaml
- name: Add failure summary
  if: failure()
  run: |
    {
      echo '### 🔴 Build Failed';
      echo '';
      echo '**Step:** Compile';
      echo '**Signature:** cache-miss-cold-compile-47ac2f';
      echo '**Hypothesis:** Dependencies changed, cache miss';
      echo '**Next:** Check requirements.txt or rerun';
      echo '';
      echo '[Full logs](#) • [Similar failures](#)';
    } >> "$GITHUB_STEP_SUMMARY"
```

**Impact:** Instant diagnosis, no log hunting

[GitHub Blog: Job Summaries](https://github.blog/news-insights/product-news/supercharging-github-actions-with-job-summaries/)

---

## 🎯 The 1,000-Run Pagination Wall (We Hit It Today)

### The Problem

**GitHub API caps:**

- Search API: ~1,000 results max
- List endpoints: Page 10+ returns duplicates
- CLI `gh run list --limit 1000`: Hard stop

**What we discovered today:** ✅ Validated by Comfort Cat

[GitHub Docs: Workflow Runs API](https://docs.github.com/en/rest/actions/workflow-runs)

---

### The Solution: Time-Sliced Fetching

```bash
#!/bin/bash
# Fetch all runs by day-slicing (works around 1k cap)

REPO="MoneyCat-inc/otel-ops-pack"
START="2025-10-01T00:00:00Z"
END="2025-10-10T23:59:59Z"

for DAY in $(seq 0 9); do
  DAY_START=$(date -u -d "$START +$DAY day" +"%Y-%m-%dT00:00:00Z")
  DAY_END=$(date -u -d "$START +$((DAY+1)) day" +"%Y-%m-%dT00:00:00Z")
  
  echo "Fetching runs for $DAY_START..."
  
  gh api "repos/$REPO/actions/runs" \
    -f per_page=100 \
    -f status=completed \
    -f "created=>=$DAY_START" \
    -f "created=<$DAY_END" \
    --paginate \
    --jq '.workflow_runs[].id' >> run_ids.txt
done

echo "Total runs: $(wc -l < run_ids.txt)"
```

**Why it works:**

- Each day has <1,000 runs
- Pagination within day works fine
- Aggregate across days = full dataset

---

## 📊 Metrics That Prove Loops Are Closing

### Flow & Quality

| Metric | Current | Target | Measure |
|--------|---------|--------|---------|
| **LTRR** (Lead Time to Red Reason) | Unknown | <2 min | Run start → PR sees summary |
| **Flake Rate** | Unknown | <10% | Flaky failures / total failures |
| **New Signatures/Week** | Unknown | Trending ↓ | Unique sig_ids per week |
| **MTTR (Run)** | Unknown | <30 min | First red → green on same PR |
| **Cache Hit %** | Unknown | >80% | Cache hits / total fetches |

### Volume & Cost

| Metric | Current | Target | Measure |
|--------|---------|--------|---------|
| **Runs per PR** | Unknown | <3 | Total runs / PR |
| **Cancelled/Started Ratio** | 0% | 70% | Cancelled by concurrency |
| **Queue Wait p95** | Unknown | <2 min | Time in queue |
| **API Calls per Run** | Unknown | Minimized | Rate limit usage |

---

## 🚀 7-Day Build Plan (Immediately Actionable)

### Day 1-2: Wire the Spine

**Goal:** Ingest → File

**Tasks:**

```python
# webhook_receiver.py
@app.post("/webhook/workflow_run")
def handle_workflow_run(payload):
    run_id = payload["workflow_run"]["id"]
    
    # Fetch full data
    meta = gh_api(f"/repos/{repo}/actions/runs/{run_id}")
    jobs = gh_api(f"/repos/{repo}/actions/runs/{run_id}/jobs")
    
    # File structure
    run_dir = f"/ecrr/org={org}/repo={repo}/dt={date}/run={run_id}/"
    write_json(f"{run_dir}/meta.json", redact(meta))
    
    for job in jobs["jobs"]:
        logs = gh_api(f"/repos/{repo}/actions/jobs/{job['id']}/logs")
        write_log(f"{run_dir}/jobs/{job['id']}/raw.log", redact(logs))
```

**Deliverable:** Webhook → Filed ECRR structure

---

### Day 3: Normalizer

**Goal:** Logs → Structured Events

**Tasks:**

```python
# normalizer.py
def normalize_logs(log_text):
    events = []
    for line in log_text.split("\n"):
        if is_error(line):
            event = {
                "ts": extract_timestamp(line),
                "lvl": "error",
                "tool": detect_tool(line),  # pytest, npm, cargo, etc.
                "msg": normalize_error(line)  # strip paths, SHAs
            }
            events.append(event)
    
    return events

def generate_signature(events, step_name, workflow):
    error_text = "\n".join(e["msg"] for e in events if e["lvl"] == "error")
    normalized = normalize(error_text)
    sig_id = hashlib.sha256(
        (normalized + step_name + workflow).encode()
    ).hexdigest()[:16]
    return sig_id
```

**Deliverable:** `events.jsonl` + `sig_id` per run

---

### Day 4: Summarizer

**Goal:** JSONL → 8-line synopsis

**Tasks:**

```python
# summarizer.py
def generate_summary(run_dir):
    meta = load_json(f"{run_dir}/meta.json")
    events = load_jsonl(f"{run_dir}/jobs/*/events.jsonl")
    sig = load_json(f"{run_dir}/signatures.json")[0]
    
    summary = f"""
### 🔴 Run Failed

**Workflow:** {meta['workflow_name']}
**Step:** {sig['step']}
**Signature:** `{sig['sig_id']}`
**Error:** {events[0]['msg'][:100]}...

**Hypothesis:** {classify_failure(sig['sig_id'])}
**Next:** [Rerun](link) • [View similar](#)
"""
    
    # Write to GitHub Job Summary
    write_to_github_summary(summary)
    write_file(f"{run_dir}/summary.md", summary)
```

**Deliverable:** Human-readable summaries in UI + stored

---

### Day 5: Act (Close Loops)

**Goal:** Summaries → Actions

**Tasks:**

```python
# actor.py
def act_on_failure(run_id, sig_id):
    sig_info = signature_registry.get(sig_id)
    
    if sig_info and sig_info["is_flake"]:
        # Auto-rerun once
        gh_api(f"/repos/{repo}/actions/runs/{run_id}/rerun")
        comment_on_pr(pr_number, "♻️ Auto-retrying known flake")
    
    elif sig_info and sig_info["has_playbook"]:
        # Link to fix
        comment_on_pr(pr_number, f"See: {sig_info['playbook_url']}")
    
    else:
        # New signature - open tracking issue
        issue = create_issue(
            title=f"[CI] New failure signature: {sig_id[:8]}",
            body=f"Seen in run #{run_id}\nSignature: {sig_id}"
        )
        comment_on_pr(pr_number, f"Tracking: {issue.url}")
```

**Deliverable:** Auto-rerun, PR comments, tracking issues

---

### Day 6: Policy (Demand Shaping)

**Goal:** Prevent clutter formation

**Tasks:**

1. Add `concurrency` to all PR workflows
2. Set org retention to 14 days
3. Add path filters to slow workflows
4. Document policy in repo

**Deliverable:** 70% fewer wasted runs

---

### Day 7: Dashboard

**Goal:** Visibility into loop health

**Metrics:**

- Failure rate (7d trend)
- New signatures this week
- Flake rate
- Cache hit %
- p95 step duration
- Top 10 signatures

**Tech:** Grafana + Prometheus, or SigNoz (already have!)

**Deliverable:** Real-time health dashboard

---

## 🎯 Immediate Wins (Can Do Today)

### 1. Add Concurrency Groups (5 minutes)

```bash
# Add to top of all PR workflows
for workflow in .github/workflows/*.yml; do
  if grep -q "pull_request:" "$workflow"; then
    # Insert concurrency block after 'on:' section
    echo "Adding concurrency to $workflow"
  fi
done
```

**Impact:** 70% queue pressure reduction

---

### 2. Set Retention Policy (2 minutes)

```text
Settings → Actions → Artifact and log retention
Change from 90 → 14 days
```

**Impact:** Prevents future 10k pileups

---

### 3. Add Job Summaries (10 minutes per workflow)

```yaml
- name: Failure summary
  if: failure()
  run: |
    echo '### Build failed - cache miss' >> "$GITHUB_STEP_SUMMARY"
```

**Impact:** Instant failure diagnosis

---

## 🐾 What We Just Learned (Meta-Insight)

### We Were Solving The Wrong Problem

**What we thought:** "We have too many old runs, let's delete them"

**What's actually happening:** 

- Retention = ∞ (demand shaping missing)
- Every push = full suite (no concurrency)
- No loop-closing (failures just... exist)
- No learning (same errors recur)

**The Fix:** Build the machine, not the mop

---

### The Pagination Discovery Was Real

**What we found:** `gh run list` doesn't paginate past 1k

**Comfort Cat confirms:** ✅ Known limitation, use time-slicing

**Our investigation:** Valuable validation of tool limits

**The lesson:** Always verify tool capabilities with duplicate detection

---

## 🎯 What Success Looks Like

### Before (Today)

❌ 10,149 runs accumulated  
❌ Manual cleanup required  
❌ Hit 1k pagination wall  
❌ No pattern detection  
❌ Logs = spelunking  
❌ Flakes rerun manually  
❌ Same errors recur weekly

### After (Loop-Closing Machine)

✅ 14-day retention (auto-cleanup)  
✅ Concurrency = 70% fewer runs  
✅ Time-sliced fetching (no walls)  
✅ Signature tracking (patterns)  
✅ 8-line summaries (instant clarity)  
✅ Auto-rerun flakes (once)  
✅ Playbooks linked (fixes remembered)

---

## 🚀 Decision Point

**Comfort Cat is offering:**

1. **Starter repo layout** (ingest worker, normalizer, templates, queries)
2. **Flake detector** (pattern recognition)
3. **Signature registry** (learning system)

**What we need to decide:**

- Start with immediate wins (concurrency, retention, summaries)?
- Build the full loop-closing machine (7-day plan)?
- Focus on specific component first (which loop size)?

---

## 📚 Reference Links (From Comfort Cat)

### GitHub Docs

- [Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)
- [Workflow Runs API](https://docs.github.com/en/rest/actions/workflow-runs)
- [Caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)
- [Retention Policy](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization)
- [Rate Limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
- [Job Summaries Blog](https://github.blog/news-insights/product-news/supercharging-github-actions-with-job-summaries/)

### Tools

- [actions/cache](https://github.com/actions/cache)
- [gh CLI pagination discussion](https://github.com/cli/cli/discussions/7010)

---

## 🐾 BossCat Response

**Status:** 🎯 **VISION RECEIVED & UNDERSTOOD**

**Recognition:**

- We were tactical (cleaning), you're strategic (preventing)
- Our pagination investigation **validated** the 1k wall
- Loop-closing at 4 levels is the right abstraction
- ECRR as "filed artifact" = queryable intelligence

**Ready to:**

- [ ] Start with immediate wins (concurrency + retention)
- [ ] Begin 7-day build plan (ingest → act → learn)
- [ ] Accept starter code/templates
- [ ] Build signature registry + flake detector

**Question:** Which component do you want us to pounce on first?

---

**Authority:** BossCat Operations + Comfort Cat Strategic Vision  
**Status:** Architecture documented, awaiting implementation directive  
**Seal:** 🐾 **Ready to build the machine**

---

## 📌 Status Addendum — 2026-09-01 (verified against live repo)

Eleven months on, here is what this vision actually became. Every claim below was
checked live on 2026-09-01, not carried forward from the text above.

### Shipped and live

- **Concurrency groups (Loop 2):** 48 of 62 workflows carry a `concurrency` block.
  Of the 14 without one, 11 are manual-dispatch-only utilities, one is push-only,
  and one (`required-check-shims`) is an instant shim — coverage is effectively
  complete where it matters.
- **Run-archiver conveyor (Loop 4):** [run-archiver.yml](../../.github/workflows/run-archiver.yml)
  runs every 30 minutes, analyzes runs, and publishes evidence to
  `MoneyCat-inc/otel-ops-evidence`. Green as of today. The PowerShell backfill
  toolkit lives in `BRAV/SCPT/run-archiver/` and includes the time-sliced
  fetching this doc proposed (the 1k pagination wall is solved).
- **Retention:** the run horizon on the repo is ~90 days (only 14 runs remain
  older than 2026-06-01). Better than the ∞ of 2025-10, but the 14-day target
  was never adopted.

### Built but never went live

- The **Ingest → Normalize → Summarize → Classify → Act spine** exists as
  scripts (`scripts/ingest-worker.ts`, `normalize-events.ts`,
  `summarize-run.ts`, `classify-run.ts`, `auto-rerun-guard.ps1`) but is wired
  into **no live workflow**. Loops 1 and 3 (run explanation, signature
  trending) never closed.
- The **signature registry** (`ALFA/APPS/signature-registry.json`) still
  contains only its single 2025-10-10 seed entry. No learning ever occurred.
- The rerun policy now lives at `DELT/CONF/policy/ecrr-policy.json`
  (PHASE3_QUICKSTART.md's `config/policy/` path is stale).

### Retired (Phase 0 workflow audit, 2026-08-03 — see [ROADMAP_2026H2.md](ROADMAP_2026H2.md))

- `nightly-ecrr-aggregates.yml` — "daily rollup with no consumer."
- `run-rotation.yml` — parallel conveyor; one archiver suffices.

### The metric reality (2026-09-01)

- **19,814 runs on the repo** — nominally worse than the 10,149 this doc called
  a crisis, but the composition changed entirely: the old backlog is gone;
  the count is fresh demand. **13,287 runs were created since 2026-08-01**
  (~430/day).
- Demand is dominated by ~9 workflows (PSScriptAnalyzer, Gitleaks, OSV-Scanner,
  Trivy, CodeQL, Governance Suite, Gate Verification, Tetragram Guardrails,
  Gate & Site Evidence) firing on **every PR push and every push to main**.
  Dependabot batches multiply this: one 19-PR batch × update-branch cascades
  × 9 workflows per push. 8 of those 9 workflows have **zero path filters** —
  a docs-only change still runs the full security suite.

### Standing verdict

- This doc's core insight ("fix the leak, not the floor") is **half done**: the
  floor now cleans itself (archiver + retention), and superseded runs get
  cancelled — but the leak itself (per-push full-suite triggers, no
  change-aware lanes) was never plugged.
- [ROADMAP_2026H2.md](ROADMAP_2026H2.md)'s guiding model (subtract machinery;
  no new gate frameworks or compliance engines) **forecloses building the rest
  of the machine** — the webhook ingest service, the learning registry, the PR
  comment bot stay unbuilt unless the Phase 4 purpose decision revives them.
  The unwired scripts and seed registry remain in place as inventory.
- The one open, roadmap-compatible lever from this doc is **demand shaping**:
  path filters / lanes on the 8 unfiltered per-push workflows would cut the
  ~430/day materially with no new machinery. That is the natural next ECRR if
  run volume is ever prioritized.

