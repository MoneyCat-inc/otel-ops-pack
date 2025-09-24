# Analytics SSOT — Practice KPIs

**Source of truth:** `/api/events` ring buffer implemented in [`src/api/events/handler.js`](../src/api/events/handler.js). The handler clamps payloads, enforces rate limits, and guarantees `Cache-Control: no-store` so analytics stay local-first.

## KPIs

| KPI | Description | Calculation | Notes |
| --- | --- | --- | --- |
| Mic Grant % | Share of drills where the mic permission was granted on the first try. | `(grants / attempts) * 100` sourced from `grantRatePct` | Populated by warmup drill analytics only. |
| Activation % | Share of phrase drills that hit the activation threshold. | `(activations / attempts) * 100` sourced from `activationRatePct` | Populated by activation drill analytics only. |
| Time In Target % | Portion of frames inside the coached pitch/intonation band. | `timeInTargetPct` averaged per session | Optional diagnostic card in `/analytics`. |

All downstream dashboards and reports must read from this table. No other endpoint is permitted to emit these KPIs.

## Data Handling Guarantees

- Payloads larger than 25 events are rejected with `400` (`too_many_events`).
- Audio blobs, transcripts, emails, phone numbers, and similar identifiers raise `400 invalid_event`.
- Ring buffer size defaults to 256 events and exposes export/delete helpers for compliance tooling.
- Rate limits default to 6 requests / 10 seconds per client; bursting beyond this window returns `429` with a retry hint.

See [`tests/events-handler.test.js`](../tests/events-handler.test.js) for automated coverage of these guarantees.
