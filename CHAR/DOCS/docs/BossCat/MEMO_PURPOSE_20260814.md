# Decision memo — what does this stack observe?

**Date:** 2026-08-14

**Drafted by:** Claude (chat/review seat) for operator decision

**Scope:** Roadmap 2026 H2, Phase 4 — the deferred purpose question

**Recommendation:** **Deliberate steady-state**, with the clean-host onboarding path preserved as the
pack's artifact of record and productisation left open rather than closed.

---

## What the stack observes today

Verified 2026-08-14, not restated from documentation:

| Subject | Nature |
|---|---|
| `demo-app` | synthetic, in `docker-compose.yml` |
| `gpu-aggregation`, `gpu-inference`, `gpu-compression` | synthetic load generators |
| `dotnet-test-app` | the .NET target used by the k6 performance gate |
| Windows host Event Log, filelog, local OTLP | real, but the host's own signals |

Every trace and metric in this stack originates from something built to produce them. The only
non-synthetic telemetry is the Windows collector's log stream — and that describes the machine
running the observability stack, not a workload being observed.

## The finding that reframes the question

The roadmap frames Phase 4 as choosing between three subjects. The first — *instrument a real
workload, any MoneyCat service with actual traffic* — assumes such a service exists.

**It does not, today.** All four sibling repositories have **zero commits since the Pack 3B split on
2026-07-24**:

| Repository | Last commit | Commits since split |
|---|---|---|
| `moneycat-site` | 2026-07-24 | 0 |
| `scorebot` | 2026-07-24 | 0 |
| `viz-engine` | 2026-07-24 | 0 |
| `socm` | 2026-07-24 | 0 |

Meanwhile `otel-ops-pack` and `otel-ops-evidence` have been committed to continuously across the
same three weeks. **The observability infrastructure is the only actively developed thing in the
estate.**

`moneycat-site` is live — `hub.resonai.uk` serves 200 — but it is a static Pages site. It emits no
server telemetry, which is the original Resonai problem restated rather than solved.

This does not decide the question, but it removes an option that looked available.

## The three options, costed

**1 · Instrument a real workload.** Blocked on a subject, not on capability. Choosing it commits to
reviving or building a service *first*, which is a product decision wearing an observability
costume. Picking it today would mean the stack keeps observing its demo app while the roadmap claims
otherwise — the exact drift Phase 2 spent itself removing.

**2 · Productise the pack.** This has the strongest asset behind it. Clone to first span is **6.86
min** on a genuinely clean Windows host, with a checksum-verified pinned MSI and a gate that proves
it repeatably. Windows OpenTelemetry onboarding is genuinely painful in the wider ecosystem, and
this path is unusually good.

The cost is not technical. Productising means an audience, releases, support, and a docs surface
that must stay true for strangers — a standing commitment. The evidence that capacity is the binding
constraint is on this page: four product repositories, dormant three weeks.

**3 · Deliberate steady-state.** Declare the stack reference infrastructure. Keep the quarterly
upgrade-and-prune and monthly rollup cadence, keep the clean-host gate as the proof it still works,
and redirect attention to product repositories when they resume.

The honest objection: steady-state is how the 2025 drift began. That objection is weaker now than it
was in June. Phases 0–2 removed the machinery that made drift invisible — a compliance gate that
could not fail, a drift guard that could not pass, 41 scheduled tasks failing silently, an installer
URL that had 404'd since it was written. What remains is 11 scheduled workflows with written
justifications and a gate that has proven it can go RED twice and mean it.

## Recommendation

**Take option 3, and record option 2 as deferred rather than rejected.**

The stack is finished as infrastructure. It works, it is now truthful about what it does, and
nothing is asking it for more. Choosing a subject it does not have would put the roadmap back in the
position Phase 2 just corrected: a steering document describing work that is not happening.

Steady-state is also the only option whose cost matches the evidence. The estate's constraint is
attention, and the four dormant repositories are where attention is owed.

**What this commits to:**

- quarterly upgrade + prune; monthly evidence rollup
- the clean-host E2E as the standing proof the pack still installs from zero
- no new lanes, gates, or recurring writers
- `PURPOSE.md` as the test for every future gate: does this work serve the declared subject?

**What reopens the question, automatically:**

- any MoneyCat service resuming development with server-side traffic — then option 1 becomes real
  and should be taken
- an identified external audience for the onboarding path — then option 2 becomes real

Both triggers are observable without a review meeting, which is the point.

## Note on the deliverable

The roadmap asks for `docs/PURPOSE.md` recording the choice and its rejection reasons. This memo is
the options draft; `PURPOSE.md` should be written once the operator decides, and should be one page
that a stranger can read before proposing a gate.
