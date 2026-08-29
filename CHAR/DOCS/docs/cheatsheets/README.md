# BossCat Cheatsheets

Quick reference guides for Resonai [OTel] operations.

## Gate Verification

```powershell
# Run gate verification (strict mode)
pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict

# Run without failing on missing assets
pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -NoFailOnMissing
```

## ECRR Benchmark

```powershell
# Benchmark all ECRR reports
pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1
```

## Local Pipeline

```bash
# Run local pipeline verification
python BRAV/SCPT/run-local-pipeline.py --verbose
```

## SigNoz Health

```bash
# OTLP smoke test
python BRAV/SCPT/test-otlp-smoke.py --verbose
```

