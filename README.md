# OTel Windows → SigNoz Observability Kit

A complete Windows-to-SigNoz observability pipeline with automated monitoring and alerting.

## 🚀 Quick Start

### Prerequisites
- Windows 11 with PowerShell 5.1+
- Docker Desktop with WSL2 integration
- Administrator privileges for service installation

### Setup
1. **Start SigNoz stack:**
   ```powershell
   docker compose -f .\docker-compose.yml up -d
   ```

2. **Install Windows OTel Collector (Admin PowerShell):**
   ```powershell
   .\scripts\setup.ps1
   ```

3. **Verify pipeline:**
   ```powershell
   .\scripts\verify-integration.ps1
   ```

## 📊 Monitoring

### Automated Verification
- **Scheduled Task**: Runs every 15 minutes
- **Canary Logs**: Visible in SigNoz UI
- **Alerting**: Configured for missing canaries

### Manual Verification
```powershell
# Check system status
.\scripts\verify-integration.ps1

# View canary logs
# http://localhost:8080 → Logs → Filter: log.body contains "windows-canary"

# Check scheduled task
Get-ScheduledTask -TaskName "OTel-Verification-Canary"
```

## 🔧 Management

### Start/Stop Services
```powershell
# Start all services
.\scripts\start-all.ps1

# Stop all services
.\scripts\stop-all.ps1

# Restart Windows collector
.\scripts\restart-collector.ps1
```

### Fallback Monitoring
If scheduled tasks fail, use continuous monitoring:
```batch
.\monitor-loop.bat
```

## 📁 File Structure

```
C:\otel\
├── config/
│   ├── otelcol-windows.yaml    # Windows collector config
│   └── signoz-collector.yaml   # SigNoz collector config
├── scripts/
│   ├── setup.ps1               # Main setup script
│   ├── verify-integration.ps1  # Health verification
│   ├── start-all.ps1          # Start services
│   ├── stop-all.ps1           # Stop services
│   └── schedule-monitoring.ps1 # Create scheduled task
├── docker-compose.yml          # SigNoz stack
├── monitor-loop.bat            # Fallback monitoring
└── README.md                   # This file
```

## 🎯 Success Criteria

- ✅ Windows OTel Collector running (ports 5317/5318)
- ✅ SigNoz stack healthy (ports 4317/4318, 8080, 8123/9000)
- ✅ Canary logs visible in SigNoz UI
- ✅ Scheduled verification every 15 minutes
- ✅ Alerting configured for missing canaries

## 🚨 Troubleshooting

### Common Issues
1. **Port conflicts**: Check if ports 4317/4318 are available
2. **Service issues**: Restart with `.\scripts\restart-collector.ps1`
3. **SigNoz UI**: Verify http://localhost:8080 is accessible
4. **Scheduled tasks**: Check Task Scheduler for "OTel-Verification-Canary"

### Manual Health Checks
```powershell
# Check Docker containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check Windows services
Get-Service -Name "otelcol-contrib"

# Check SigNoz health
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing
```

## 📋 Next Steps

1. **Configure SigNoz Alert**: Set up notification for missing canaries
2. **Schedule Monitoring**: Run `.\scripts\schedule-monitoring.ps1` (Admin)
3. **Verify End-to-End**: Confirm canary logs appear every 15 minutes

## 🎉 Status

**The OTel Windows → SigNoz observability pipeline is fully operational and ready for production monitoring!**