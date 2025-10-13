# IONA Error Ledger

This ledger tracks anomalies and recurring error classes for BossCat operations.

Format: `YYYY-MM-DD HH:mm:ss K | site | gate | class | note`

Examples:

- 2025-10-12 00:00:00 +00:00 | ci  | IONA | SIG_NOZ_UI | transient 503 during nightly health poll
- 2025-10-12 00:10:00 +00:00 | stg | IONA | QUEUE_EVIDENCE_MISSING | queue-steward-verification.txt absent (non-blocking)
