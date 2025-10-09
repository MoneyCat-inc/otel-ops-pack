# Windows Collector Operations Runbook

**Purpose**: Quick reference for enabling and managing the OpenTelemetry Windows Collector service.

## Quick Setup (One-Shot)

```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\enable-windows-collector.ps1 -OtlpEndpoint "http://localhost:4317"
```

## Service Management

### Check Status
```powershell
Get-Service otelcol-contrib
sc query otelcol-contrib
```

### Start/Stop/Restart
```powershell
Start-Service otelcol-contrib
Stop-Service otelcol-contrib
Restart-Service otelcol-contrib
```

### Health Check
```powershell
Invoke-WebRequest http://localhost:13133/healthz
```

## Configuration

### Config Location
- **Path**: `C:\ProgramData\otelcol-contrib\config.yaml`
- **Backup**: Automatically created with timestamp before changes

### Key Endpoints
- **OTLP gRPC**: `0.0.0.0:4317`
- **OTLP HTTP**: `0.0.0.0:4318`
- **Health Check**: `0.0.0.0:13133`
- **Metrics**: `0.0.0.0:8888`

### Firewall Ports
- **4317**: OTLP gRPC (inbound)
- **4318**: OTLP HTTP (inbound)
- **13133**: Health check (inbound)
- **8888**: Collector metrics (inbound)

## Troubleshooting

### Service Won't Start
1. Check Event Viewer: `Applications and Services Logs → OpenTelemetry-Collector`
2. Verify config syntax: `otelcol-contrib --config C:\ProgramData\otelcol-contrib\config.yaml --dry-run`
3. Check port conflicts: `netstat -an | findstr ":4317"`

### Health Check Fails
1. Verify service is running: `Get-Service otelcol-contrib`
2. Check config file exists and is valid YAML
3. Test port connectivity: `Test-NetConnection localhost -Port 13133`

### Common Exit Codes
- **1077**: Service disabled or not started since boot
- **1069**: Service failed to start due to logon failure
- **1053**: Service did not respond in timely fashion

## Configuration Examples

### SigNoz Backend
```yaml
exporters:
  otlp:
    endpoint: "http://localhost:4317"
    tls:
      insecure: true
```

### Remote Backend with TLS
```yaml
exporters:
  otlp:
    endpoint: "https://your-backend.com:4317"
    tls:
      insecure: false
      cert_file: "path/to/cert.pem"
      key_file: "path/to/key.pem"
```

## Recovery Actions

### Reset to Defaults
```powershell
Stop-Service otelcol-contrib
Remove-Item "C:\ProgramData\otelcol-contrib\config.yaml"
.\scripts\enable-windows-collector.ps1 -OtlpEndpoint "http://localhost:4317"
```

### View Logs
```powershell
Get-EventLog -LogName Application -Source "OpenTelemetry-Collector" -Newest 10
```

## Integration with BossCat

### Gate Readiness Check
```powershell
# Quick health verification
$health = Invoke-WebRequest -Uri "http://localhost:13133/healthz" -UseBasicParsing
if ($health.StatusCode -eq 200) {
    Write-Host "✅ Windows Collector: Healthy" -ForegroundColor Green
} else {
    Write-Host "❌ Windows Collector: Unhealthy" -ForegroundColor Red
}
```

### ECRR Reporting
- **Status**: Include in gate readiness reports
- **Evidence**: Health check results, service status
- **Artifacts**: Config backups, event logs
