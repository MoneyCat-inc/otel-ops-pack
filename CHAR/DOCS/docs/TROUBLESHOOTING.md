# 🚨 Troubleshooting Guide

Common issues and solutions for the OTel + Resonai observability stack.

## Quick Diagnostics

```powershell
# Run comprehensive health check
.\Test-ResonaiStack.ps1

# Check all services
Get-Service otelcol-contrib
wsl -e bash -lc "docker ps | grep signoz"
Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*next*" }
```

## Service Issues

### OTel Collector Not Running

**Symptoms**: Ports 14317/14318 not listening, canaries failing

**Solutions**:
```powershell
# Check service status
Get-Service otelcol-contrib

# Start service
Start-Service otelcol-contrib

# Check logs
Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 10

# Manual start (for debugging)
otelcol-contrib --config collector\otel-local.yaml
```

### SigNoz Not Accessible

**Symptoms**: http://localhost:8080 returns connection refused

**Solutions**:
```powershell
# Check Docker containers
wsl -e bash -lc "docker ps | grep signoz"

# Restart SigNoz
wsl -e bash -lc "cd ~/signoz/deploy && docker compose restart"

# Check WSL2 status
wsl --status
```

### Resonai Not Starting

**Symptoms**: Port 3003 not listening, pnpm errors

**Solutions**:
```powershell
# Navigate to correct directory
cd third_party\resonai

# Install dependencies
pnpm install

# Start dev server
pnpm dev

# Check for port conflicts
netstat -ano | findstr "3003"
```

## Port Conflicts

### Common Port Issues

| Port | Service | Common Conflicts |
|------|---------|------------------|
| 14317 | OTel gRPC | Other OTel instances |
| 14318 | OTel HTTP | Other OTel instances |
| 3003 | Resonai | Other Next.js apps |
| 8080 | SigNoz | Other web services |

### Resolution

```powershell
# Find what's using a port
netstat -ano | findstr "14317"

# Kill process by PID
taskkill /PID <PID> /F

# Change port in config if needed
# Edit collector/otel-local.yaml or next.config.js
```

## Audio/Microphone Issues

### Firefox AudioWorklet Problems

**Symptoms**: No mic prompt, audio not working, console errors

**Solutions**:
1. **Use localhost**: Ensure you're on http://localhost:3003 (not 127.0.0.1)
2. **Check permissions**: Firefox → Settings → Privacy → Permissions → Microphone
3. **Close other tabs**: Other apps might be holding the mic
4. **Check COOP/COEP**: Look for `window.crossOriginIsolated` in console

### Cross-Origin Isolation

**Symptoms**: `SharedArrayBuffer` errors, AudioWorklet not working

**Solutions**:
```javascript
// Add to next.config.js
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Cross-Origin-Embedder-Policy',
            value: 'require-corp',
          },
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin',
          },
        ],
      },
    ]
  },
}
```

## Network Issues

### OTLP Canaries Failing

**Symptoms**: POST to http://localhost:14318/v1/logs fails

**Solutions**:
```powershell
# Test collector endpoint
Test-NetConnection -ComputerName localhost -Port 14318

# Check collector logs
Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 5

# Verify config
Get-Content collector\otel-local.yaml
```

### SigNoz Not Receiving Data

**Symptoms**: No logs appear in SigNoz UI

**Solutions**:
1. **Check collector config**: Ensure exporter points to correct SigNoz port
2. **Verify SigNoz OTLP receiver**: Check if port 4317 is listening
3. **Test with canary**: Send test data and verify it appears
4. **Check logs**: Look for collector export errors

## Performance Issues

### High Latency

**Symptoms**: Slow audio processing, delayed feedback

**Solutions**:
1. **Check CPU usage**: Monitor system resources
2. **Optimize audio settings**: Reduce sample rate, buffer size
3. **Check network**: Ensure localhost communication is fast
4. **Profile code**: Use browser dev tools to identify bottlenecks

### Memory Issues

**Symptoms**: Browser crashes, slow performance

**Solutions**:
1. **Close unused tabs**: Free up browser memory
2. **Restart services**: Clear accumulated state
3. **Check for leaks**: Monitor memory usage over time
4. **Optimize audio processing**: Reduce buffer sizes

## Development Issues

### Hot Reload Not Working

**Symptoms**: Changes not reflected in browser

**Solutions**:
```powershell
# Restart dev server
cd third_party\resonai
pnpm dev

# Clear cache
rm -rf .next
pnpm dev
```

### Environment Variables Not Loading

**Symptoms**: OTel config not applied

**Solutions**:
1. **Check .env.local**: Ensure file exists and has correct format
2. **Restart dev server**: Environment variables loaded on startup
3. **Verify syntax**: No spaces around =, proper quoting
4. **Check precedence**: .env.local overrides other env files

## Log Analysis

### SigNoz Query Examples

**Find errors**:
```
severity = "ERROR" AND service.name = "resonai-local"
```

**Track user sessions**:
```
message contains "session" AND service.name = "resonai-local"
```

**Monitor performance**:
```
service.name = "resonai-local" | rate(5m) | top(10)
```

### Windows Event Logs

**Application logs**:
```powershell
Get-EventLog -LogName Application -Newest 10
```

**System logs**:
```powershell
Get-EventLog -LogName System -Newest 10
```

## Recovery Procedures

### Full Stack Restart

```powershell
# Stop all services
Stop-Service otelcol-contrib
wsl -e bash -lc "cd ~/signoz/deploy && docker compose down"
Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*next*" } | Stop-Process

# Start all services
Start-Service otelcol-contrib
wsl -e bash -lc "cd ~/signoz/deploy && docker compose up -d"
cd third_party\resonai
pnpm dev

# Verify
.\Test-ResonaiStack.ps1
```

### Reset Configuration

```powershell
# Reset OTel config
git checkout collector\otel-local.yaml

# Reset Resonai env
Remove-Item third_party\resonai\.env.local
# Recreate with correct values

# Restart services
# (Use full stack restart above)
```

## Getting Help

1. **Check logs**: Always start with service logs
2. **Run diagnostics**: Use `.\Test-ResonaiStack.ps1`
3. **Verify configs**: Ensure all config files are correct
4. **Test components**: Isolate which service is failing
5. **Document issues**: Note exact error messages and steps to reproduce

## Prevention

1. **Regular health checks**: Run diagnostics periodically
2. **Monitor resources**: Watch CPU, memory, disk usage
3. **Keep services updated**: Regular updates prevent issues
4. **Backup configs**: Version control all configuration files
5. **Test changes**: Verify after any configuration changes



