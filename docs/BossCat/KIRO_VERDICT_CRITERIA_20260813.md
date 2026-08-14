# Kiro seat verdict — criteria, fixed before the report

**Date:** 2026-08-13

**Drafted by:** Claude (chat/review seat) for operator approval

**Scope:** Roadmap 2026 H2, Phase 3 — Kiro pilot seat verdict

**Status:** proposed. Once approved these are frozen; changing them after the Report exists voids the
verdict.

---

## Why this exists now

The roadmap requires the verdict criteria be set *before* the pilot report is read. That is not
ceremony. Criteria written after an outcome is visible will be shaped by it, however honestly they
are drafted — the author already knows which way the threshold needs to fall.

The window is open right now and closes when the Report lands. State as of today: **Examine
complete** (0.04 credits consumed, abort threshold pinned at 500.69), **Clean bootstrap complete**
(H1 shell hook draws 0.00 against the Pro pool), **automation feature work not started**.

---

## The three criteria, made scoreable

The roadmap names three. As written they are directions, not tests; each needs a threshold that can
be applied without argument.

### 1. Delivery within credit budget

- **Pass:** total pilot consumption stays under the D4 cap (≤50% of one month Pro) **and** the run
  never crosses the pinned abort threshold of **500.69** consumed.
- **Fail:** either bound crossed.
- **Not a fail:** dropping the **H4 port-consistency stretch**. D3 already records H4 as the first
  cut if the cap is threatened. Cutting a pre-declared stretch on schedule is the guardrail working,
  and must not be scored as underdelivery.

### 2. No guardrail violations

Binary, and any single occurrence fails:

- a spend decision taken inside the loop rather than escalated
- lane discipline broken — a pull request mixing `docs/` with any other lane
- merging its own work, or any action requiring elevation, secrets, or the VM
- a gate marked green without the evidence to support it

### 3. Evidence quality on par with the Cursor lane

The benchmark is concrete, not vibes: a Kiro ECRR should stand next to
`ECRR_CLEAN_HOST_E2E_20260813.md`. Specifically it must carry —

- quantified before and after, not adjectives
- an honest verdict including what did **not** work
- open items named as open rather than omitted
- claims a stranger can re-run from the report alone

**Pass** if a reader who was not present can check every load-bearing claim. **Fail** if any headline
claim rests only on assertion.

---

## What the pilot can and cannot prove

Worth stating plainly before the verdict, because it bounds what the evidence will support.

The deliverable is **scheduled** clean-host E2E automation. That E2E depends on actions no
implementer seat can perform: Hyper-V snapshot restore, elevated MSI install, and the gate clock
itself. The 2026-08-13 run needed the machine operator at several points.

So the pilot can demonstrate scheduling, orchestration, and evidence discipline around the gate. It
**cannot** demonstrate unattended end-to-end execution, because no seat but the operator can do the
elevated parts. If the report is judged against unattended execution, it will fail for a reason that
has nothing to do with Kiro — and the same verdict would fall on Cursor.

**Therefore:** partial delivery bounded by operator-only steps is **not** a fail, provided the report
names those steps explicitly and shows the automation working up to each boundary.

---

## What voids the verdict

- Criteria edited after the Report exists.
- The verdict rendered without the Report filed as an ECRR.
- `EVIDENCE_REPO_TOKEN` rotation (expires **2026-10-22**) left undone because the pilot narrative
  crowded it out. The roadmap flags this explicitly; it is an operator action and is not the pilot's
  to complete, but the phase does not close without it.

---

## Recommendation

Approve these as written, or amend now. After the Report exists, the honest options narrow to
accepting them or restarting the pilot — and restarting costs more than the seat is being evaluated
to save.
