# ECRR GPU_FIX Report (20251011)

- Lane: GPU_FIX
- Option B Required: False
- Ports: 5317=True, 5318=True
- Synthetic Span: name=iona.boot success=True endpoint=http://127.0.0.1:5318/v1/traces
- k6: test=ALFA/TEST/unit/k6/baseline-test.js exit=99 p95_ms=1.91574
- Status: GREEN

Artifacts:
- DELT/ARTF/gate-verification-results.json
- artifacts/k6-summary.json
- Snapshots captured: 15 files
