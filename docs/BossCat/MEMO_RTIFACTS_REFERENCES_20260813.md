# Decision memo — the `rtifacts/` references: fix, retire, or scope

**Date:** 2026-08-13

**Drafted by:** Claude (chat/review seat) for operator decision

**Scope:** Roadmap 2026 H2, Phase 2 — truth in steering documents

**Recommendation:** **Scope the criterion, fix the 17 live surfaces, leave the 314 historical
reports alone.**

---

## First: the exit criterion cannot be satisfied as written

Phase 2 says it closes when *"grep for `rtifacts/` returns nothing."* It never will. `rtifacts/` is
a **substring of `artifacts/`**, so a plain grep matches essentially every legitimate path in the
repo — 1,645 files. The criterion is not strict, it is unmeasurable.

This is the fourth unsatisfiable check found this month, after the compliance gate that could not
fail, the drift guard that could not pass, and the permanently red `Validate JSON Contracts`. It
belongs on that list and should be restated before anyone tries to close the phase against it.

**Proposed replacement:**

```bash
git grep -nE '(^|[^aA])rtifacts/' -- ':!CHAR/ECRR/**'
```

Both the case-insensitive exclusion and the path scope matter. Without `[^aA]` the pattern still
matches `Artifacts/` inside identifiers like `$reportsWithArtifacts/`; without the exclusion it
re-imports the historical corpus this memo argues to leave alone.

## The real numbers

| Measure | Count |
|---|---|
| Naive `rtifacts/` grep (meaningless) | 1,645 files |
| Genuine broken references | **763 occurrences across 331 files** |
| …under `CHAR/ECRR` (historical evidence) | **314 files** |
| …under `CHAR/EVID` | 13 files |
| …live steering surfaces (`docs/BossCat`, `docs/GATE_STATUS_DASHBOARD.md`, `CHAR/DOCS`) | **4 files** |

The roadmap's "~300 normalization addenda" estimate was accurate. Only the test was broken.

## The three options, costed

**Fix everything.** A repo-wide `s|rtifacts/|artifacts/|` across 331 files. Mechanically trivial and
the criterion goes green. It also edits **314 dated evidence reports after the fact**, to correct a
typo whose presence changes none of their conclusions. Afterwards no reader can tell what a report
said when it was filed. This project's evidence is worth something precisely because it is
contemporaneous; spending that to fix a cosmetic link is a bad trade, and it is close to the
report-normalization campaign the roadmap lists under explicit non-goals.

**Retire everything.** Archive the 2025 shell reports wholesale and bless the lean 2026 format. This
is the roadmap's own alternative and it protects the record, but it is heavier than the problem
warrants: the broken path is not why those reports would be archived, and bundling the two decisions
means the archive question gets answered by a typo rather than on its merits.

**Scope it — recommended.** Fix the handful of references on surfaces that are *read for current
truth*, and leave the historical corpus untouched. A broken path in
`docs/GATE_STATUS_DASHBOARD.md` actively misleads someone today; the identical string inside
`CHAR/ECRR/ECRR_REPORTS/2025-09-22-monitoring-automation.md` is a fact about what was written in
September 2025. Those are different objects and deserve different treatment.

That is **4 live files** to correct against 314 to leave alone, and it makes the exit criterion both
meetable and meaningful.

## Recommendation

Restate the criterion as above, fix the live surfaces, and record in the phase closeout that the
historical `rtifacts/` strings are **known and deliberately preserved** — so a future reader finds an
explanation rather than assuming the cleanup was never finished.

Keep the archive question for the 2025 shell reports as its own decision, judged on whether those
reports still earn their place, not on a typo.

## If the operator prefers fix-everything

It should be one mechanical commit, no reflow or reformatting alongside it, with the diff reviewable
as a pure string substitution — and the phase closeout should state plainly that historical evidence
was edited after filing, so the corpus carries its own caveat.
