# Privacy Audit Checklist — Practice Flows

| Item | Status | Evidence |
| --- | --- | --- |
| No network calls in drills (analytics allowlist only) | ✅ | [`tests/practicePrivacy.test.js`](../tests/practicePrivacy.test.js) fails if a drill references anything except `/api/events`. |
| Analytics payload clamps applied | ✅ | [`tests/events-handler.test.js`](../tests/events-handler.test.js) verifies clamping + banned payload rejection. |
| Rate limiting proven with 429s | ✅ | [`tests/events-handler.test.js`](../tests/events-handler.test.js) `rate limits repeated requests` case. |
| Data controls (export/delete) available | ✅ | Practice flow JSON embeds `dataControls`, and the handler exposes `exportRingBuffer` / `clearRingBuffer`. |
| KPI SSOT scoped to `/api/events` | ✅ | [`docs/analytics-ssot.md`](./analytics-ssot.md). |

All checklist items must remain green for Codex Cloud to approve merges touching practice flows or `/api/events`.
