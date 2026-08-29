# Clean-host E2E — the drill

**What it proves:** the pack installs and produces a first span from **nothing** on a clean
Windows host. `docs/PURPOSE.md` calls this the one thing that must keep working.

**Why it is operator-driven:** GitHub-hosted runners cannot host it — Windows runners cannot
run the Linux SigNoz containers, Linux runners cannot exercise the winget/MSI path, and neither
is "clean" in the sense the gate proves. The substrate is a Hyper-V VM on the operator's host,
restored to a clean snapshot. Decision 2026-08-25 (option B): the runs stay manual, and
`.github/workflows/clean-host-freshness.yml` makes *skipping* visible — amber issue past
**31 days** (monthly for now; flip `CADENCE_DAYS` to 92 once this drill is boring), red if the
last verdict was not GREEN. A pin change (collector, SigNoz, ClickHouse) mandates a re-run
regardless of calendar.

## The drill

1. **Restore the clean snapshot** (host, elevated — nested virt needs host elevation for
   VM Connect/Hyper-V). Use the pre-Phase-0 checkpoint, not `docker-ready-*` (that one is for
   retrying after a failed Phase 0 without reinstalling Docker).
2. **Phase 0** (guest, elevated): copy `scripts/windows/phase0-setup.ps1`, `RUN-PHASE0.cmd`,
   and `scripts/windows/collector-version.txt` (sibling pin — else the embedded fallback runs)
   to the guest; run `RUN-PHASE0.cmd`. Excluded from the gate clock. Writes `C:\Phase0\DONE.json`.
3. **Gate clock** (guest, elevated): `RUN-GATE-CLOCK.cmd` — first clone byte to
   `verify-pipeline` exit 0. Known caveats: `canary-test.ps1` hangs on first Event Log source
   registration (skip it; verify covers the canary); do not Ctrl+C the transcript or the clock
   is lost (2026-08-23 lesson). Parameterise `run_id` before trusting the JSON it writes.
4. **Record the run** — update `CHAR/EVID/clean-host/latest.json` (PR, non-docs lane):
   `run_id`, `date`, `verdict` (GREEN only if verify exited 0 **and** the clock was actually
   measured — a functional-but-unclocked run records its caveats in `verdict_detail`),
   `collector`, `head`. Close the freshness issue if one is open.
5. **After a failed Phase 0**: `docker rm -f` leftovers or restore `docker-ready-*` before
   retrying.

## Reference numbers

- **6.86 min** clone-to-first-span, 2026-08-13, collector 0.158.0 — last *measured* clock.
- 2026-08-23, collector 0.159.0 — functional GREEN, clock estimated ~5–7 min (unmeasured).

## Future: automating the restore

Hyper-V restore + PowerShell Direct automation (option A) is deliberately not built. It
graduates from this runbook only after the manual drill is stable enough to be boring, and it
arrives as a tested script with an owner, a review date, and a kill switch — not before. If two
consecutive freshness ambers go unanswered, that is the signal to build it.
