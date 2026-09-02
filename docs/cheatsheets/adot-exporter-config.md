# ADOT Exporter Configuration Guide

> ## UNBUILT — companion to the never-implemented ADOT lane (2025-10-15)
>
> References `.aws/adot-collector-config.yaml`, a `deployment/resonai-otel-collector` manifest and
> `base/` / `overlays/aws-prod/` config trees that do not exist, and a "Phase 3: SigNoz decommissioned"
> cutover that `docs/PURPOSE.md` rules out. The exporter trade-off table is generic guidance; nothing in
> this repository consumes it. Kept as the record of the design.

**Quick Reference**: How to configure trace exporters to avoid dual egress costs

---

## Default Configuration (SigNoz Only)

**Recommended** for most deployments to avoid unnecessary costs.

```yaml
# No environment variables needed - defaults to SigNoz
TRACE_EXPORTER_PRIMARY=otlp/signoz  # default
TRACE_EXPORTER_SECONDARY=           # default (empty = disabled)
```

**Result**: Traces sent to SigNoz only ✅  
**Cost**: 1x egress + storage

---

## AWS X-Ray Only

Use when deploying in AWS environment without SigNoz.

```yaml
TRACE_EXPORTER_PRIMARY=awsxray
TRACE_EXPORTER_SECONDARY=
```

**Result**: Traces sent to AWS X-Ray only ✅  
**Cost**: 1x egress + X-Ray pricing

---

## Dual Egress (Migration/Testing)

⚠️ **Warning**: Doubles telemetry costs and data volume

```yaml
TRACE_EXPORTER_PRIMARY=otlp/signoz
TRACE_EXPORTER_SECONDARY=awsxray
```

**Result**: Traces sent to BOTH SigNoz AND X-Ray ⚠️  
**Cost**: 2x egress + SigNoz storage + X-Ray pricing

**Use Cases**:

- Migration period (validating X-Ray before cutover)
- A/B testing observability backends
- Compliance requiring multi-backend redundancy

**Duration**: Temporary only - plan to disable after validation

---

## Environment-Specific Recommendations

| Environment | Primary | Secondary | Rationale |
|-------------|---------|-----------|-----------|
| **Local Dev** | `otlp/signoz` | `` | Fast local SigNoz stack |
| **CI/Staging** | `otlp/signoz` | `` | Cost optimization |
| **Production (Hybrid)** | `otlp/signoz` | `` | Vendor-neutral, cost-effective |
| **Production (AWS-only)** | `awsxray` | `` | Native AWS integration |
| **Migration Period** | `otlp/signoz` | `awsxray` | Dual validation (temporary) |

---

## Configuration Methods

### Method 1: Environment Variables (Recommended)

**Docker Compose**:

```yaml
services:
  adot-collector:
    environment:
      - TRACE_EXPORTER_PRIMARY=otlp/signoz
      - TRACE_EXPORTER_SECONDARY=  # Empty = disabled
```

**EKS Operator CR**:

```yaml
spec:
  env:
    - name: TRACE_EXPORTER_PRIMARY
      value: "otlp/signoz"
    - name: TRACE_EXPORTER_SECONDARY
      value: ""  # Disabled
```

**ECS Task Definition**:

```json
{
  "environment": [
    {"name": "TRACE_EXPORTER_PRIMARY", "value": "otlp/signoz"},
    {"name": "TRACE_EXPORTER_SECONDARY", "value": ""}
  ]
}
```

---

### Method 2: Config Overlays (Kustomize/Helm)

**Base** (`base/config.yaml`):

```yaml
exporters: ["${TRACE_EXPORTER_PRIMARY:-otlp/signoz}", "${TRACE_EXPORTER_SECONDARY:-}", logging]
```

**Overlay** (`overlays/aws-prod/config.yaml`):

```yaml
exporters: [awsxray, logging]  # Override for AWS-only
```

---

## Cost Impact Example

**Scenario**: 1M spans/day

| Configuration | Egress | SigNoz | X-Ray | Total/Month |
|---------------|--------|--------|-------|-------------|
| **SigNoz Only** | $10 | $50 | $0 | **$60** ✅ |
| **X-Ray Only** | $10 | $0 | $100 | **$110** |
| **Dual Egress** | $20 | $50 | $100 | **$170** ⚠️ |

**Savings**: SigNoz-only vs Dual = **$110/month** (64% reduction)

---

## Migration Strategy

### Phase 1: SigNoz Only (Baseline)

```yaml
TRACE_EXPORTER_PRIMARY=otlp/signoz
TRACE_EXPORTER_SECONDARY=
```

**Duration**: Ongoing production

---

### Phase 2: Dual Export (Validation)

```yaml
TRACE_EXPORTER_PRIMARY=otlp/signoz
TRACE_EXPORTER_SECONDARY=awsxray
```

**Duration**: 1-2 weeks (validation period)  
**Action**: Compare trace data quality, latency, cost

---

### Phase 3: X-Ray Only (Cutover)

```yaml
TRACE_EXPORTER_PRIMARY=awsxray
TRACE_EXPORTER_SECONDARY=
```

**Duration**: After validation complete  
**Result**: Migrated to X-Ray, SigNoz decommissioned

---

## Troubleshooting

### Issue: Seeing duplicate traces in both systems

**Cause**: `TRACE_EXPORTER_SECONDARY` is set (dual egress enabled)

**Solution**:

```bash
# Disable secondary exporter
export TRACE_EXPORTER_SECONDARY=""

# Restart collector
kubectl rollout restart deployment/resonai-otel-collector
```

---

### Issue: High data transfer costs

**Symptom**: AWS egress costs doubled unexpectedly

**Check**:

```bash
# Verify exporter configuration
kubectl exec -it deployment/resonai-otel-collector -- env | grep TRACE_EXPORTER

# Expected (SigNoz only):
TRACE_EXPORTER_PRIMARY=otlp/signoz
TRACE_EXPORTER_SECONDARY=
```

**Fix**: Ensure `TRACE_EXPORTER_SECONDARY` is empty

---

### Issue: X-Ray sampling not working

**Cause**: `proxy_server` block not configured in awsxray receiver

**Solution**: Already included in `.aws/adot-collector-config.yaml`:

```yaml
awsxray:
  endpoint: 0.0.0.0:2000
  transport: udp
  proxy_server:
    endpoint: 0.0.0.0:2000
    proxy_address: ""  # Optional: X-Ray service endpoint
```

**For remote sampling rules**, set `proxy_address`:

```yaml
proxy_address: "https://xray.us-east-1.amazonaws.com"
```

---

## Quick Commands

### Check Current Configuration

```bash
# Kubernetes
kubectl get deployment resonai-otel-collector -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="TRACE_EXPORTER_PRIMARY")].value}'

# Docker Compose
docker exec adot-collector env | grep TRACE_EXPORTER
```

### Test Trace Export

```bash
# Send test trace via OTLP HTTP
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"test-service"}}]},"scopeSpans":[{"spans":[{"name":"test-span","spanId":"0102030405060708","traceId":"01020304050607080910111213141516","startTimeUnixNano":"1234567890000000000","endTimeUnixNano":"1234567890001000000"}]}]}]}'

# Verify in SigNoz: http://localhost:8080/traces
# Verify in X-Ray (if enabled): AWS Console → X-Ray → Traces
```

---

## Best Practices

✅ **DO**:

- Use SigNoz-only (PRIMARY) for dev/staging/prod unless AWS-specific features needed
- Set SECONDARY to empty string explicitly (not omitted)
- Document cost implications if enabling dual egress
- Time-box dual egress periods (e.g., "2 weeks for validation")

❌ **DON'T**:

- Enable dual egress without clear use case and timeline
- Leave SECONDARY exporter enabled after migration completes
- Assume dual egress is necessary - single exporter is usually sufficient

---

**Last Updated**: 2025-10-15  
**Authority**: cursor{implementer} → BossCat OEM  
**Related**: `docs/cheatsheets/adot-setup.md`, `.aws/adot-collector-config.yaml`

