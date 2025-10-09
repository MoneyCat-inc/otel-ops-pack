# Tetragrammaton User Guide

## Overview

The Tetragrammaton automation stack provides comprehensive cross-language benchmark validation using the YHWH (Yod-He-Vav-He) architecture. This guide covers usage of the `-hehe` parameter and related automation features.

## Quick Start

### Basic Usage

```powershell
# Execute cross-language benchmarks
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action cross-language

# Execute HE-HE dual integration
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe

# Run nightly CI with all integrations
pwsh -File scripts/nightly-tetragrammaton-ci.ps1 -IncludeHeHeIntegration
```

### Dry Run Validation

```powershell
# Validate configuration without execution
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe -DryRun
pwsh -File scripts/nightly-tetragrammaton-ci.ps1 -DryRun
```

## Tetragrammaton Architecture

### YHWH Structure

```
YOD (Foundation) ──► Core text processing operations
     │
     ▼
HE (Interface) ────► Command-line interface layer
     │
     ▼
VAV (Validation) ──► Input validation and error handling
     │
     ▼
HE (Integration) ──► Complete execution orchestration
```

### HE-HE Dual Integration

The `-hehe` parameter specifically targets the dual HE elements:
- **HE (Interface)**: CLI operations and user interactions
- **HE (Integration)**: Complete execution orchestration

## Command Reference

### Tetragrammaton Benchmark Automation

```powershell
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action <action> [options]
```

**Actions**:
- `run`: Execute benchmarks for specified language
- `validate`: Validate benchmark environments
- `cross-language`: Generate cross-language comparison
- `hehe`: Execute HE-HE dual integration
- `report`: Generate ECRR compliance report

**Language Options**:
- `nodejs`: NodeJS Tetragrammaton benchmark only
- `python`: Python logfilter benchmark only
- `both`: Execute both benchmarks
- `cross-language`: Cross-language comparison mode
- `hehe`: HE-HE dual integration mode

**Common Options**:
- `-OutputPath <path>`: Output directory for artifacts
- `-ECRRReportDir <path>`: ECRR reports directory
- `-BossCatSnapshotDir <path>`: BossCat snapshot directory
- `-DryRun`: Validate configuration only

### Nightly Tetragrammaton CI

```powershell
pwsh -File scripts/nightly-tetragrammaton-ci.ps1 [options]
```

**Options**:
- `-SignozUrl <url>`: SigNoz UI URL (default: http://localhost:8080)
- `-BenchmarkPaths <array>`: Benchmark directory paths
- `-IncludeDashboardExport`: Include SigNoz dashboard export
- `-IncludeCrossLanguageComparison`: Include cross-language analysis
- `-IncludeQuadrantMatrix`: Include quadrant matrix analysis
- `-IncludeHeHeIntegration`: Include HE-HE dual integration
- `-DryRun`: Validate configuration only

### Tetragrammaton Quadrant Matrix

```powershell
pwsh -File scripts/tetragrammaton-quadrant-matrix.ps1 -BenchmarkPath <path> [options]
```

**Options**:
- `-BenchmarkPath <path>`: Path to NodeJS benchmark directory
- `-OutputPath <path>`: Output directory for quadrant reports
- `-ECRRReportDir <path>`: ECRR reports directory
- `-IncludeDetailedMetrics`: Include detailed per-quadrant metrics
- `-DryRun`: Validate configuration only

## GitHub Actions Integration

### Manual Trigger

Access: GitHub Actions → Workflows → Nightly Tetragrammaton Benchmarks → "Run workflow"

**Configuration Options**:
- `include_dashboard_export`: Include SigNoz dashboard export (default: true)
- `include_cross_language`: Include cross-language comparison (default: true)
- `include_quadrant_matrix`: Include quadrant matrix analysis (default: true)
- `include_hehe_integration`: Include HE-HE dual integration (default: false)

### Automated Schedule

- **Schedule**: Daily at 2:00 AM UTC
- **Cron**: `0 2 * * *`
- **Purpose**: Aligned with executive dashboard export time

## Output Artifacts

### Generated Files

**Cross-Language Reports**:
- `artifacts/tetragrammaton-benchmarks/cross-language-benchmark-report.md`
- `artifacts/tetragrammaton-benchmarks/cross-language-metrics.json`

**Quadrant Matrix Reports**:
- `artifacts/tetragrammaton-quadrants/tetragrammaton-quadrant-matrix-report.md`
- `artifacts/tetragrammaton-quadrants/tetragrammaton-quadrant-metrics.json`

**ECRR Reports**:
- `docs/ecrr/ECRR_REPORTS/tetragrammaton-benchmark-ecrr-YYYY-MM-DD.md`
- `docs/ecrr/ECRR_REPORTS/tetragrammaton-quadrant-ecrr-YYYY-MM-DD.md`

**BossCat Snapshots**:
- `docs/observability/snapshots/tetragrammaton-benchmark-snapshot-YYYY-MM-DD-HHMMSS.json`
- `docs/observability/snapshots/nightly-tetragrammaton-snapshot-YYYY-MM-DD-HHMMSS.json`

## Troubleshooting

### Common Issues

**Benchmark Path Not Found**:
```powershell
# Check benchmark paths
Test-Path "C:\Users\fubum\nodejs_benchmark"
Test-Path "C:\Users\fubum\codex_local_test"
```

**Dependency Issues**:
```powershell
# Validate NodeJS dependencies
cd "C:\Users\fubum\nodejs_benchmark"
npm install

# Validate Python dependencies
cd "C:\Users\fubum\codex_local_test"
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -e .[test]
```

**Permission Issues**:
```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Debug Mode

```powershell
# Enable verbose output
$VerbosePreference = "Continue"
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe -Verbose
```

## Performance Metrics

### Expected Execution Times

- **NodeJS Benchmark**: ~3-5 minutes
- **Python Benchmark**: ~2-3 minutes
- **Cross-Language Comparison**: ~1-2 minutes
- **HE-HE Integration**: ~6-8 minutes total
- **Quadrant Matrix**: ~1 minute
- **Nightly CI**: ~10-15 minutes

### Resource Usage

- **Memory**: <500MB peak usage
- **Disk**: ~100MB for artifacts per run
- **Network**: Minimal (local execution)

## Best Practices

### Development Workflow

1. **Always use dry run first**:
   ```powershell
   pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe -DryRun
   ```

2. **Validate environments before execution**:
   ```powershell
   pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action validate
   ```

3. **Check artifacts after execution**:
   ```powershell
   Get-ChildItem artifacts/ -Recurse -File | Sort-Object LastWriteTime -Descending
   ```

### Integration Testing

1. **Test individual components**:
   ```powershell
   pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action run -Language nodejs
   pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action run -Language python
   ```

2. **Test cross-language comparison**:
   ```powershell
   pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action cross-language
   ```

3. **Test HE-HE integration**:
   ```powershell
   pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe
   ```

## BossCat Compliance

### ECRR Framework

All executions follow the ECRR (Examine → Clean → Report → Role) framework:

- **Examine**: Environment validation and benchmark setup
- **Clean**: Benchmark execution and artifact generation
- **Report**: Evidence collection and compliance documentation
- **Role**: Assigned actor responsibility (Tetragrammaton Benchmark Automation)

### Governance Requirements

- **Evidence Collection**: All executions generate comprehensive evidence
- **BossCat Snapshots**: Executive-level reporting for governance visibility
- **ECRR Compliance**: Automated compliance checking and reporting
- **Cross-Language Validation**: Multi-ecosystem capability demonstration

## Advanced Usage

### Custom Configuration

```powershell
# Custom output paths
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe -OutputPath "custom/artifacts" -ECRRReportDir "custom/ecrr" -BossCatSnapshotDir "custom/snapshots"

# Custom benchmark paths
pwsh -File scripts/nightly-tetragrammaton-ci.ps1 -BenchmarkPaths @("C:\custom\nodejs", "C:\custom\python")
```

### Integration with Existing Workflows

```powershell
# Chain with existing automation
pwsh -File scripts/tetragrammaton-benchmark-automation.ps1 -Action hehe
pwsh -File scripts/nightly-dashboard-export.ps1
pwsh -File scripts/ecrr-compliance-monitor.ps1
```

## Support and Documentation

### Additional Resources

- [Tetragrammaton HE-HE Integration Complete](TETRAGRAMMATON_HEHE_INTEGRATION_COMPLETE.md)
- [Tetragrammaton Automation Integration Complete](TETRAGRAMMATON_AUTOMATION_INTEGRATION_COMPLETE.md)
- [BossCat Tetragrammaton Sign-Off Documentation](BOSSCAT_TETRAGRAMMATON_SIGNOFF_DOCUMENTATION.md)

### Contact

For issues or questions regarding the Tetragrammaton automation stack:
- Check existing documentation in the `docs/` directory
- Review ECRR reports in `docs/ecrr/ECRR_REPORTS/`
- Examine BossCat snapshots in `docs/observability/snapshots/`

---

**Generated**: 2025-10-06 01:00 UTC  
**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**BossCat Compliance**: ECRR Framework Implemented  
**Cross-Language Capability**: NodeJS + Python Validation**
