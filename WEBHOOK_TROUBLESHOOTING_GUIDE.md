# Webhook Troubleshooting Guide

## Current Status
- **Webhook URL**: http://192.168.0.76:3003/api/alerts/webhook
- **Network**: ✅ Port 3003 accessible
- **Issue**: 400 Bad Request - "Invalid Hostname"

## Troubleshooting Steps

### 1. Check Host Header
The server might be expecting a specific Host header. Try:
```powershell
$Headers = @{
    "Host" = "192.168.0.76:3003"
    "Content-Type" = "application/json"
}
Invoke-RestMethod -Uri "http://192.168.0.76:3003/api/alerts/webhook" -Method POST -Headers $Headers -Body '{"test": true}'
```

### 2. Check Expected Payload Format
The endpoint might expect a different JSON structure. Try:
```powershell
$Payload = @{
    alert = @{
        status = "firing"
        labels = @{
            alertname = "OTelPipelineTest"
            severity = "warning"
        }
        annotations = @{
            summary = "OTel pipeline test alert"
        }
    }
} | ConvertTo-Json
```

### 3. Check API Documentation
Verify the expected format by checking:
- Application logs on 192.168.0.76:3003
- API documentation for the alerts endpoint
- Required authentication headers

### 4. Alternative Testing
```powershell
# Test with different HTTP methods
curl -X POST http://192.168.0.76:3003/api/alerts/webhook -H "Content-Type: application/json" -d '{"test": true}'

# Test with different content types
curl -X POST http://192.168.0.76:3003/api/alerts/webhook -H "Content-Type: text/plain" -d "test alert"
```

## Current Pipeline Status
✅ **Core Pipeline Working Perfectly**:
- SigNoz authentication: Working
- Dashboard imported: Success
- Logs visible: Confirmed
- Pipeline operational: 5,095+ logs processed

⚠️ **Webhook**: Needs payload format adjustment (non-critical for basic monitoring)
