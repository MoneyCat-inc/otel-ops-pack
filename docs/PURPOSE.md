# Purpose — what this stack observes

**Decided:** 2026-08-14 · **Phase 4, Roadmap 2026 H2** · Options draft:
`docs/BossCat/MEMO_PURPOSE_20260814.md`

**The choice: deliberate steady-state.** This repository is **reference infrastructure**. It is not
a product, and it is not currently instrumenting a live workload.

---

## Read this before proposing a gate

Every proposed gate, workflow, script, or scheduled task must answer one question:

> **Does this work serve the declared subject?**

The declared subject is **the pack itself remaining installable, truthful, and provably working from
zero**. Work that serves it is in scope. Work that assumes a live production workload, an external
user base, or a growing feature surface is out of scope until this document changes.

---

## What steady-state commits to

- **Quarterly:** dependency and stack upgrade check; evidence-repo prune.
- **Monthly:** evidence rollup to `otel-ops-evidence`.
- **Per change:** a lean ECRR — quantified before and after, honest verdict.
- **The clean-host E2E gate** stays as the standing proof the pack still installs from nothing. It
  is the one thing that must keep working.
- **No new lanes, gates, compliance frameworks, or recurring writers.** A recurring writer requires
  an owner, a review date, and a kill switch, or it does not get created.

## What it explicitly does not commit to

Feature growth, an external audience, published releases, support obligations, or instrumenting a
workload that does not exist.

---

## Why the other two were rejected

**Instrument a real workload — rejected: no workload.** The roadmap's first option assumed a
MoneyCat service with live traffic. On 2026-08-14, `moneycat-site`, `scorebot`, `viz-engine` and
`socm` each had **zero commits since the Pack 3B split on 2026-07-24**, while this repository was
committed to daily across the same period. `moneycat-site` is served at `hub.resonai.uk` but is a
static Pages site emitting no server telemetry — the original Resonai problem restated, not solved.
Choosing this option would have made the roadmap describe work that is not happening.

**Productise the pack — deferred, not rejected.** The asset is real: **6.86 minutes** from clone to
first span on a genuinely clean Windows host, with a checksum-verified pinned MSI and a gate that
has gone RED twice and meant it. Windows OpenTelemetry onboarding is painful across the ecosystem
and this path is unusually good. It was not chosen because productising commits to an audience,
releases, and support — and the binding constraint on this estate is attention, evidenced by four
dormant repositories. Waiting does not destroy the asset; the clean-host gate keeps proving it.

---

## What reopens this decision, automatically

No review meeting required. Either of these makes the corresponding option real:

1. **A MoneyCat service resumes development with server-side traffic** → instrument it. That is the
   better subject the moment it exists.
2. **An identified external audience appears for the onboarding path** → productise.

If neither happens, steady-state stands and needs no renewal.

---

## Standing risk, named

Steady-state is how the 2025 drift began, and pretending otherwise would be dishonest.

What makes this different is not intention but instrumentation. Phases 0–2 removed the machinery
that made drift *invisible*: a compliance gate that could not fail, a drift guard that could not
pass, a permanently red CI check, an unsatisfiable exit criterion, 41 scheduled tasks failing
silently for months, and an installer URL that had returned 404 since it was written. What remains
is 11 scheduled workflows each carrying a written justification, and gates that can report failure.

The rule that follows from that experience, and applies to anything added under this purpose:

> **A check must be able to both pass and fail.** Anything that cannot is broken, however green it
> looks.

---

## Authority

Decided by the machine operator `@fubumaki`, who delegated the call to the chat/review seat after
that seat drafted the options and declined to self-ratify. The authority is the operator's; the
delegation was explicit. Chat/review proposes and does not decide — recorded here so this document
is not later read as a seat having awarded itself a decision.
