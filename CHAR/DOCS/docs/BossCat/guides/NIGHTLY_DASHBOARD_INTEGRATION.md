# Nightly Dashboard Export Integration Guide

## Overview

The `scripts/nightly-dashboard-export.ps1` script provides automated SigNoz dashboard export capabilities that integrate with the BossCat gate verification pipeline. This script exports configured dashboards to PDF format and generates ECRR-compliant reports for executive review.

## Integration with BossCat Pipeline

### 1. **Sequencing with Performance Testing**

The nightly dashboard export should be executed **after** the BossCat gate verification pipeline completes successfully. This ensures that:

- Performance test results are reflected in the dashboards
- Synthetic traces and canary tests have been generated
- Gate verification reports are available for correlation

**Recommended Execution Order:**
```bash
# 1. Run BossCat gate verification pipeline
python scripts/run-local-pipeline.py --test-types baseline load stress soak

# 2. Wait for SigNoz to process all data (5-10 minutes)
sleep 600

# 3. Export dashboards with current data
pwsh scripts/nightly-dashboard-export.ps1 -SignozUrl "http://localhost:8080"
```

### 2. **Dashboard Configuration**

The script uses `scripts/dashboard-list.json` to define which dashboards to export. This file should include:

```json
{
  "dashboards": [
    {
      "name": "BossCat Performance Overview",
      "url": "/dashboard/bosscat-performance",
      "description": "k6 performance test results and thresholds"
    },
    {
      "name": "BossCat Gate Verification",
      "url": "/dashboard/bosscat-gates", 
      "description": "Gate verification status and synthetic traces"
    },
    {
      "name": "OTel Pipeline Health",
      "url": "/dashboard/otel-pipeline",
      "description": "OpenTelemetry collector and SigNoz health metrics"
    }
  ]
}
```

### 3. **Output Integration**

The script generates outputs that integrate with BossCat reporting:

- **PDF Exports**: `docs/observability/snapshots/YYYY-MM-DD/`
- **ECRR Reports**: `docs/ecrr/ECRR_REPORTS/`
- **Summary Logs**: Appended to `docs/BossCat/reports/BOSSCAT_LOG.md`

### 4. **GitHub Actions Integration**

The nightly dashboard export can be integrated into the GitHub Actions workflow:

```yaml
nightly-dashboard-export:
  runs-on: ubuntu-latest
  needs: [gate-verification]
  if: github.ref == 'refs/heads/main' && github.event_name == 'schedule'
  steps:
  - name: Checkout code
    uses: actions/checkout@v4
    
  - name: Setup PowerShell
    uses: actions/setup-powershell@v1
    
  - name: Export SigNoz Dashboards
    run: |
      pwsh scripts/nightly-dashboard-export.ps1 \
        -SignozUrl "http://localhost:8080" \
        -OutputRoot "docs/observability/snapshots" \
        -ReportDir "docs/ecrr/ECRR_REPORTS"
        
  - name: Upload Dashboard Exports
    uses: actions/upload-artifact@v3
    with:
      name: nightly-dashboard-exports
      path: docs/observability/snapshots/
```

## Usage Patterns

### **Local Development**
```bash
# Dry run to validate configuration
pwsh scripts/nightly-dashboard-export.ps1 -DryRun

# Full export with custom output directory
pwsh scripts/nightly-dashboard-export.ps1 \
  -SignozUrl "http://localhost:8080" \
  -OutputRoot "my-exports" \
  -ReportDir "my-reports"
```

### **CI/CD Integration**
```bash
# Automated nightly export
pwsh scripts/nightly-dashboard-export.ps1 \
  -SignozUrl "${{ env.SIGNOZ_URL }}" \
  -SignozSession "${{ secrets.SIGNOZ_SESSION }}" \
  -DashboardListPath "scripts/dashboard-list.json"
```

### **Production Monitoring**
```bash
# Production dashboard export with authentication
pwsh scripts/nightly-dashboard-export.ps1 \
  -SignozUrl "https://signoz.company.com" \
  -SignozSession "$SIGNOZ_SESSION_TOKEN" \
  -OutputRoot "docs/observability/snapshots" \
  -ReportDir "docs/ecrr/ECRR_REPORTS"
```

## Configuration Files

### **Dashboard List (`scripts/dashboard-list.json`)**
Defines which dashboards to export and their metadata:

```json
{
  "dashboards": [
    {
      "name": "BossCat Performance",
      "url": "/dashboard/bosscat-performance",
      "description": "Performance test results",
      "priority": "high",
      "timeRange": "1h"
    }
  ],
  "exportSettings": {
    "format": "pdf",
    "quality": "high",
    "timeout": 30000
  }
}
```

### **Environment Variables**
- `SIGNOZ_BROWSER_PATH`: Custom browser path for Edge
- `SIGNOZ_SESSION`: Session cookie for authentication
- `SIGNOZ_URL`: Base URL for SigNoz instance

## Error Handling and Monitoring

### **Common Issues**
1. **Browser Not Found**: Ensure Microsoft Edge is installed
2. **Authentication Failed**: Check session cookie validity
3. **Dashboard Not Found**: Verify dashboard URLs in configuration
4. **Timeout Errors**: Increase timeout settings for large dashboards

### **Monitoring Integration**
The script logs all operations to `docs/BossCat/reports/BOSSCAT_LOG.md` with:
- Export timestamps
- Success/failure status
- Error details
- Dashboard counts and file sizes

### **ECRR Compliance**
All exports include ECRR-compliant metadata:
- **Examine**: Dashboard state before export
- **Clean**: Error handling and retry logic
- **Report**: Export results and file locations
- **Role**: Automated export responsibility

## Best Practices

### **Scheduling**
- Run after BossCat gate verification completes
- Allow 5-10 minutes for SigNoz data processing
- Use consistent time ranges for dashboard exports
- Schedule during low-traffic periods

### **Storage Management**
- Implement retention policies for old exports
- Compress PDF files for long-term storage
- Monitor disk usage in export directories
- Archive exports older than 30 days

### **Security**
- Use secure session cookies for production
- Implement proper authentication for SigNoz access
- Secure export directories with appropriate permissions
- Log all access attempts for audit trails

## Troubleshooting

### **Debug Mode**
```bash
# Enable verbose logging
pwsh scripts/nightly-dashboard-export.ps1 -Verbose -DryRun
```

### **Common Solutions**
1. **Browser Issues**: Update Edge or use custom browser path
2. **Authentication**: Refresh session cookies
3. **Network Issues**: Check SigNoz connectivity and firewall rules
4. **Permission Issues**: Ensure write access to output directories

### **Log Analysis**
Check `docs/BossCat/reports/BOSSCAT_LOG.md` for:
- Export timestamps and durations
- Error messages and stack traces
- Dashboard access patterns
- File generation statistics

---

**Integration Status**: ✅ Ready for Production  
**Last Updated**: 2025-01-27  
**BossCat Compatibility**: Full integration with gate verification pipeline
