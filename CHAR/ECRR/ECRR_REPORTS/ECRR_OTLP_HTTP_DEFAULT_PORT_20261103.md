# ECRR — OTLP/HTTP defaults on the gRPC port: the app's metric export never arrived

**Date:** 2026-11-03
**Actor:** Claude Code (local seat), in a side session started by the session that filed `ECRR_TS7_JEST_TOOLCHAIN_20261102.md` (§1c, the SigNoz exporter port)
**Scope:** PR #903, code lane: `ALFA/LIBS/lib/observability/signoz.ts`, new `ALFA/TEST/unit/observability/signoz-endpoint.test.ts`, `env.template`, `.env.example`, `BRAV/SCPT/security/remediate-secrets.ps1`, `scripts/windows/run-dotnet-test-instrumented.ps1`, `scripts/windows/install-dotnet-otel-autoinstrumentation.ps1` and the regenerated `docs/status/scripts.json` (commits `2e9e4d0aa`, `994e5939d`). PR #904, docs lane: `docs/ecrr/OTEL_SYNTH_RUNBOOK.md`, `docs/BossCat/DOTNET_OTEL_ACTIVATION.md` (commit `7cc20ca63`).
**Verdict:** **AMBER** — against the local stack the old default fails and the new one arrives, and a jest suite that fails on the old code now runs in the `unit` job. It closes GREEN when #903 and #904 merge and the `unit` job passes on `main` (addendum).
**Trigger:** `signoz.ts` exports over OTLP/HTTP but defaulted to 4317, the collector's gRPC port. #894 made its exporter import resolve on a clean install.

## 1. Examine

### 1a. Two collectors, four ports

The host runs two OTLP receivers: the Windows `otelcol-contrib` service (root `config.yaml`: `127.0.0.1:5320` gRPC, `5321` HTTP) and the Docker `signoz-otel-collector` (`signoz-collector-config.yaml`: 4317 gRPC, 4318 HTTP), which the Windows collector exports to on 4317. The brief placed 4317 and 4318 in `config.yaml`; they belong to the Docker collector. `DELT/CONF/otel-ports.json` carries all four.

### 1b. The failure, on the wire

`signoz.ts` builds `OTLPMetricExporter` from `@opentelemetry/exporter-metrics-otlp-http` with `url: ${OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4317'}/v1/metrics`. An OTLP/HTTP POST to 4317 meets a gRPC server: curl reports `Received HTTP/0.9 when not allowed`, Node's parser `Expected HTTP/, RTSP/ or ICE/`, and the collector logs `grpc: Server.Serve failed to create ServerTransport ... bogus greeting from client: "POST /v1/metrics HTTP/1."`. The same POST gets 200 on 4318 and on 5321. The SDK passes export errors to `diag`, and nothing in the app registers a diag logger, so the app dropped every metric without a line of output.

### 1c. How it got there

`signoz.ts` arrived on 2025-09-28 (`d5fb749dc`) defaulting to `14317`, then the host mapping of the collector's gRPC 4317 (`"14317:4317"`). #227 (`c025a462a`, 2026-06-12) moved it to 4317, and #262 (`c4f5bccfa`, 2026-06-26) did the same to `env.template`: port-for-port realignments that kept the protocol mismatch. B3 (2026-08-15) bound only the 5320/5321 consumers to `otel-ports`, so the 4317 users were outside it.

### 1d. The same mistake elsewhere

A repo-wide sweep (outside `CHAR/`, archives and evidence) of every OTLP/HTTP exporter, every reader of `OTEL_EXPORTER_OTLP_*ENDPOINT`, the env templates and the live docs:

| Where | What reads it | Was | Now |
| --- | --- | --- | --- |
| `signoz.ts:14` | OTLP/HTTP metric exporter | 4317 | 4318, trailing slash trimmed (#903) |
| `env.template:53` | `signoz.ts`, `instrumentation.ts`, `app/api/health/utils.ts`, all appending `/v1/<signal>` | 4317 | 4318 (#903) |
| `.env.example:11`, and its generator `remediate-secrets.ps1:107` | the same variable | retired 14317; 4317 | 4318 (#903) |
| `run-dotnet-test-instrumented.ps1:71` | the .NET app's job, which inherits `http/protobuf` from line 38 | 4317 | `Get-OtelIngestHttpBase` with `http/protobuf` (#903) |
| `install-dotnet-otel-autoinstrumentation.ps1:78` | printed setup | 4317, no protocol | adds `grpc` (#903) |
| `OTEL_SYNTH_RUNBOOK.md:15,33` | .NET recipe | 4317, no protocol | adds `grpc` (#904) |
| `DOTNET_OTEL_ACTIVATION.md:32` | the gRPC alternative | 5320, no protocol | adds `grpc` (#904) |

The .NET rows count because the auto-instrumentation defaults to `http/protobuf` (its v1.7.0 configuration docs, the version installed here and pinned by the install script), unlike the .NET SDK's `grpc`, and a `Start-Job` child inherits the parent's environment (checked). Checked and right: `tracing.ts` (5321 over HTTP through `otel-ports`), `iona-telemetry.ts`, `logs-sdk.ts` and `instrumentation.ts` (4318), the `ALFA/OTEL/synthetic` senders and `gpu-metrics-*.py` (protocol matches port), the Gate #026/#027/#029, demo and `deploy-dotnet-service.ps1` .NET scripts (gRPC ports with `grpc`), the compose `demo-app` and `bosscat-gate-bot-native.yml` (4318), and the other live docs.

### 1e. Found on the way, not changed here

- `docs/runbooks/misc/HUB_GO_LIVE_RUNBOOK.md:197` repeats the 4317 recipe; it is a dated record kept unedited.
- The retired `14317` survives in live text: `docs/demo/DEMO_SCRIPT.md:311,315` (troubleshooting) and `docs/runbooks/windows-collector.md:171` ("Direct path (14317) is production baseline").
- `signoz.ts:13` takes the API key from `OTEL_EXPORTER_OTLP_HEADERS?.split('=')[1]`, so `.env.example`'s `Authorization=Bearer …` becomes `Bearer Bearer …`. The local collectors do not check it.
- Export failures stay silent while the app registers no diag logger; a WARN-level logger in `signoz.ts` would surface the next one.

## 2. Clean

#903 defaults to `http://localhost:4318`. The module is written for HTTP exporters only, and `instrumentation.ts` in the same server process already sends OTLP/HTTP to 4318 from the same variable. A gRPC exporter on 4317 would add `@grpc/grpc-js`. Routing through the Windows collector (5321) would change the route; setting the variable does that and works (run E). The trailing-slash trim matches `instrumentation.ts`: the collector answers `//v1/metrics` with a 301. The new suite mocks the exporter and asserts its URL for the unset default, a base URL and a trailing slash. `docs/status/scripts.json` is regenerated for the two script sizes (Registry Guard). #904 carries the docs.

Not done: the .NET scripts were not run end to end. Their test app binds `0.0.0.0:5555` (a firewall prompt on the operator's desktop) and the profiler variables reach the job's own `pwsh`; the change rests on the v1.7.0 docs and the evaluated job table (`http://127.0.0.1:5321` with `http/protobuf`). The §1e items.

## 3. Report

Fresh `pnpm install --frozen-lockfile` (pnpm 10.18.1, Node 22.23.2) in a scratch worktree at `main` `0e2339c51`, against the running stack (`signoz-otel-collector` v0.144.8, the Windows `otelcol-contrib`, ClickHouse). The probe loads the repo's `signoz.ts` as the app does (module-load init), records one counter point under a run-unique metric name, flushes through `shutdownSigNoz()` and logs each export result. Arrival is polled for 60 s in `signoz_metrics.distributed_time_series_v4` and `distributed_samples_v4`, the tables SigNoz reads. SigNoz credentials were removed from the probe's environment.

| Run | `signoz.ts` | Endpoint variable | Export | Collector | ClickHouse |
| --- | --- | --- | --- | --- | --- |
| A | `main` | unset (4317) | FAILED: `Parse Error: Expected HTTP/, RTSP/ or ICE/` | `bogus greeting` at 14:37:10.730Z | 0 rows |
| B | #903 | unset (4318) | SUCCESS | no rejection | series (`resonai-backend`, `B143832`) and sample 1, within 6 s |
| C | #903 | `http://localhost:4318`, the new template value | SUCCESS | | arrived |
| D | #903 | `http://localhost:4318/` | SUCCESS | | arrived |
| E | #903 | `http://127.0.0.1:5321`, the Windows collector | SUCCESS | | arrived, through its export to 4317 |
| F | `main` | `http://localhost:4318/` | FAILED: `Moved Permanently` | 301 | 0 rows |

| Check | Result |
| --- | --- |
| jest on the same install | 5 suites, 126 tests passed (4 and 124 before) |
| the new suite on `main`'s `signoz.ts` | 2 failed: received `…4317/v1/metrics` and `…4318//v1/metrics` |
| `tsc --noEmit -p tsconfig.json` | exit 0 after `prisma generate`; `signoz.ts` in the program |
| #903 CI, first run | green except Registry Guard (`scripts.json` sizes), fixed in `994e5939d` |
| #904 | markdownlint-cli2 0.14.0: 0 errors; CI 15 of 15 green |

The six changed source files in #903 are byte-identical to the probed ones; the branch was then rebased over docs- and evidence-only commits (#897 to #901).

## 4. Role

Claude Code (local seat): investigation, probes, PRs #903 and #904 and this report; nothing merged. Operator `@fubumaki`: the merge gos for #903, #904 and this report.

**Incident in this session.** Between 14:30Z and 14:37Z a shell filter printed three host environment values, `SIGNOZ_API_KEY`, `SIGNOZ_API_TOKEN` and `SIGNOZ_JWT_SECRET`, into this seat's session log. Under the blast-radius rule they are rotated (operator): a new API key and token in the local SigNoz, and a new JWT secret, which the root compose's `signoz` service reads, so that container is recreated after the change. No value appears here or in any PR.

## 5. Next

- Merge #903 and #904 on the operator's go, then the `BOSSCAT_LOG.md` line and the mirror republish.
- Addendum: the `unit` job on `main` after #903 merges.

## 6. Addendum (2026-11-04): merged, green on `main`, rotation still owed

- Merged on the operator's go, squash, one at a time after an update-branch and fresh checks, with the `Driving:` assignment posted on #900 before the cascade's first merge: #903 `82d1040bc` (21:00Z), #904 `63927bfa4` (21:01Z), this report #905 `d5c5509af` (21:03Z).
- The `unit` job on `main` after #903 (push run 41911900610, head `82d1040bc`): jest 5 suites and 126 tests (4 and 124 before; the new `signoz-endpoint` suite adds 2), `node --test` 17 of 17, `tsc --noEmit` clean. The header's code condition is met; the rotation below keeps the verdict AMBER.
- **Rotation owed (operator).** The three values §4 records were printed into a session log, so under the blast-radius rule they are rotated, and that is a keyboard step for `@fubumaki`. The full list, wider than §4's:
  1. Revoke every SigNoz API key.
  2. Put the new key in the host variables `SIGNOZ_API_KEY` and `SIGNOZ_API_TOKEN`, in every scope that holds them (`SIGNOZ_API_KEY` is set at User and Machine scope), and in the Actions secret `SIGNOZ_API_KEY` (last updated 2026-08-14). `gate-nightly.yml` uses that secret only for read queries (`POST /api/v5/query_range`, sent by `verify-pipeline.ps1`), and under the blast-radius rule a CI-bound key is minted least privilege.
  3. Replace `SIGNOZ_JWT_SECRET`.
  4. Recreate the `signoz` container so it reads the new secret.
  5. Run Gate Nightly Verification and see it green with the new key.
- When it is done, record the date here and add rows for `SIGNOZ_API_TOKEN` and `SIGNOZ_JWT_SECRET` to `docs/BossCat/CREDENTIAL_ROTATION_CALENDAR.md`, which today has a row for `SIGNOZ_API_KEY` only.

**Status:** AMBER until the rotation is recorded here (operator); the code and docs changes are closed.
