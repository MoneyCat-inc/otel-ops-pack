# Practice Flow Privacy Guardrails

The practice flows live in [`practice-flows/presets`](../practice-flows/presets) and define the Warmup → Glide → Phrase → Reflection journey for local-first drills. Each flow ships with explicit **data controls** and analytics hooks so we can prove that no audio ever leaves the device.

## Data Controls

- ✅ `export`: users can export their IndexedDB sessions locally.
- ✅ `delete`: sessions can be cleared at any time.
- ✅ `retentionHours`: capped to a single day to align with on-device storage promises.

These controls are required per flow and are enforced by [`tests/practicePrivacy.test.js`](../tests/practicePrivacy.test.js).

## Analytics Allowlist

Drill steps may only tee analytics into `/api/events`. The Jest gate verifies:

1. Every drill step only references the allowlisted endpoint.
2. Analytics payloads exclude audio blobs, transcripts, emails, phone numbers, and other PII hints.
3. Flow definitions do not embed any other network calls.

If a future flow introduces an additional analytics endpoint or payload field, the test suite will fail at merge time, preserving the "no network calls in drills" audit commitment.

## KPI Feeds

The only metrics that leave the flow runner are cohort-level grant %, activation %, and time-in-target summaries. They are clamped server-side (see [`src/api/events/handler.js`](../src/api/events/handler.js)) before landing in the ring buffer feeding `/analytics`.
