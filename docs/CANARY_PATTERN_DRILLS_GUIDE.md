# Canary Log Pattern Drills Guide

## Overview

The Canary Log Pattern Drills system provides comprehensive testing capabilities for the observability pipeline using realistic log patterns and scenarios. This system helps validate the pipeline's ability to handle various log formats, volumes, and patterns while ensuring proper ingestion, processing, and alerting.

## System Components

### 1. Pattern Library (`scripts/canary-pattern-library.ps1`)
A comprehensive library of predefined log patterns organized by category:

- **Application Logs**: Web server access logs, error logs, database queries
- **Security Logs**: Authentication attempts, authorization events, intrusion detection
- **Performance Logs**: System metrics, application metrics, slow operations
- **Business Logs**: Payment transactions, order processing, user activity

### 2. Pattern Drills (`scripts/canary-pattern-drills.ps1`)
Automated drill execution for specific pattern types:

- **Error Patterns**: Application errors, database failures, authentication issues
- **Performance Patterns**: System metrics, response times, resource usage
- **Format Variations**: JSON, plain text, key-value pairs, CSV
- **Volume Spikes**: Burst patterns, high-volume scenarios
- **Edge Cases**: Unicode, special characters, malformed data
- **Multiline Patterns**: Stack traces, JSON multiline, XML content

### 3. Scenario Execution (`scripts/execute-pattern-drills.ps1`)
Realistic scenario-based testing:

- **Web Application**: Complete web application log simulation
- **Microservices**: Service-to-service communication patterns
- **Security Incident**: Security event simulation
- **Performance Degradation**: Gradual performance decline simulation
- **Business Transaction**: E-commerce transaction patterns
- **Mixed Workload**: Combined patterns from all categories

### 4. Testing Framework (`scripts/test-pattern-drills.ps1`)
Comprehensive testing and verification:

- **Pipeline Health**: SigNoz and collector health checks
- **Drill Execution**: Automated drill testing
- **Scenario Testing**: Scenario execution validation
- **SigNoz Verification**: Data ingestion verification
- **Report Generation**: Detailed test reports

## Usage Examples

### Quick Pattern Drill
```powershell
# Run error pattern drill for 60 seconds
.\scripts\canary-pattern-drills.ps1 -DrillType "error-patterns" -Duration 60 -Intensity "medium"

# Run all pattern drills
.\scripts\canary-pattern-drills.ps1 -DrillType "all" -Duration 120 -Intensity "high"
```

### Scenario-Based Testing
```powershell
# Test web application scenario
.\scripts\execute-pattern-drills.ps1 -Scenario "web-application" -Duration 5 -Intensity "medium"

# Test all scenarios
.\scripts\execute-pattern-drills.ps1 -Scenario "all" -Duration 10 -Intensity "high"
```

### Comprehensive Testing
```powershell
# Run comprehensive test suite
.\scripts\test-pattern-drills.ps1 -TestType "comprehensive"

# Quick verification test
.\scripts\test-pattern-drills.ps1 -TestType "quick" -DrillType "error-patterns"
```

## Drill Types

### Error Pattern Drills
**Purpose**: Test error handling and logging patterns
**Patterns**:
- Application Errors: Module failures, error codes, detailed messages
- Database Connection Errors: Connection timeouts, authentication failures
- Authentication Failures: Invalid credentials, brute force attempts
- Resource Exhaustion: Memory, CPU, disk usage alerts

**Example Output**:
```json
{
  "timestamp": "2024-01-01T10:00:00.000Z",
  "level": "ERROR",
  "message": "ERROR: Application failure in module auth-service - AUTH_001: Invalid credentials",
  "service": "error-pattern-drill",
  "drill_id": "drill-20240101-100000",
  "pattern_name": "Application Errors"
}
```

### Performance Pattern Drills
**Purpose**: Test performance monitoring and metrics collection
**Patterns**:
- System Metrics: CPU, memory, disk, network usage
- Application Metrics: Request rates, response times, error rates
- Slow Operations: Database queries, API calls, file processing

**Example Output**:
```json
{
  "timestamp": "2024-01-01T10:00:00.000Z",
  "level": "INFO",
  "message": "Performance metrics: response_time=45ms, cpu=67%, memory=89%, disk=23%",
  "service": "performance-pattern-drill",
  "metrics": {
    "response_time_ms": 45,
    "cpu_usage_percent": 67,
    "memory_usage_percent": 89,
    "disk_usage_percent": 23
  }
}
```

### Format Variation Drills
**Purpose**: Test different log format handling
**Formats**:
- JSON Structured: Nested JSON with metadata
- Plain Text: Traditional log format
- Key-Value Pairs: Structured key-value format
- CSV Format: Comma-separated values

**Example Outputs**:
```json
// JSON Structured
{
  "timestamp": "2024-01-01T10:00:00.000Z",
  "level": "INFO",
  "message": "Structured JSON log entry",
  "structured_data": {
    "user_id": "12345",
    "session_id": "sess_abc123",
    "action": "login"
  }
}

// Plain Text
2024-01-01 10:00:00 [INFO] Plain text log entry - service=format-drill drill_id=drill-123

// Key-Value Pairs
timestamp=2024-01-01T10:00:00.000Z level=INFO message='Key-value log entry' service=format-drill

// CSV Format
2024-01-01T10:00:00.000Z,INFO,CSV log entry,format-drill,drill-123,field1,field2,field3
```

### Volume Spike Drills
**Purpose**: Test high-volume log ingestion
**Patterns**:
- Burst Patterns: High-rate bursts followed by normal rates
- Sustained High Volume: Continuous high-rate logging
- Gradual Increase: Gradually increasing log volume

**Example Burst Pattern**:
```
Burst 1: 100 logs/sec for 10 seconds
Normal: 20 logs/sec for 20 seconds  
Burst 2: 200 logs/sec for 5 seconds
Elevated: 30 logs/sec for 15 seconds
Burst 3: 150 logs/sec for 8 seconds
```

### Edge Case Drills
**Purpose**: Test handling of unusual or problematic data
**Cases**:
- Unicode Characters: International characters and emojis
- Very Long Messages: Messages exceeding typical limits
- Empty Fields: Null or empty values
- Special Characters: Control characters and symbols
- Nested JSON: Deeply nested JSON structures
- SQL Injection Attempts: Malicious payloads
- XML Content: XML-formatted data

**Example Edge Cases**:
```json
// Unicode
{
  "message": "Unicode test: 你好世界 🌍 émojis 🚀 special chars: àáâãäåæçèéêë"
}

// Very Long Message
{
  "message": "Very long message: " + ("x" * 1000) + " - This is a test..."
}

// Special Characters
{
  "message": "Special chars: \n\r\t\"'`~!@#$%^&*()_+-=[]{}|;':\",./<>?"
}

// SQL Injection
{
  "message": "SELECT * FROM users WHERE id = 1; DROP TABLE users; --"
}
```

### Multiline Pattern Drills
**Purpose**: Test multiline log handling
**Patterns**:
- Stack Traces: Exception stack traces
- JSON Multiline: JSON spanning multiple lines
- Log Continuation: Logs with continuation lines
- XML Multiline: XML content across lines

**Example Multiline Patterns**:
```
// Stack Trace
Exception: System.NullReferenceException
   at MyApp.Services.UserService.GetUser(Int32 userId)
   at MyApp.Controllers.UserController.GetUser(Int32 id)
   at System.Web.Mvc.ControllerActionInvoker.InvokeActionMethod

// JSON Multiline
{
  "timestamp": "2024-01-01T10:00:00.000Z",
  "level": "ERROR",
  "message": "Multiline JSON log entry",
  "details": {
    "error": "Something went wrong",
    "stack_trace": [
      "line 1 of stack",
      "line 2 of stack"
    ]
  }
}
```

## Scenario Types

### Web Application Scenario
**Simulates**: Complete web application environment
**Patterns**: Access logs, error logs, performance metrics, slow operations
**Duration**: 5 minutes (configurable)
**Intensity**: Low/Medium/High (configurable)

### Microservices Scenario
**Simulates**: Microservices architecture
**Patterns**: Service calls, circuit breakers, database queries, connections
**Duration**: 5 minutes (configurable)
**Intensity**: Low/Medium/High (configurable)

### Security Incident Scenario
**Simulates**: Security event detection
**Patterns**: Login attempts, authorization events, suspicious activity
**Duration**: 5 minutes (configurable)
**Intensity**: Low/Medium/High (configurable)

### Performance Degradation Scenario
**Simulates**: Gradual performance decline
**Patterns**: System metrics, application metrics, slow operations
**Duration**: 5 minutes (configurable)
**Intensity**: Low/Medium/High (configurable)

### Business Transaction Scenario
**Simulates**: E-commerce transactions
**Patterns**: Payment processing, order management, user activity
**Duration**: 5 minutes (configurable)
**Intensity**: Low/Medium/High (configurable)

### Mixed Workload Scenario
**Simulates**: Combined workload from all categories
**Patterns**: All available patterns randomly selected
**Duration**: 5 minutes (configurable)
**Intensity**: Low/Medium/High (configurable)

## Testing Framework

### Test Types

#### Quick Test
- Pipeline health check
- Pattern library validation
- Single drill execution
- Basic verification

#### Comprehensive Test
- Full pipeline health check
- All drill types execution
- All scenario types execution
- Complete SigNoz verification
- Detailed reporting

#### Verification-Only Test
- Check existing data in SigNoz
- Verify drill results
- No new data generation
- Quick validation

### Test Results

#### Pipeline Health
- SigNoz health status
- Collector health status
- Log ingestion capability
- Trace ingestion capability
- Metrics collection status

#### Drill Execution
- Success/failure status
- Execution time
- Exit codes
- Error messages

#### SigNoz Verification
- Log search results
- Trace search results
- Metrics query results
- Alert configuration status

## Configuration

### Intensity Levels
- **Low**: 1x multiplier, slower execution
- **Medium**: 3x multiplier, normal execution
- **High**: 5x multiplier, faster execution

### Duration Settings
- **Drill Duration**: 30-300 seconds per drill
- **Scenario Duration**: 1-15 minutes per scenario
- **Test Duration**: Varies by test type

### Output Configuration
- **Log Directory**: `C:\logs`
- **Artifacts Directory**: `artifacts`
- **Report Generation**: JSON format
- **Verification**: SigNoz UI integration

## Verification in SigNoz

### Log Queries
```sql
-- Error pattern drill results
message contains 'error-pattern-drill'

-- Performance pattern drill results  
message contains 'performance-pattern-drill'

-- Web application scenario results
message contains 'web-application-scenario'

-- All drill results
message contains 'drill' OR message contains 'scenario'
```

### Trace Queries
```sql
-- Pattern drill traces
service.name = 'pattern-drill-scenario'

-- Canary test traces
service.name = 'canary-test'
```

### Metrics Queries
```sql
-- System metrics
otelcol_process_memory_rss
otelcol_process_cpu_seconds

-- Queue metrics
otelcol_exporter_queue_size
otelcol_exporter_queue_capacity
```

## Troubleshooting

### Common Issues

#### Script Execution Errors
- **PowerShell Version**: Requires PowerShell 7.0+
- **Permissions**: May require elevated privileges
- **Path Issues**: Ensure scripts are in correct location

#### SigNoz Connection Issues
- **Service Status**: Check SigNoz is running on localhost:8080
- **Network**: Verify localhost connectivity
- **API Endpoints**: Check API endpoint availability

#### Pattern Generation Issues
- **Pattern Library**: Ensure pattern library is loaded
- **Memory**: Large pattern generation may require more memory
- **File Permissions**: Check write permissions for log files

#### Verification Failures
- **Data Ingestion**: Verify logs are being ingested
- **Query Syntax**: Check SigNoz query syntax
- **Time Ranges**: Ensure appropriate time ranges
- **Data Availability**: Check if data exists in time range

### Debugging Steps

1. **Check Pipeline Health**:
   ```powershell
   .\scripts\test-pattern-drills.ps1 -TestType "verification-only"
   ```

2. **Verify SigNoz Status**:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health"
   ```

3. **Check Collector Status**:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:13134/healthz"
   ```

4. **Test Pattern Library**:
   ```powershell
   .\scripts\canary-pattern-library.ps1
   ```

5. **Run Simple Drill**:
   ```powershell
   .\scripts\canary-pattern-drills.ps1 -DrillType "error-patterns" -Duration 30 -Intensity "low"
   ```

## Best Practices

### Regular Testing
- Run quick tests daily
- Run comprehensive tests weekly
- Run scenario tests before deployments
- Monitor test results and trends

### Test Data Management
- Clean up test log files regularly
- Monitor disk space usage
- Archive test results for analysis
- Maintain test data retention policies

### Performance Monitoring
- Monitor drill execution times
- Track SigNoz ingestion rates
- Monitor system resource usage
- Set up alerts for test failures

### Documentation
- Document custom patterns
- Maintain test scenarios
- Update verification procedures
- Share test results with team

## Integration

### CI/CD Integration
```yaml
# Example GitHub Actions workflow
- name: Run Pattern Drills
  run: |
    pwsh -File scripts/test-pattern-drills.ps1 -TestType "quick"
    
- name: Run Comprehensive Tests
  run: |
    pwsh -File scripts/test-pattern-drills.ps1 -TestType "comprehensive"
```

### Monitoring Integration
- Integrate with existing monitoring systems
- Set up alerts for test failures
- Monitor test execution metrics
- Track test result trends

### Reporting Integration
- Generate test reports for stakeholders
- Integrate with documentation systems
- Share results with operations teams
- Maintain test result history

## Files Created

```
scripts/canary-pattern-library.ps1          # Pattern library
scripts/canary-pattern-drills.ps1            # Pattern drills
scripts/execute-pattern-drills.ps1           # Scenario execution
scripts/test-pattern-drills.ps1              # Testing framework
docs/CANARY_PATTERN_DRILLS_GUIDE.md         # This documentation
artifacts/canary-pattern-library.json        # Exported pattern library
artifacts/pattern-drill-*.json               # Test results
artifacts/pattern-drill-test-report-*.json   # Test reports
```

## Related Documentation

- [SigNoz UI Setup Guide](SIGNOZ_UI_SETUP_GUIDE.md)
- [Monitoring Setup Guide](MONITORING_SETUP_GUIDE.md)
- [OTel Collector Configuration](config.yaml)
- [Canary Test Documentation](canary-test.ps1)

## Support

For issues with pattern drills:
1. Check pipeline health: Run verification-only test
2. Verify SigNoz status: Check health endpoints
3. Review test logs: Check artifacts directory
4. Run simple drill: Test basic functionality
5. Check documentation: Review this guide

---

**Last Updated**: 2025-09-24  
**Version**: 1.0.0  
**Status**: Production Ready
