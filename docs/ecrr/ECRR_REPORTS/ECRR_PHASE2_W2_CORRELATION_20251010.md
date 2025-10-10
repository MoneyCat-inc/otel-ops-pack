# ECRR Phase 2 · Week 2 — Correlation ID Adoption

Evidence: Correlation ID generation, propagation, and verification across logs and traces.

- Examine
  - Added `scripts/lib/correlation.ts` providing UUID generation and context propagation.
  - Logger `scripts/lib/logger.ts` now mixes `correlation_id` from active context into every log line.
  - Emitter `scripts/emit-synthetic-span.ts` sets `correlation_id` span attribute and sends `x-correlation-id` header.
  - Example `scripts/examples/log-with-trace.ts` demonstrates file logging with `correlation_id`.

- Clean
  - Updated OTLP exporter headers to include `x-correlation-id`.
  - Root and child spans carry `correlation_id` attribute.
  - `.agent/EVIDENCE.log` schema extended with `correlation_id`.

- Report
  - Acceptance: `logs/app.log` includes `correlation_id`, `trace_id`, and `span_id` on first entry.
  - Emitter prints `Correlation ID: <uuid>` and last root span contains `correlation_id` attribute.
  - Verifier `scripts/verify-correlation.ps1` confirms logs and optionally checks SigNoz API.

- Role
  - Investigator: Verified file logs and exporter headers.
  - Gap-Closer: Implemented correlation library and wiring.
  - QA Scribe: Recorded this ECRR report and evidence schema change.

Artifacts
- Logs: `logs/app.log`
- Evidence: `.agent/EVIDENCE.log`
- Scripts: `scripts/lib/correlation.ts`, `scripts/lib/logger.ts`, `scripts/emit-synthetic-span.ts`, `scripts/examples/log-with-trace.ts`, `scripts/verify-correlation.ps1`

Notes
- SigNoz API check is best-effort; verifier exits 0 if API unavailable, but prints a note.

