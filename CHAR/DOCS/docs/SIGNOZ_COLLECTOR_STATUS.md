# SigNoz Collector Status & Configuration

## Current State: ✅ Production Ready

**Last Updated**: 2025-09-29  
**SigNoz Version**: v0.129.6  
**Configuration Schema**: 0.129 compliant  

## ✅ Working Components

### Active Pipelines
- **✅ Traces Pipeline**: OTLP → Resource detection → Span metrics (delta) → ClickHouse
- **✅ Metrics Pipeline**: OTLP + Host metrics + Prometheus scrape → ClickHouse + Prometheus export
- **⏸️ Logs Pipeline**: Intentionally disabled (see `LOGS_STRATEGY_OPTIONS.md`)

### Endpoints
- **OTLP gRPC**: `localhost:14317` ✅
- **OTLP HTTP**: `localhost:14318` ✅  
- **Prometheus Metrics**: `localhost:18889` ✅
- **Health Check**: `localhost:13133` ✅

### Prometheus Scrape Targets
- **✅ signoz-otel-collector**: `localhost:8889/metrics` (collector's own metrics)

## Configuration Files

### `signoz-collector-config.yaml`
- **Hostmetrics**: Simplified scrapers (`cpu: {}`, `memory: {}`, etc.)
- **ClickHouse Exporters**: DSN format (`tcp://signoz-clickhouse:9000/signoz_*`)
- **Span Metrics**: Delta aggregation with comprehensive dimensions
- **Resource Detection**: Environment and system attributes

### `docker-compose-signoz.yml`
- **JWT Secret**: `SIGNOZ_JWT_SECRET` environment variable
- **Health Check**: TCP probe (`bash -c 'exec 3<>/dev/tcp/localhost/13133'`)
- **Port Mapping**: 14317/14318 for OTLP, 18888/18889 for metrics

## Monitoring Commands

### Health Check
```powershell
# Service status
docker compose -f docker-compose-signoz.yml ps signoz-otel-collector

# OTLP endpoint test
Test-NetConnection -ComputerName 127.0.0.1 -Port 14318

# Collector logs
docker logs signoz-otel-collector --tail 10
```

### SigNoz UI Access
- **URL**: http://localhost:8080
- **Collectors Status**: Home → Status → Collectors
- **Traces Query**: `signoz_traces.distributed_traces` (sort by timestamp desc)
- **Metrics Query**: `otelcol_*` for pipeline metrics

## Future Enhancements

### 1. Logs Pipeline Re-enablement
- **Status**: Paused due to ClickHouse schema mismatch
- **Action**: Follow `docs/LOGS_STRATEGY_OPTIONS.md`
- **Error**: `clickhouse: expected 3 arguments, got 2`

### 2. Additional Prometheus Targets
- **Current**: Only collector self-metrics
- **Potential**: Add backend services, databases, or custom applications
- **Example**: `resonai-backend:3000/metrics` (when service is running)

### 3. Alerting & Dashboards
- **Current**: Basic SigNoz UI
- **Enhancement**: Custom dashboards for collector health
- **Alerts**: Pipeline failures, high error rates, resource usage

## Troubleshooting

### Common Issues
1. **Port Conflicts**: Ensure 14317/14318 are not used by other services
2. **Schema Mismatches**: Check ClickHouse table schemas for compatibility
3. **Resource Limits**: Monitor memory usage with `memory_limiter` processor
4. **Network Issues**: Verify Docker network connectivity between containers

### Log Locations
- **Collector Logs**: `docker logs signoz-otel-collector`
- **SigNoz UI Logs**: `docker logs signoz`
- **ClickHouse Logs**: `docker logs signoz-clickhouse`

## Maintenance Schedule

### Daily
- Check collector health status
- Monitor error rates in logs
- Verify OTLP endpoint accessibility

### Weekly  
- Review Prometheus scrape targets
- Check ClickHouse storage usage
- Update documentation if configuration changes

### Monthly
- Evaluate logs pipeline re-enablement
- Review performance metrics
- Consider additional monitoring targets

## Success Criteria

✅ **Collector Health**: `Up (healthy)` status  
✅ **OTLP Endpoints**: Both gRPC and HTTP responding  
✅ **Clean Logs**: No warnings or errors  
✅ **Prometheus Scrape**: Working without failures  
✅ **Schema Compliance**: 0.129 format throughout  

**Status**: 🟢 **OPERATIONAL** - Ready for production telemetry ingestion
