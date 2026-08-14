# Decision memo — the `rtifacts/` references: fix, retire, or scope

**Date:** 2026-08-13

**Drafted by:** Claude (chat/review seat) for operator decision

**Scope:** Roadmap 2026 H2, Phase 2 — truth in steering documents

**Recommendation:** **Scope the criterion, fix the 2 genuinely-broken live references, leave the
historical reports alone.**

**Status:** the 2 live fixes are done. See the addendum below — the defect is a BEL control
character, not a missing letter, which changes how any wider fix must be written.

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

## Addendum (2026-08-13) — it is not a typo, it is a control character

Found while fixing the live surfaces. The broken strings do not have a *missing* `a`; they have a
**BEL byte (`0x07`) in its place** — the text is literally `**Evidence:** <BEL>rtifacts/...`.

That is `\a` escape-interpretation. A Windows path written as `...\artifacts/` passed through
something that treated `\a` as an escape sequence and emitted BEL. **761 of the 770 genuine
occurrences carry the BEL byte**; only 9 are a plain missing letter.

Two consequences:

1. **These documents contain non-printing control characters**, not merely a wrong path. That is a
   different and slightly worse defect than the roadmap describes.
2. **A naive `s|rtifacts/|artifacts/|` would not fix them.** It would leave the BEL in place and
   produce `<BEL>artifacts/` — still corrupt, and now invisible to the very grep used to verify the
   cleanup. Any fix must match `\x07rtifacts/`, e.g.
   `perl -i -pe 's/\x07rtifacts\//artifacts\//g'`.

This strengthens the recommendation below rather than changing it. A mass edit across 314 historical
reports was already a poor trade; a mass edit that silently leaves 761 control characters behind
while reporting success would be the fifth unsatisfiable check in this list rather than a fix.

## The real numbers

| Measure | Count |
|---|---|
| Naive `rtifacts/` grep (meaningless) | 1,645 files |
| Genuine broken references | **763 occurrences across 331 files** |
| …under `CHAR/ECRR` (historical evidence) | **314 files** |
| …under `CHAR/EVID` | 13 files |
| …live steering surfaces matching the pattern | 4 files |
| …of those, **genuinely broken and worth fixing** | **2** (`BOSSCAT_LOG.md`, `GATE_STATUS_DASHBOARD.md`) |

The gap between those last two rows is the point. Of the 4 "live" matches, the roadmap and this memo
match only because they **discuss** the string — their subject *is* the defect. An automated fix
scoped to "live files" would have corrupted both: rewriting a memo about `rtifacts/` into a memo
about `artifacts/` destroys its meaning. The remaining match is a `CHAR/DOCS` mirror of a 2025
report, which is historical evidence in published form and belongs with the 314.

So the actual repair surface is **2 files, 2 occurrences** — and both corrected paths
(`artifacts/pm/curated/`, `artifacts/icf/convergence-report.json`) exist, so the fix resolves rather
than trading one dead link for another.

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
