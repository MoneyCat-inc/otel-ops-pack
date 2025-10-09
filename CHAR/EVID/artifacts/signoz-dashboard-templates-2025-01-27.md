# SigNoz Dashboard Configuration Templates
**Date**: 2025-01-27  
**Time**: 16:50 UTC  
**Purpose**: Ready-to-use dashboard configurations for SigNoz

## 📊 **Dashboard Templates**

### **Template 1: System Health Dashboard**
`json
{
  "dashboard": {
    "title": "Observability Pipeline Health",
    "description": "Core system health monitoring",
    "panels": [
      {
        "title": "Windows Collector Status",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "up{job=\"otelcol-contrib\"}",
            "legendFormat": "Collector Status"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            }
          }
        }
      },
      {
        "title": "SigNoz Container Health",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [
          {
            "expr": "up{job=\"signoz\"}",
            "legendFormat": "SigNoz Status"
          }
        ]
      },
      {
        "title": "Log Ingestion Rate",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "rate(otelcol_receiver_accepted_log_records[5m])",
            "legendFormat": "Logs/sec"
          }
        ]
      },
      {
        "title": "Canary Generation Success",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "rate(otelcol_receiver_accepted_log_records{source=\"canary\"}[5m])",
            "legendFormat": "Canary Events/sec"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 6, "y": 8},
        "targets": [
          {
            "expr": "rate(otelcol_receiver_refused_log_records[5m])",
            "legendFormat": "Errors/sec"
          }
        ]
      }
    ],
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    }
  }
}
`

### **Template 2: Performance Metrics Dashboard**
`json
{
  "dashboard": {
    "title": "Performance Metrics",
    "description": "System performance monitoring",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(process_cpu_seconds_total[5m]) * 100",
            "legendFormat": "CPU %"
          }
        ],
        "yAxes": [
          {
            "max": 100,
            "min": 0,
            "unit": "percent"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "process_resident_memory_bytes / 1024 / 1024",
            "legendFormat": "Memory MB"
          }
        ],
        "yAxes": [
          {
            "unit": "MB"
          }
        ]
      },
      {
        "title": "Network I/O",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "rate(otelcol_exporter_sent_log_records[5m])",
            "legendFormat": "Sent Logs/sec"
          }
        ]
      },
      {
        "title": "Disk I/O",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "rate(otelcol_receiver_accepted_log_records[5m])",
            "legendFormat": "Processed Logs/sec"
          }
        ]
      }
    ],
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    }
  }
}
`

### **Template 3: Application Metrics Dashboard**
`json
{
  "dashboard": {
    "title": "Application Metrics",
    "description": "Application-specific monitoring",
    "panels": [
      {
        "title": "Service Worker Status",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "service_worker_supported",
            "legendFormat": "SW Supported"
          }
        ]
      },
      {
        "title": "Cross-Origin Isolation",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [
          {
            "expr": "cross_origin_isolated",
            "legendFormat": "COI Status"
          }
        ]
      },
      {
        "title": "Audio Latency",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "audio_latency_p50",
            "legendFormat": "P50 Latency"
          },
          {
            "expr": "audio_latency_p90",
            "legendFormat": "P90 Latency"
          },
          {
            "expr": "audio_latency_p99",
            "legendFormat": "P99 Latency"
          }
        ],
        "yAxes": [
          {
            "unit": "ms"
          }
        ]
      },
      {
        "title": "WASM Heap Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "wasm_heap_used_bytes",
            "legendFormat": "Heap Used"
          },
          {
            "expr": "wasm_heap_total_bytes",
            "legendFormat": "Heap Total"
          }
        ],
        "yAxes": [
          {
            "unit": "bytes"
          }
        ]
      },
      {
        "title": "SharedArrayBuffer Usage",
        "type": "stat",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "shared_array_buffer_available",
            "legendFormat": "SAB Available"
          }
        ]
      }
    ],
    "refresh": "5s",
    "time": {
      "from": "now-1h",
      "to": "now"
    }
  }
}
`

## 🚨 **Alert Configuration Templates**

### **Critical Alerts**
`json
{
  "alerts": [
    {
      "name": "Windows Collector Down",
      "condition": "up{job=\"otelcol-contrib\"} == 0",
      "duration": "0m",
      "severity": "critical",
      "notifications": ["email", "slack"],
      "message": "Windows Collector service is down. Immediate action required."
    },
    {
      "name": "SigNoz Container Unhealthy",
      "condition": "up{job=\"signoz\"} == 0",
      "duration": "0m",
      "severity": "critical",
      "notifications": ["email", "slack"],
      "message": "SigNoz container is unhealthy. Check Docker status."
    },
    {
      "name": "OTLP Pipeline Failure",
      "condition": "rate(otelcol_receiver_accepted_log_records[5m]) == 0",
      "duration": "5m",
      "severity": "critical",
      "notifications": ["email", "slack"],
      "message": "No logs ingested for 5 minutes. Check OTLP pipeline."
    }
  ]
}
`

### **Warning Alerts**
`json
{
  "alerts": [
    {
      "name": "High CPU Usage",
      "condition": "rate(process_cpu_seconds_total[5m]) * 100 > 80",
      "duration": "5m",
      "severity": "warning",
      "notifications": ["slack"],
      "message": "CPU usage above 80% for 5 minutes."
    },
    {
      "name": "Memory Leak Detection",
      "condition": "increase(process_resident_memory_bytes[1h]) > 0.1",
      "duration": "1h",
      "severity": "warning",
      "notifications": ["slack"],
      "message": "Memory usage increasing significantly."
    },
    {
      "name": "Service Worker Registration Failed",
      "condition": "service_worker_registration_success_rate < 0.95",
      "duration": "10m",
      "severity": "warning",
      "notifications": ["slack"],
      "message": "Service Worker registration success rate below 95%."
    },
    {
      "name": "Cross-Origin Isolation Lost",
      "condition": "cross_origin_isolated == 0",
      "duration": "0m",
      "severity": "warning",
      "notifications": ["slack"],
      "message": "Cross-origin isolation lost. Check COOP/COEP headers."
    },
    {
      "name": "Audio Latency Degradation",
      "condition": "audio_latency_p90 > 200",
      "duration": "2m",
      "severity": "warning",
      "notifications": ["slack"],
      "message": "Audio latency P90 above 200ms."
    }
  ]
}
`

## 🔧 **Implementation Instructions**

### **Dashboard Import**
1. **Access SigNoz**: Navigate to http://localhost:8080
2. **Go to Dashboards**: Click "Dashboards" in sidebar
3. **Import Dashboard**: Click "Import" button
4. **Paste JSON**: Copy and paste dashboard JSON
5. **Configure**: Adjust queries and settings as needed
6. **Save**: Save the dashboard

### **Alert Configuration**
1. **Access Alerts**: Navigate to "Alerts" section
2. **Create Alert**: Click "New Alert" button
3. **Configure Condition**: Set up alert condition
4. **Set Thresholds**: Configure severity and duration
5. **Add Notifications**: Set up notification channels
6. **Test Alert**: Trigger test to verify functionality

### **Customization**
- **Adjust Queries**: Modify PromQL queries for your specific metrics
- **Change Thresholds**: Adjust alert thresholds based on your needs
- **Add Panels**: Add more panels for additional metrics
- **Configure Refresh**: Set appropriate refresh rates
- **Set Time Ranges**: Configure default time ranges

---
**Templates Generated**: 2025-01-27 16:50 UTC  
**Status**: Ready for import and configuration  
**Next**: Import dashboards and configure alerts in SigNoz
