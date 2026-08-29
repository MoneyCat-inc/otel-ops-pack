# IONA Error Ledger

This ledger tracks anomalies and recurring error classes for BossCat operations.

Format: `YYYY-MM-DD HH:mm:ss K | site | gate | class | note`

Resolved Incidents:

- 2025-10-16 09:30:00 +00:00 | prod | IONA | QUEUE_EVIDENCE_PATH_DRIFT |
  queue evidence wrote to DELT/ARTF instead of artifacts/ — **CLARIFIED** 2025-10-22:
  Both paths valid per Gate #008
- 2025-10-16 09:35:00 +00:00 | ci   | IONA | STATUS_EVIDENCE_STALE |
  docs/status/tests.json pointed at old run — **RESOLVED** 2025-10-22:
  Updated in Gate #008 remediation
- 2025-10-16 09:40:00 +00:00 | ci   | IONA | ASCII_EXPORT_POLICY |
  gate comment emitted non-ASCII glyphs — **POLICY DOCUMENTED** 2025-10-22:
  ASCII validation added

Active Incidents:

(None - all incidents from 2025-10-16 addressed via ECRR 2025-10-22)
