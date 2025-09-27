# SigNoz Query Recipes for OTel Monitoring
## Queue Pressure Monitoring
### Queue Utilization Ratio
```promql
otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100
```
**Description**: Shows queue utilization as a percentage. Values > 80% indicate high pressure.
