## RSI Proposal (BossCat)

- Objective: strictly improve primary metric with guards honored
- Evidence: attach METRICS lines and evaluation summary

### Summary

- Index: files/sec -> <fill>
- Archive: arch_qps_effective -> <fill>
- Guards: errors=0, rate_backoff_ms stable

### Reproduce

```
node BRAV/SCPT/rsi/propose.mjs > .agent/rsi-candidate.json
pwsh BRAV/SCPT/rsi/evaluate.ps1 -Candidate .agent/rsi-candidate.json
```

### Artifacts

- `CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl`
- `CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl`
- `docs/ecrr/ECRR_REPORTS/RSI_EVAL_LATEST.md`

