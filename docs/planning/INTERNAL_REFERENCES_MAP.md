# Internal References Map
**Generated:** 2025-10-09 06:27:35  
**Total References:** 773  
**Tool:** BossCat OEM Reference Scanner

---

## 📊 Executive Summary

This document maps all internal file references across the repository, identifying which files reference other files. This is essential for refactoring, migration (like tetragram), and understanding code dependencies.

### Statistics

| Metric | Count |
|--------|-------|
| Total References | 773 |
| Unique Source Files | 282 |
| Unique Target Files | 355 |

### References by File Type

| Type | Count |
|------|-------|| markdown | 106 |
| powershell | 402 |
| python | 124 |
| typescript | 141 |

---

## 🎯 Top 20 Most Referenced Files

These files are referenced most often across the codebase. Changes to these files will have wide-reaching impact.

| Rank | File | References |
|------|------|------------|| 1 | `time` | 26 |
| 2 | `@/lib/db` | 18 |
| 3 | `@/lib/middleware/otel` | 16 |
| 4 | `@/lib/middleware/auth` | 15 |
| 5 | `@/lib/middleware/rate-limit` | 13 |
| 6 | `@/lib/validation/schemas` | 12 |
| 7 | `scripts/agent/update-status.ps1` | 10 |
| 8 | `scripts/manage-gpu-sidecars.ps1` | 10 |
| 9 | `subprocess` | 9 |
| 10 | `scripts/import-dashboard.ps1` | 8 |
| 11 | `numpy` | 8 |
| 12 | `scripts/notify-alert.ps1` | 8 |
| 13 | `scripts/validate-production-gpu.ps1` | 8 |
| 14 | `scripts/ecrr-schedule-monitoring.ps1` | 8 |
| 15 | `../../lib/config/queue` | 7 |
| 16 | `scripts/gpu-integration-automation.ps1` | 6 |
| 17 | `scripts/canary-pattern-drills.ps1` | 6 |
| 18 | `scripts/monitor-ecrr-alerts.ps1` | 6 |
| 19 | `./db` | 6 |
| 20 | `scripts/test-webhook.ps1` | 6 |

---

## 📁 Top 20 Files With Most References

These files reference many other files. They are highly coupled to the rest of the codebase.

| Rank | File | Outgoing Refs |
|------|------|---------------|| 1 | `docs/archive/root-docs-2025-10-09-052108/miscellaneous/README_NEW.md` | 31 |
| 2 | `scripts/deploy-gpu-sidecars.ps1` | 17 |
| 3 | `scripts/send_synthetic_otel_simple.py` | 11 |
| 4 | `docs/BossCat/IONA_SETUP_GUIDE.md` | 10 |
| 5 | `scripts/gpu-automation-quickstart.ps1` | 10 |
| 6 | `synthetic/send_synthetic_otel.py` | 10 |
| 7 | `scripts/setup-ecrr-cicd-integration.ps1` | 9 |
| 8 | `scripts/update-daily-automation-enhanced.ps1` | 9 |
| 9 | `scripts/ecrr-schedule-monitoring.ps1` | 8 |
| 10 | `scripts/setup-complete-pipeline.ps1` | 8 |
| 11 | `rolling_run.py` | 8 |
| 12 | `scripts/run-latency-test-example.ps1` | 8 |
| 13 | `docs/archive/root-docs-2025-10-09-052108/iona/IONA_GATE_INTEGRATION_README.md` | 8 |
| 14 | `scripts/final-deployment-checklist.ps1` | 8 |
| 15 | `sidecars/compression/compression_sidecar.py` | 8 |
| 16 | `sidecars/aggregation/aggregation_sidecar.py` | 7 |
| 17 | `scripts/agent/staged-failure-drill.ps1` | 7 |
| 18 | `sidecars/inference/inference_sidecar.py` | 7 |
| 19 | `scripts/configure-webhook-url.ps1` | 6 |
| 20 | `synthetic/send_synthetic_otel_simple.py` | 6 |

---

## 📋 Complete Reference List

### CSV Format

The complete reference data is available in CSV format:
- **Master File:** `artifacts/reference-scan/master-references.csv`
- **Individual Scans:** `artifacts/reference-scan/*-refs.csv`

### Query Examples

**Find all references TO a file:**
```powershell
Import-Csv artifacts/reference-scan/master-references.csv | Where-Object { $_.Target -like "*filename*" }
```

**Find all references FROM a file:**
```powershell
Import-Csv artifacts/reference-scan/master-references.csv | Where-Object { $_.Source -like "*filename*" }
```

**Count references by type:**
```powershell
Import-Csv artifacts/reference-scan/master-references.csv | Group-Object Type | Sort-Object Count -Descending
```

---

## 🔧 Usage for Tetragram Migration

This reference map is critical for the tetragram migration (ALFA/BRAV/CHAR/DELT structure):

1. **Pre-Migration:** Identify all files that reference a directory you plan to move
2. **Path Rewriter:** Use this data to update all references automatically
3. **Validation:** After migration, re-run scanner to detect broken references

### Migration Impact Analysis

Before moving a directory, query references:
```powershell
$refs = Import-Csv artifacts/reference-scan/master-references.csv
$impactedFiles = $refs | Where-Object { $_.Target -like "scripts/*" } | Select-Object Source -Unique
Write-Host "Moving scripts/ will impact $($impactedFiles.Count) files"
```

---

## 🐾 BossCat Notes

**Maintenance:**
- Re-run scanner after major refactoring: `pwsh scripts/reference-scan/orchestrator.ps1`
- Commit updated map to track changes over time
- Use in CI to detect broken references

**Generated:** 2025-10-09 06:27:35  
**Next Scan:** Run after major file moves or refactoring
