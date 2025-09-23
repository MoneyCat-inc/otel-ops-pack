AI PR Execution Plan — Phase A
================================

Team & RACI
-----------

- Owner: Delivery Lead — Marcus Rodriguez (Overall coordination, unblockers)
- Data Engineering (P1) — Alex Chen (Ingestion, warehouse jobs, classifier plumbing, KPI refresh)
- Data Science — Sarah Kim (Metrics definitions, sampling, validation, analysis)
- Platform/Infra — Jennifer Liu (CI, secrets redaction, runners, repo wiring)
- Observability — David Park (Dashboards, alerts, evidence artifacts)

RACI per Workstream
-------------------

- BigQuery exports: R(Alex), A(Marcus), C(Jennifer), I(Sarah, David)
- Classifier baseline: R(Sarah), A(Marcus), C(Alex), I(Jennifer, David)
- CI wiring (WSL/Windows): R(Jennifer), A(Marcus), C(Alex), I(Sarah, David)
- Dashboards + evidence: R(David), A(Marcus), C(Sarah), I(Alex, Jennifer)

ASCII Success Gates (must meet or exceed)
-----------------------------------------

- Classifier precision
  - Agentic >= 0.90
  - Automation >= 0.80
- Coverage >= 85% of sampled PRs classified
- Data freshness: daily exports by 09:30 local, retries until success
- Evidence: artifacts contain CSVs, summary, and stamped kickoff report

Cadence
-------

- Daily: export + refresh KPIs; 10-min review standup (async OK)
- Weekly: threshold review and deltas; tune sampling/filters

Phase A Checklist
-----------------

- [x] Export scripts present (PowerShell + Bash) with mock fallback
- [x] SQL templates present for baseline queries
- [ ] Kickoff run executed, artifacts under `artifacts/bq_exports/`
- [ ] PHASE_A_KICKOFF_REPORT.md committed with ECRR evidence

Verification
------------

- Run: `pwsh -File scripts/bq_export.ps1 -GcpProject demo-project -StartDate 2024-01-01 -EndDate 2024-01-31`
- Expect: CSVs + `artifacts/bq_exports/export_summary.txt` with row counts

# AI PR Landscape Execution Plan

## Objective Snapshot
- Build end-to-end visibility into AI involvement in pull requests across repos.
- Deliver actionable insights and policy guardrails that preserve velocity while improving signal on agentic activity.
- Pilot changes in a controlled subset of repos and prove we can scale with low maintainer overhead.

## Team & RACI
- **Data Engineering (P1)** - **Alex Chen** - Own data ingestion, warehouse jobs, classifier implementation, KPI dataset refresh.
- **Data Science (P2)** - **Sarah Kim** - Own validation study, KPI analysis, dashboard build, findings memo.
- **Platform Engineering (P3)** - **Marcus Rodriguez** - Own GitHub/Governance automation, policy pack packaging, pilot repo onboarding.
- **Eng Manager + Maintainers (Support)** - **Jennifer Liu** - Approve policy adoption, provide pilot feedback, track merge quality.
- **Program Lead** - **David Park** - Weekly checkpoint, risk goalie, unblock cross-team dependencies.

## Milestone Timeline (4 weeks)
- **Week 0 (Today)**: Stand up baseline queries, unpack starter kit, align on validation label book.
- **Week 1**: Finish classifier v0.1, produce first KPI export, drop policy pack drafts into pilot repos for review.
- **Week 2**: Complete validation labeling sprint, publish precision/recall report, turn on labeler workflow in pilots.
- **Week 3**: Dashboard first pass + memo draft, enable merge queue + dependabot grouping, start maintainer interviews.
- **Week 4**: Pilot readout (before/after metrics + qualitative feedback), finalize dashboard + policy revisions.

## Phase A — Measurement (Data Eng lead)
### Daily Tasks
1. **Day 0-1** — Configure GH Archive BigQuery jobs using `/sql/pr_opened_baseline.sql` and `/sql/pr_closed_merge_join.sql`.
   - _Command hint_: `bash scripts/bq_export.sh <gcp-project> ./artifacts/bq_exports`
   - _Acceptance_: Baseline CSVs land in artifacts with <5 min runtime.
2. **Day 1** — Run GraphQL paginator (`node graphql/paginate_prs.js org repo`) for top 10 repos by PR volume.
   - Store JSON in `/analysis/raw/graphql/<repo>.json`.
3. **Day 1-2** — Execute `python notebooks/classifier_template.py <json> --out <csv>` for each repo.
   - Publish aggregated CSV (`artifacts/classified_prs.csv`).
4. **Day 2-3** — Wire KPI aggregation `python scripts/compute_kpis.py ... --out artifacts/kpis.csv`.
   - Schedule nightly refresh (GitHub Actions or Airflow) with validation hook.

### Success Gates
- Classifier precision Agentic >=0.90, Automation >=0.80 using validation sample.
- Validation plan + label book committed under `docs/validation_plan.md` and `scripts/label_book.md` updates.

## Phase B — Insight (Data Science lead)
### Tasks
1. Build notebook to ingest `artifacts/kpis.csv`, generate charts for share%, merge rate, TTM, CI pass, revert proxy.
2. Create dashboard skeleton (e.g., Streamlit or Observable) reusing dataset to avoid one-off calculations.
3. Draft 2-page memo summarizing deltas by language, repo quartile, domain; include top risks.

### Acceptance
- Notebook produces reproducible figures stored in `docs/landscape_deck_outline.md` references.
- Dashboard includes trend lines and cohort tables with filters for repo cohort + language.
- Memo approved by Eng Manager.

## Phase C — Governance & Tooling (Platform Eng lead)
### Tasks
1. Fork `policy-pack/` templates into pilot repos via PR with maintainers tagged.
2. Deploy `.github/workflows/label-ai-and-deps.yml` using reusable workflow or direct copy; confirm permissions `pull-requests: write` only.
3. Update branch protections / rulesets per `policy-pack/rulesets-example.json`; enable Merge Queue for dependency branch.
4. Apply `dependabot.yml` grouping and adjust schedule with maintainers.

### Acceptance
- Policy pack merged in >=3 pilot repos with maintainer approval comments.
- Labeler correctly tags >=90% of `copilot/*` and dependency PRs (spot check 50).
- Merge queue active; maintainers confirm dependency noise decreased.

## Phase D — Pilot & Iterate (Program lead + Maintainers)
### Tasks
1. Capture 30-day baseline metrics before policy launch, then 30-day post metrics (automate via KPI dataset filter).
2. Schedule and run maintainer interviews using `docs/interview_guide.md`; log notes in `/docs/pilot_feedback/<repo>.md`.
3. Iterate on policy language and automation thresholds; record deltas in `docs/methodology.md`.

### Acceptance
- No regression in human PR merge rate/TTM.
- >=80% maintainers report no additional burden.
- Final pilot report summarizing quantitative + qualitative findings stored in `docs/pilot_readout.md`.

## Operating Rhythm
- **Daily**: Data Eng posts ingest status, failed job alerts, classifier anomalies.
- **Twice weekly**: Cross-functional standup (15 min) to unblock.
- **Weekly**: Program lead circulates status note (wins, risks, next week focus).

## Next Actions (Today)
1. Data Eng: run `scripts/bq_export.sh` for top repos; push outputs.
2. Data Sci: stub analysis notebook with KPI schema ingest.
3. Platform Eng: open pilot issue threads with policy pack diff preview.
4. Program Lead: set calendar invites for standups + maintainers interviews.

## ECRR Gate
### Examine
- AI PR landscape research completed with baseline measurement approach identified
- Repository structure supports artifacts/, docs/, scripts/ organization
- Cross-functional team roles and responsibilities mapped

### Clean
- Execution plan structured with clear ownership and acceptance criteria
- Timeline broken into 4-week milestone with daily/weekly cadence
- Success gates defined with measurable thresholds

### Report
- Actionable execution plan created at `docs/AI_PR_EXECUTION_PLAN.md`
- Phase-based approach: Measurement → Insight → Governance → Pilot
- RACI matrix established with primary/secondary owners

### Role
- **Cursor Agent: Observability Copilot** — packaged research roadmap into structured execution plan following ECRR methodology

