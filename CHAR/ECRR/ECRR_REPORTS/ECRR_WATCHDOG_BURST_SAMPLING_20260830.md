# ECRR — Watchdog Burst Sampling

**Date:** 2026-08-30
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — incident resolution 5 min → 10 s, both paths tested, healthy path unchanged

## 1. Examine

Operator proposal: adaptive watchdog cadence for better diagnostic data. Log-driven
self-rescheduling was rejected (feedback loop through the safety net; self-modifying
SYSTEM task; the 2025-drift pattern). Chosen shape: fixed 5-minute tick, escalate
resolution *within* the run when live state warrants it.

Gap analysis of the current script against its mission (close the MSI-disable
silent-dark, visibly): the not-Running path snapshotted state once at t+3s — the
08-13 flap produced six ambiguous lines over 25 minutes because 3 seconds cannot
distinguish slow StartPending from a crash loop, and nothing recorded *why* (no SCM
events, no start error text).

## 2. Clean

`scripts/windows/watchdog-otelcol.ps1`:

- Healthy path unchanged: one `ok` line, immediate exit.
- Not-Running path now: remediate (re-enable if Disabled, start — unchanged), then
  **burst-observe**: one `burst_sample` line every `$BurstSampleSec` (10 s) for up to
  `$BurstSeconds` (90 s) or until Running, then a final verdict line carrying
  `burst_samples`, `elapsed_s`, and the start error text.
- **Incident bundle** per non-Running entry: start error, start type, last 30 min of
  Service Control Manager events for the service → `artifacts/watchdog/incidents/incident-<ts>.json`,
  pruned to newest `$MaxIncidentFiles` (20). Event-driven, bounded, same owner and kill
  switch as the task — not a new recurring writer.
- Bundle failure logs `bundle_failed` — observable in both directions; exit code stays
  tied to service health only.
- Worst-case runtime ~100 s fits the task's existing 2-minute execution limit —
  **no task re-registration, no elevation needed**. `MultipleInstances IgnoreNew`
  already guards overlap.

**Test:** happy path against live `otelcol-contrib` → single `ok` line, exit 0.
Failure path against a stopped service the non-admin seat cannot start
(`-BurstSeconds 12 -BurstSampleSec 4`) → 3 burst samples at 4 s resolution, incident
bundle written with captured start error, final `start_failed`, exit 1.

## 3. Report

| Property | Before | After |
| --- | --- | --- |
| Incident resolution | 1 snapshot at t+3s | 10 s samples for up to 90 s |
| Failure context | action word only | start error + start type + SCM events bundle |
| Healthy-path cost | 1 line | 1 line (unchanged) |
| Task/schedule | 5 min, SYSTEM | untouched |
| New unbounded writers | — | none (log rotated; bundles capped at 20) |

## 4. Role

Claude (chat/review) analyzed, drafted, tested, and merged under standing delegation.
No elevation used; the scheduled task was not touched.

**Status:** COMPLETE

---

## Addendum (2026-08-31) — production validation + SCM filter fix

The burst path fired for real on 2026-08-30 20:55: host was shut down 13:55→20:53; the
post-boot catch-up tick found the collector Stopped, started it (beating delayed-auto),
confirmed Running at +11 s with one burst sample, wrote `incident-20260830-205513.json`,
clean `started` verdict. First live exercise of the design — worked as intended.

The incident exposed one latent bug: the bundle's SCM filter matched the short service
name (`otelcol-contrib`), but SCM messages use the display name ("OpenTelemetry
Collector") — so `scm_events` could never populate. Harmless on 08-30 (this host
suppresses informational 7036 events; the boot window genuinely had no matching events),
but crash-loop incidents log 7031/7034/7000 with the display name, and those would have
been silently missed. Fixed: filter now matches short name OR display name (applied by
the machine operator's seat, committed here). Regression: bundle path re-tested against a
stopped service — `incident_bundle` written, no `bundle_failed`; happy path exit 0.

Watch item recorded: `vhdx_gb` 105.6 → 119.9 GB in ~24 h; weekly trim is the lever,
the gate's 50 GB C: floor is the tripwire.
