# Windows Collector Restart Instructions

## **Current Status**
- ✅ **config.yaml**: Updated with correct port mapping and resource defaults
- ✅ **verify-integration.ps1**: ASCII health script created
- ⚠️ **Collector Service**: Running but not listening on OTLP ports (5317/5318)
- ❌ **Integration**: Needs restart to load new configuration

## **Required Action: Elevated Restart**

The Windows OTel Collector service needs to be restarted with elevated privileges to load the new configuration.

### **Option 1: Run the restart script (Recommended)**

1. **Open PowerShell as Administrator**:
   - Right-click on PowerShell
   - Select "Run as Administrator"
   - Click "Yes" when prompted by UAC

2. **Navigate to the project directory**:
   ```powershell
   cd C:\otel
   ```

3. **Run the restart script**:
   ```powershell
   .\restart-collector.ps1
   ```

### **Option 2: Manual restart commands**

1. **Open PowerShell as Administrator**

2. **Run these commands**:
   ```powershell
   Restart-Service -Name otelcol-contrib -Force
   Start-Sleep -Seconds 5
   Get-Service otelcol-contrib
   ```

## **Verification Steps**

After restart, run the verification script:

```powershell
# In your regular PowerShell (not elevated)
cd C:\otel
.\verify-integration.ps1
```

**Expected Output**: All checks should show `[OK]`

## **What the Restart Will Fix**

- **Port Binding**: Collector will bind to 0.0.0.0:5317 and 0.0.0.0:5318
- **Resource Defaults**: Service will be tagged with `service.name=windows-otel-collector`
- **Retry Queue**: Proper retry and queue configuration will be active
- **Pipeline**: All three pipelines (traces, metrics, logs) will be operational

## **Troubleshooting**

If the restart fails:

1. **Check service logs**:
   ```powershell
   Get-EventLog -LogName Application -Source otelcol-contrib -Newest 10
   ```

2. **Check configuration**:
   ```powershell
   otelcol-contrib --config=config.yaml --dry-run
   ```

3. **Manual service control**:
   ```powershell
   Stop-Service otelcol-contrib -Force
   Start-Service otelcol-contrib
   ```

## **Success Criteria**

After successful restart and verification:

- ✅ **Ports**: 5317/5318 listening
- ✅ **Health**: `/healthz` endpoint responding
- ✅ **Metrics**: 8888 endpoint with OTEL metrics
- ✅ **OTLP**: Canary log successfully sent
- ✅ **SigNoz**: UI accessible and canary visible

## **Rollback (if needed)**

If issues occur, rollback with:

```powershell
git checkout -- config.yaml verify-integration.ps1
Restart-Service otelcol-contrib -Force
```


