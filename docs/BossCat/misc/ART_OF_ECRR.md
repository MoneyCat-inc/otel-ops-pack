# The Art of ECRR

by BossCat --- IONA User Manual

> *"Speed is born from discipline. Discipline is born from rules that
> end cleanly."*

## I. The Four Letters (Tetragram)

**ECRR = Evidence → Contain → Rollback → Report.** When in doubt, **ECRR
and terminate**.

- **Evidence**: Capture facts (logs, state, diffs).
- **Contain**: Stop blast radius (halt writes, freeze lane).
- **Rollback**: Return the repo and job state to last‑known‑good.
- **Report**: Emit a concise incident record to BossCat and exit.

------------------------------------------------------------------------

## II. Roles, Lanes, and Budgets

- **A (Actor)**: the only writer; executes the job.
- **B (Balancer)**: reads, verifies, times, and reports; never writes to
  the repo.
- **BossCat**: command channel / orchestrator.
- **Lane**: short‑lived branch or workspace assigned to a single job.
- **Budgets** (hard): ≤ **2 jobs**, ≤ **10 files**, ≤ **200 LOC**
  touched per job. *Outside the lane or over budget is forbidden.*

**Repo contracts (created by A only):**

- `.agent/JOB.lock` --- mutex for the active job.
- `.agent/EVIDENCE.log` --- JSONL events (append‑only).
- `.agent/PLAN.md` --- one‑page intent & scope (optional but
  recommended).
- Kill‑switch (human ops/infra): `.agent/LOCK` --- if present, all bots
  stop.

------------------------------------------------------------------------

## III. The Prime Rules

### **Rule #1 --- Two Make the Strike**

**Auto‑bots operate in pairs.** **A** implements the task. **B**
monitors A's output and reports to BossCat.

- If **A** cannot locate **B** (heartbeat missing or channel down):
  **ECRR and terminate**.
- If **B** cannot locate **A** (no lock, no logs, or stalled TTL):
  **ECRR and terminate**.

> *"A single sword cuts crooked. A paired guard keeps the edge
> straight."*

### Checklist (B)

1.  Watch `.agent/JOB.lock` heartbeat (mtime tick ≤ 60 s).
2.  Tail `.agent/EVIDENCE.log`; enforce TTL & budgets.
3.  On anomaly: page BossCat, then require ECRR.

------------------------------------------------------------------------

### **Rule #2 --- Single‑Writer, Lane‑Locked**

**A is the only writer; B never writes.**

- Before A edits, acquire mutex: create `.agent/JOB.lock`.\
  If lock already exists, **ECRR and terminate**.
- A touches only files inside the **active lane**.
- Respect hard budgets: **≤ 2 jobs, ≤ 10 files, ≤ 200 LOC**.

> *"One pen, one path, one purpose."*

### Checklist (A) — Rule #2

1.  `if [ -e .agent/LOCK ]; then ECRR; exit 1; fi`
2.  `if [ -e .agent/JOB.lock ]; then ECRR; exit 1; else touch .agent/JOB.lock; fi`
3.  Emit PLAN (`.agent/PLAN.md`), then begin.

------------------------------------------------------------------------

### **Rule #3 --- No‑Human / No‑Conflict Preflight**

- Abort instantly if `.agent/LOCK` exists.
- Abort if the lane is not fast‑forward clean against its base (no
  conflicts, no pending human changes).
- Tools, tokens, and secrets must be present and scoped; missing
  pre‑reqs → **ECRR**.

> *"Enter only quiet rooms. Leave no prints but your own."*

### Checklist (A) — Rule #3

- Verify: clean worktree, sync base, deterministic env, secrets scope
  OK.
- Dry‑run diff ≤ budgets; else **ECRR**.

------------------------------------------------------------------------

### **Rule #4 --- Bounded Retry, or Evidence and Stop**

Wrap every action with crash‑safe retry: **≤ 3 retries** with
exponential backoff; **job TTL** applies.

- On final failure: **rollback**, then **ECRR and terminate**.
- B enforces that repeated flaps do not exceed TTL.

> *"Try thrice; the fourth time is folly."*

------------------------------------------------------------------------

## IV. The Campaign Rules (Operational Doctrine)

### **Rule #5 --- Declare Intent Before You Move**

Before the first write, A commits a plan of attack.

- Create/append `.agent/PLAN.md` (≤ 150 words): *goal, scope, files,
  tests*.
- Log a `plan` event in `.agent/EVIDENCE.log`.

> *"Announce the hill; then take it."*

------------------------------------------------------------------------

### **Rule #6 --- Evidence‑First Telemetry**

Every significant step writes one JSON line to `.agent/EVIDENCE.log`.

**Event schema (one line each):**

    {"t":"ISO8601","who":"A|B","type":"plan|preflight|lock|edit|test|rollback|report|exit",
     "lane":"<branch>", "files_touched":3, "loc_delta":72, "msg":"<short>"}

B never edits this file; B only reads it.

> *"What is not written did not happen."*

------------------------------------------------------------------------

### **Rule #7 --- CI Gate: Changed‑Paths Only**

A must run **smoke tests** that cover only changed paths.

- If tests fail: rollback → **ECRR**.
- Long suites are forbidden; keep latency low.

> *"Test the bridge you cross, not the river you leave behind."*

------------------------------------------------------------------------

### **Rule #8 --- Review Without Writing**

B reviews artifacts and diffs; B posts **out‑of‑repo** status to BossCat
(e.g., API/chat).

- If evidence insufficient (no plan, missing tests, over budget):
  command **ECRR**.
- B may not push commits, resolve conflicts, or edit files.

> *"Eyes open; hands off."*

------------------------------------------------------------------------

### **Rule #9 --- Merge Is Not a Bot's Honor**

Bots do **not** merge to trunk. A opens the lane; integration is
external (BossCat/human ops).

- Rebase lane to base on start and before exit; if conflict
  appears → **ECRR**.

> *"Win the skirmish; leave the treaty to others."*

------------------------------------------------------------------------

### **Rule #10 --- Secrets and Boundaries**

- No new external endpoints, no credential sprawl, no writing outside
  lane paths.
- Large binaries (\> 10 MB) and unvetted dependencies are forbidden.
- Any secret exposure → immediate **Contain → Rollback → Report**.

> *"Guard your keys; narrow your doors."*

------------------------------------------------------------------------

### **Rule #11 --- Artifacts Are Ephemeral**

- Temporary build outputs live under `.agent/tmp/` and are deleted on
  success.
- Persistent artifacts (if any) are checksummed and listed in
  `.agent/PLAN.md`.

> *"Carry light; leave nothing shining."*

------------------------------------------------------------------------

### **Rule #12 --- Latency Comes from Small Cuts**

Prefer **many small edits** over one broad change.

- Keep diffs surgical; pre‑warm caches if available; stream evidence
  early.

> *"Thin blades enter first."*

------------------------------------------------------------------------

### **Rule #13 --- Health, Heartbeat, and TTL**

- A updates the mtime of `.agent/JOB.lock` every ≤ 60 s.
- **Default TTL** per job: 15 minutes (tune per org).
- **Stall** = no heartbeat for 2 intervals → B commands **ECRR**.

> *"A quiet drum is a fallen unit."*

------------------------------------------------------------------------

### **Rule #14 --- Rollback Is a First‑Class Action**

- A maintains a revert plan for every edit (stash/patch/branch).
- On failure: restore last‑known‑good, then log `rollback`.

> *"Retreat cleanly so you may return quickly."*

------------------------------------------------------------------------

### **Rule #15 --- Exit Codes and Colors (NATO‑style)**

- **GREEN (0)**: success; lane rebased; evidence complete.
- **AMBER (10)**: soft stop (budget/TTL reached); no writes pending;
  report.
- **RED (20)**: hard failure; ECRR executed.
- **BLACK (30)**: kill‑switch or policy breach; ECRR executed,
  escalation required.

> *"Name the state; command the response."*

------------------------------------------------------------------------

### **Rule #16 --- Manual Changes Are Sacred**

If a human touches the lane during a bot job (detected via
author/committer):

- Immediate **Contain** (freeze), then **ECRR** and terminate.

> *"Where humans walk, machines kneel."*

------------------------------------------------------------------------

## V. Communications (Brevity Codes)

**Call‑signs:** `A`, `B`, `BossCat`.

**B → BossCat status template (out‑of‑repo):**

    IONA/BALANCER STATUS
    Lane: <branch>  TTL: <mm:ss>  Budget: <files>/<loc>
    State: GREEN|AMBER|RED|BLACK
    Last event: <t> <type> "<msg>"
    Action: continue|hold|ECRR

------------------------------------------------------------------------

## VI. Minimal CI/CD Wire‑Up (Fast, Not Fancy)

1.  **Trigger**: BossCat assigns lane & budgets; pairs A/B.
2.  **Preflight** (A): No kill‑switch, acquire lock, declare plan, log
    `preflight`.
3.  **Execute** (A): Edit within budgets; log `edit`.
4.  **Smoke** (A): Run changed‑paths tests; log `test`.
5.  **Verify** (B): Read evidence & diffs; if OK, advise **GREEN** to
    BossCat.
6.  **Exit** (A): Rebase‑check only; never merge; drop lock; log `exit`.
7.  **On Any Breach**: **ECRR and terminate**.

------------------------------------------------------------------------

## VII. ECRR Pocket Card (do this verbatim)

When any rule demands "ECRR and terminate," A performs:

1.  **Evidence**

2.  Append to `.agent/EVIDENCE.log` the final `report` with reason,
    files, and loc.

3.  Save `git diff --no-color` patch to `.agent/last.diff` (if present).

4.  **Contain**

5.  Stop all writes; preserve `.agent` as the only added files.

6.  Freeze lane (no more retries).

7.  **Rollback**

8.  Revert worktree to base tip; delete `.agent/tmp/`.

9.  Leave `.agent/JOB.lock` in place until Report succeeds.

10. **Report**

11. B posts status **RED/BLACK** to BossCat with a 3‑line summary.

12. A removes `.agent/JOB.lock` and exits with the proper code.

*No improvisation. No partial cleans. End cleanly.*

------------------------------------------------------------------------

## VIII. Glossary (quick)

- **Lane**: short‑lived branch/workspace for a single job.
- **Budget**: limits on jobs, files, and LOC.
- **TTL**: job time‑to‑live.
- **ECRR**: Evidence, Contain, Rollback, Report (the "four letters").
- **Terminate**: clean exit with state restored and status reported.

------------------------------------------------------------------------
