# Decision memo — Windows collector: keep as first-class or retire

**Date:** 2026-08-03

**Drafted by:** Claude (chat/review seat) for operator decision

**Scope:** Roadmap 2026 H2, Phase 1 — standalone gate; gate-definition change rules apply

**Recommendation:** **Keep as first-class, and upgrade.** The premise behind retiring it does not
survive measurement.

---

## The premise, and why it fails

Gate #026A (Oct 2025) declared the Windows collector intentionally bypassed on the grounds that
"Docker collectors carry telemetry." Phase 1 exists because that declaration sits uneasily beside
nine months of continued investment in the thing supposedly bypassed.

Measured on the operator's host, 2026-08-03, the service is **Running / Automatic** at version
**0.104.0** and is actively exporting:

| Receiver | Log records accepted |
|---|---|
| `windowseventlog/application` | 268 |
| `windowseventlog/system` | 39 |
| `filelog/canary` | 125 |
| `otlp` (http, 127.0.0.1:5321) | 62 |
| **`otlp` exporter → SigNoz** | **472 sent, 0 failed** |

The two `windowseventlog` receivers are the decisive ones. **A collector inside a Docker container
cannot read the Windows Event Log.** It is not a configuration gap that could be closed by pointing
the Docker collector at something; the channel is a host-OS facility with no container-visible
equivalent. The same holds for host filesystem log tailing.

So the component declared deprecated is the sole carrier of a telemetry class the rest of the stack
cannot obtain. That is precisely the "simultaneously deprecated and load-bearing" state the Phase 1
exit criteria forbids — but the resolution runs the opposite way from what the roadmap anticipated:
the error is in the declaration, not in the component.

## What this means for the investment the roadmap flagged

The roadmap counts the Aug 2 repair session, the new watchdog, and the clean-host E2E gate as
evidence of a deprecated component absorbing effort. Re-read against the throughput above, that
work was not waste — it was protecting a live telemetry path. The MSI-disable silent-dark failure
the watchdog closes would have silently ended Windows Event Log collection with nothing to notice.

## The two branches, costed honestly

**Retire** means deleting the service install path, watchdog, runbook, and repair surface. It does
not simplify the stack; it **removes a capability**. Windows Event Log and host file logs stop
reaching SigNoz, and no Docker-side configuration restores them. The clean-host E2E does get faster
than 7.5 min, but it would then verify a pipeline that no longer collects what this host produces.
This branch is only correct if the operator decides Windows host telemetry is not wanted — a
product decision, not a cleanup.

**Keep** means accepting a real maintenance obligation: 0.104.0 shipped July 2024 and is roughly
three years behind (roadmap cites upstream v0.157.0 — confirm at execution time). The upgrade is
not cosmetic. The 2026-07-25 clean-host E2E already found that 0.104.0's scraper list-syntax caused
a crash-loop (finding F3), so the pin is actively causing known breakage; upgrading likely retires
that finding rather than creating new ones. Runbook version notes need rewriting either way.

## Recommendation

Keep as first-class and upgrade 0.104.0 → current. Retiring a component that is the only source of
268 application and 39 system event-log records, while it exports cleanly to SigNoz with zero send
failures, would trade a working capability for a shorter test run.

**Execution, in order:**

1. Correct the record first: Gate #026A's "intentionally bypassed" is factually wrong and is
   steering decisions. Amending it belongs in Phase 2 (truth in steering documents) and should not
   wait for the upgrade.
2. Upgrade the pin, then re-run clean-host E2E and confirm the F3 crash-loop finding is retired.
3. Update runbook version notes — the 0.104.0 syntax caveats change.
4. Prune the dead sub-receiver while in there: `filelog/queue` tails `C:/logs/queue/*.log`, whose
   only file (`health.log`, 5.0 MB) has not been written since 2025-10-09. It is a receiver with no
   producer — the same failure class Phase 0 just cleared, at smaller scale.

**If the operator instead chooses retire,** the memo's own logic requires stating plainly what is
being given up: Windows Event Log and host file telemetry, permanently, with no Docker-side
substitute. That is a legitimate choice — but it should be recorded as a scope reduction, not as
removing dead machinery.

## Confidence and gaps

Throughput figures are a point-in-time read of the collector's own `/metrics` on one host; they
prove the receivers are live, not what volume they sustain over a week. Nothing here establishes
that anyone *reads* the Windows event logs in SigNoz — "is this telemetry consumed by a human or an
alert?" is the Phase 4 question, and if the answer is no, this decision deserves revisiting there
rather than being pre-empted here.
