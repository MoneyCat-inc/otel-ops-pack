# OpenTelemetry Collector Config Validation Guide

## Overview
This guide provides proper validation workflows for the Windows OpenTelemetry Collector configuration before making changes or restarts.

## Supported Validation Commands

### 1. Config Syntax Validation
```powershell
# Validate config syntax without running the collector
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'
```
**Expected Result**: Silent success (exit code 0) if config is valid, error output if invalid.

### 2. Component Discovery
```powershell
# List available components in this collector distribution
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' components
```
**Use Case**: Verify that receivers, processors, and exporters referenced in config are available.

### 3. Config Property Override Testing
```powershell
# Test config changes without modifying the file
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml' --set='service.telemetry.logs.level=debug'
```
**Use Case**: Test configuration changes before applying them to the actual config file.

## Unsupported Commands (Avoid)

❌ **DO NOT USE**: `--dry-run` flag
```powershell
# This will fail with "unknown flag: --dry-run"
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' --config 'C:\otel\config.yaml' --dry-run
```

## Pre-Restart Validation Workflow

1. **Validate current config**:
   ```powershell
   & 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'
   ```

2. **Check service status**:
   ```powershell
   Get-Service -Name otelcol-contrib
   ```

3. **Make config changes** (if validation passed)

4. **Re-validate after changes**:
   ```powershell
   & 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'
   ```

5. **Restart service**:
   ```powershell
   Restart-Service -Name otelcol-contrib
   ```

6. **Verify service health**:
   ```powershell
   Get-Service -Name otelcol-contrib
   ```

## Troubleshooting

### Config Validation Fails
- Check YAML syntax with a YAML validator
- Verify all referenced components exist using `components` command
- Check file paths and permissions

### Service Won't Start After Config Change
- Revert to previous config
- Check Windows Event Log for collector errors
- Use `validate` command to test the reverted config

## Service Identity Best Practices

### Correct Service Naming
```yaml
# Good: Descriptive service names
service.name: windows-logs          # For Windows Event Logs
service.name: application-logs      # For application file logs  
service.name: gpu-metrics          # For GPU-specific metrics
```

### Avoid Generic Names
```yaml
# Bad: Misleading service names
service.name: windows-gpu-metrics  # Used for all Windows logs (confusing)
service.name: collector            # Too generic
```

## Integration with Monitoring

After config changes, verify in SigNoz:
- **Logs Query**: `resource.service.name = "windows-logs"`
- **UI Path**: Logs → Add filter → resource.service.name equals windows-logs

This ensures logs are properly categorized and searchable by service identity.
