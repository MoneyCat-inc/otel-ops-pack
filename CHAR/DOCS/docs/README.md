# Docs Index — otel-ops-pack

Source of truth for documentation is this `docs/` tree; `CHAR/DOCS/` is a read-only publish mirror.
The rendered hub is [`docs/index.html`](index.html); the navigation index is
[`status/REFERENCES_MAP.md`](status/REFERENCES_MAP.md). This file is the plain-markdown map.

## Start here

- [`PURPOSE.md`](PURPOSE.md) — what this stack is for (deliberate steady-state, 2026-08-14) and the
  test every proposed change must pass
- [`REPOSITORY_STRUCTURE.md`](REPOSITORY_STRUCTURE.md) — the four planes, legacy roots, where things run from
- [`architecture/CURRENT_ARCHITECTURE.md`](architecture/CURRENT_ARCHITECTURE.md) — Windows collector → SigNoz topology,
  read from the canonical config files
- [`BossCat/CHARTER.md`](BossCat/CHARTER.md) — the four seats, lane discipline, operating principles
- [`BossCat/ROADMAP_2026H2.md`](BossCat/ROADMAP_2026H2.md) — roadmap of record (all phases closed 2026-08-14)

## Governance and record

- [`BossCat/BOSSCAT_LOG.md`](BossCat/BOSSCAT_LOG.md) — the live log, one line per change
- `../CHAR/ECRR/ECRR_REPORTS/` — per-change evidence (ECRR: Examine → Clean → Report → Role);
  template in [`ecrr/ECRR_TEMPLATE.md`](ecrr/ECRR_TEMPLATE.md)
- [`BossCat/REQUIRED_STATUS_CHECKS.md`](BossCat/REQUIRED_STATUS_CHECKS.md) — live required-check set on `main`
- [`AGENTS.md`](AGENTS.md) — workflow conventions (concurrency, retention, job summaries)
- [`BossCat/LOOP_CLOSING_MACHINE_ARCHITECTURE.md`](BossCat/LOOP_CLOSING_MACHINE_ARCHITECTURE.md) — CI demand-shaping
  vision with its 2026-09-01 status addendum
- [`comfort-cat/`](comfort-cat/README.md) — creative, copy and accessibility reference

## Operations

Runbooks (`runbooks/`):

- [`windows-collector.md`](runbooks/windows-collector.md) — the collector service: status, version pin, repair surface
- [`clean-host-e2e.md`](runbooks/clean-host-e2e.md) — the standing proof the pack installs from nothing
- [`signoz-stack-upgrade.md`](runbooks/signoz-stack-upgrade.md) · [`signoz-api-proofs.md`](runbooks/signoz-api-proofs.md)
  · [`unified-telemetry-proofs.md`](runbooks/unified-telemetry-proofs.md)
- [`wsl-recovery.md`](runbooks/wsl-recovery.md) · [`DOCKER_VHDX_MAINTENANCE.md`](DOCKER_VHDX_MAINTENANCE.md)
- `runbooks/misc/` — older deployment and hub runbooks (check dates before relying on them)

Cheatsheets (`cheatsheets/`): [index](cheatsheets/README.md) · [gate](cheatsheets/GATE_CHEATSHEET.md) ·
[watchdog](cheatsheets/WATCHDOG_CHEATSHEET.md) · [Cursor implementer](cheatsheets/cursor-implementer.md) ·
[security-notifications archiver](cheatsheets/security-notifications-archiver.md) · ADOT
([setup](cheatsheets/adot-setup.md), [exporter config](cheatsheets/adot-exporter-config.md))

## Status and registries

- [`status/README.md`](status/README.md) — `workflows.json` (CI-guarded), `scripts.json`, `REFERENCES_MAP.*`
- [`status/misc/STATUS.md`](status/misc/STATUS.md) — executive status page
- [`IONA_ERRORS.md`](IONA_ERRORS.md) — error ledger · [`MONITORING_SCHEDULE.md`](MONITORING_SCHEDULE.md)

## Other topics

- [`vr/`](vr/README.md) — Quest 3 full-body tracking (SlimeVR / Smol Slimes) setup and checklist
- [`gpu/`](gpu/), [`icf/`](icf/), [`rsi/`](rsi/), [`vizr/`](vizr/), [`personas/`](personas/) — adjacent notes;
  the visualizer and social lanes were split out in Pack 3B (2026-07-24) and are not maintained here

## Archives

- [`archive/`](archive/) and [`gate/archive/`](gate/archive/) — historical material, bannered, not maintained
- Dated briefings, memos and run cards under `BossCat/` are records of their own dates; corrections are
  addenda, never rewrites (charter rule)

*Index rewritten 2026-09-01; the previous version listed only the VR section.*
