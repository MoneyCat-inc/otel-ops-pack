# IONA Error Ledger

This ledger tracks anomalies and recurring error classes for BossCat operations.

Format: `YYYY-MM-DD HH:mm:ss K | site | gate | class | note`

Active Incidents:

- 2025-10-16 09:30:00 +00:00 | prod | IONA | QUEUE_EVIDENCE_PATH_DRIFT | queue evidence wrote to DELT/ARTF instead of artifacts/, masking missing canonical file
- 2025-10-16 09:35:00 +00:00 | ci   | IONA | STATUS_EVIDENCE_STALE | docs/status/tests.json still pointed at 2025-10-10 run rather than latest gate artifacts
- 2025-10-16 09:40:00 +00:00 | ci   | IONA | ASCII_EXPORT_POLICY | gate comment emitted non-ASCII glyphs that failed audit export validation
