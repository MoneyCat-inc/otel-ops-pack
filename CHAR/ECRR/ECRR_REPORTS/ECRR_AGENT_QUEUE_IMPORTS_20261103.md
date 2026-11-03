# ECRR — Agent scripts: dead queue-config import repointed, NodeSDK metric reader restored

**Date:** 2026-11-03
**Actor:** Claude Code (local seat), on the task proposed in `ECRR_TS7_JEST_TOOLCHAIN_20261102.md` §1c and §5 (#898)
**Scope:** PR #900, code lane: nine files under `BRAV/SCPT/agent` (commit `634a413a1`).
**Verdict:** **AMBER** — on a fresh frozen install of `main`, every queue-config specifier resolves, the five scripts that could not load now load, and `otel.ts` exports metrics through the exporter it configures; jest is unchanged at 4 suites / 124 tests. Closes GREEN when #900 merges.
**Trigger:** both were found while repairing jest under TypeScript 7 (#894) and left for their own change.

## 1. Examine

- **Dead path.** Ten specifiers in eight files took the queue config from `../../lib/config/queue` (`../../../lib/config/queue` in `migrate/`): imports at `db.ts:9`, `db.test.ts:6`, `runner.ts:14`, `status.ts:9`, `test-runner.ts:9`, `test-sqlite.ts:7`, `debug-runner.ts:8` and `migrate/from-json.ts:11`, and inline `require()` calls at `from-json.ts:247,251`. All resolve to `BRAV/lib/config/queue`, which has never existed on `main`: Phase B.1 (`3fdbd88db`) moved the scripts out of `scripts/agent/`, and Phase C.4 (`d1d45a761`, R100) moved `lib/config/queue.ts` to `ALFA/LIBS/lib/config/`, both on 2025-10-09.
- **Why it stayed hidden for 13 months.** An import of the `QueueConfig` interface alone is elided, so `db.ts`, `db.test.ts` (11 jest tests) and `from-json.ts` load. The five scripts that import values (`runner`, `status`, `test-runner`, `test-sqlite`, `debug-runner`) fail to load, and `runMigration()` throws on its first statement. No `tsc` run covers `BRAV/SCPT` (outside the root `include`), and no workflow or `package.json` script runs these files; their documented runner is `npx tsx <path>` from the repo root.
- **`otel.ts:15` passed `metricReader`.** sdk-node 0.222.0, the version `main` resolved until #876 (2026-11-01), mapped it into the meter provider's readers with a deprecation warning (`build/src/sdk.js:138-143`). 0.300.0 declares only `metricReaders` (`types.d.cts:13`) and otherwise builds readers from `OTEL_METRICS_EXPORTER`, defaulting to `otlp` over http/protobuf (`sdk.cjs:22-25, 93-100`, `utils.cjs:163-172`). Since #876, metrics left the process through `exporter-metrics-otlp-proto` instead of the http/json exporter configured here, and `OTEL_METRICS_EXPORTER=none` would have stopped them. `otel.ts` has no importer, script or workflow reference.

## 2. Clean

- The ten specifiers take the relative path to `ALFA/LIBS/lib/config/queue` (`../../../` from `agent/`, `../../../../` from `migrate/`), the form `BRAV/SCPT/emit-iona-span.ts:7` already uses. Nothing under `BRAV` uses the `@/` alias, and tsx looks for its tsconfig from the current directory, so the relative form works wherever a script is started.
- `test-sqlite.ts`: the "Run with" comment names `BRAV/SCPT/agent/test-sqlite.ts`.
- `otel.ts`: `metricReaders: [new PeriodicExportingMetricReader({...})]`, same exporter and 60 s interval. Explicit readers take precedence over `OTEL_METRICS_EXPORTER`.

## 3. Report

Fresh `pnpm install --frozen-lockfile` at `main` `0054eea5e` (pnpm 10.18.1, Node 22.23.2, tsx 4.23.15, typescript 7.0.2, jest 30.5.2). Before = `main`'s `BRAV/SCPT/agent`; after = the same tree with #900.

| Check | Before | After |
| --- | --- | --- |
| Queue-config specifiers that resolve, each relative to its file | 0 / 10 | **10 / 10**, to `ALFA/LIBS/lib/config/queue.ts` |
| Modules that load (one `tsx` process each: the six scripts and `db.ts`) | 2 / 7 | **7 / 7**, no entry point ran |
| `runMigration()` from an empty scratch directory | `MODULE_NOT_FOUND` at line 247 | past lines 247 and 251; stops at the missing `.agent/`; nothing written |
| `tsc -p` over the nine files (scratch config extending the root one) | 9 errors: 8 × TS2307, 1 × TS2561 at `otel.ts:15` ("Did you mean to write 'metricReaders'?") | **0** |
| `otel.ts` against an OTLP/HTTP capture server on `127.0.0.1` | `/v1/metrics` as `application/x-protobuf` (SDK default) | `/v1/metrics` as **`application/json`** (configured exporter) |
| `pnpm exec jest --ci` | 4 suites, 124 tests | **4 suites, 124 tests** |
| `git status --ignored` across the probes | unchanged | unchanged |

- Method: each specifier resolved with a `require` anchored at its own file under tsx; each module imported in its own `tsx` process from the repo root, where the `require.main === module` guards keep the entry points from running; `otel.ts` flushed through its own SIGTERM handler with `OTEL_EXPORTER_OTLP_ENDPOINT` set to the capture server. The probes were scratch files outside the repository. The same run on #894's head, before it merged, gave identical results.
- `unit` job on #900 (run 41656177752, head `634a413a1`): jest 4 suites / 124 tests, `node --test` 17 / 17, `tsc --noEmit` clean. 21 checks green, 1 skipped (`scan-scheduled`).
- Found, not changed: `BRAV/SCPT/agent/pr-template.md:15,17`, the 2025-09 checklist, still runs `scripts/agent/test-sqlite.ts` and `require('./lib/config/queue')`; `BRAV/SCPT/agent/error-watcher/smoke.js:8` and `publish.ps1-adapter.js:8` require `./dist/capture`, a build output nothing in the repository produces (the only other dead relative specifiers under `BRAV/`).
- Proposed `BOSSCAT_LOG.md` line (docs lane, after the merge):

```text
- <ts>Z — **[AGENT SCRIPTS: QUEUE-CONFIG IMPORT + OTEL METRIC READER]** Ten `lib/config/queue` specifiers in `BRAV/SCPT/agent` pointed at `BRAV/lib/config/queue`, which never existed (Phase B.1/C.4 moves, 2025-10-09): five scripts could not load and `runMigration()` threw; type-only imports and a `tsc` scope without `BRAV/SCPT` hid it for 13 months. `otel.ts` passed `metricReader`, which sdk-node 0.300.0 (#876) no longer reads, so metrics left through the SDK's http/protobuf default instead of the configured http/json exporter. #900: relative paths to `ALFA/LIBS`, `metricReaders: [...]`; fresh install 10/10 resolve, 7/7 load, scratch `tsc` 9 errors → 0, jest 4 suites / 124 tests. ECRR `ECRR_AGENT_QUEUE_IMPORTS_20261103.md`. Actor: Claude Code (local seat); go @fubumaki.
```

## 4. Role

Claude Code (local seat): investigation, the change, PR #900 and this report. Nothing merged, no workflow dispatched. Operator `@fubumaki`: the merge go. The driving seat: the log line and the mirror after the merge.

**Status:** OPEN until #900 merges.
