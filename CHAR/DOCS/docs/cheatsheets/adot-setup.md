# AWS ADOT Setup Cheatsheet

**Purpose**: Deploy AWS Distro for OpenTelemetry (ADOT) collector for hybrid cloud observability  
**Compatibility**: Maintains OTLP endpoints (4317/4318) for vendor-neutral ingestion  
**Target Platforms**: EKS, ECS, EC2, Local Docker

---

## Quick Reference

| Component | File | Purpose |
|-----------|------|---------|
| **Collector Config** | `.aws/adot-collector-config.yaml` | ADOT collector configuration (OTLP + AWS services) |
| **EKS Operator CR** | `.aws/adot-operator-cr.yaml` | Kubernetes deployment via ADOT Operator |
| **CI Validation** | `.github/workflows/adot-config-gate.yml` | Automated YAML lint + dry-run validation |

---

## Prerequisites

### For EKS Deployment

```bash
# Install ADOT Operator
kubectl apply -f https://amazon-otel.github.io/docs/getting-started/adot-eks-add-on/operator-install.yaml

# Create observability namespace
kubectl create namespace observability

# Create IAM role for IRSA (replace ACCOUNT_ID and CLUSTER_NAME)
eksctl create iamserviceaccount \
  --name adot-collector \
  --namespace observability \
  --cluster CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess \
  --attach-policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess \
  --approve
```

### For Local/Docker Deployment

```bash
# Pull ADOT collector image
docker pull public.ecr.aws/aws-observability/aws-otel-collector:latest

# Validate configuration
docker run --rm -v $(pwd)/.aws:/config \
  -e SIGNOZ_ENDPOINT=localhost:4317 \
  -e SIGNOZ_INSECURE=true \
  -e AWS_REGION=us-east-1 \
  public.ecr.aws/aws-observability/aws-otel-collector:latest \
  --config /config/adot-collector-config.yaml --dry-run
```

---

## Deployment Options

### Option 1: EKS with ADOT Operator (Recommended)

#### Step 1: Update ServiceAccount annotation

```yaml
# Edit .aws/adot-operator-cr.yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/resonai-otel-collector-role
```

#### Step 2: Update SigNoz endpoint

```yaml
# If SigNoz is external (not in cluster)
env:
  - name: SIGNOZ_ENDPOINT
    value: "https://your-signoz-instance.com:4317"
```

#### Step 3: Deploy

```bash
kubectl apply -f .aws/adot-operator-cr.yaml
```

#### Step 4: Verify

```bash
# Check collector status
kubectl get otelcol -n observability

# Check pods
kubectl get pods -n observability -l app.kubernetes.io/name=resonai-otel-collector

# Check logs
kubectl logs -n observability -l app.kubernetes.io/name=resonai-otel-collector -f

# Test health check
kubectl port-forward -n observability svc/resonai-otel-collector 13133:13133
curl http://localhost:13133/
```

---

### Option 2: ECS with Task Definition

#### Step 1: Create task definition

```json
{
  "family": "resonai-otel-collector",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/resonai-otel-task-role",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "aws-otel-collector",
      "image": "public.ecr.aws/aws-observability/aws-otel-collector:latest",
      "essential": true,
      "command": ["--config=/etc/config/adot-collector-config.yaml"],
      "environment": [
        {"name": "AWS_REGION", "value": "us-east-1"},
        {"name": "SIGNOZ_ENDPOINT", "value": "your-signoz:4317"},
        {"name": "SIGNOZ_INSECURE", "value": "false"}
      ],
      "portMappings": [
        {"containerPort": 4317, "protocol": "tcp"},
        {"containerPort": 4318, "protocol": "tcp"},
        {"containerPort": 13133, "protocol": "tcp"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/resonai-otel-collector",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "collector"
        }
      }
    }
  ]
}
```

#### Step 2: Deploy service

```bash
aws ecs create-service \
  --cluster your-cluster \
  --service-name resonai-otel-collector \
  --task-definition resonai-otel-collector:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

---

### Option 3: EC2 with Systemd

#### Step 1: Install ADOT collector

```bash
# Download ADOT collector
wget https://aws-otel-collector.s3.amazonaws.com/linux/amd64/latest/aws-otel-collector.rpm
sudo rpm -Uvh aws-otel-collector.rpm

# Copy config
sudo cp .aws/adot-collector-config.yaml /opt/aws/aws-otel-collector/etc/config.yaml
```

#### Step 2: Configure systemd service

```bash
# Edit /etc/systemd/system/aws-otel-collector.service
sudo systemctl daemon-reload
sudo systemctl enable aws-otel-collector
sudo systemctl start aws-otel-collector
```

#### Step 3: Verify

```bash
sudo systemctl status aws-otel-collector
sudo journalctl -u aws-otel-collector -f
```

---

### Option 4: Local Docker Compose

#### Step 1: Add to docker-compose.yml

```yaml
services:
  adot-collector:
    image: public.ecr.aws/aws-observability/aws-otel-collector:latest
    container_name: adot-collector
    command: ["--config=/etc/config/adot-collector-config.yaml"]
    volumes:
      - ./.aws/adot-collector-config.yaml:/etc/config/adot-collector-config.yaml:ro
    environment:
      - AWS_REGION=us-east-1
      - SIGNOZ_ENDPOINT=signoz:4317
      - SIGNOZ_INSECURE=true
      - COLLECTOR_LOG_LEVEL=info
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "13133:13133"  # Health check
      - "8888:8888"  # Prometheus metrics
    restart: unless-stopped
```

#### Step 2: Start

```bash
docker-compose up -d adot-collector
docker-compose logs -f adot-collector
```

---

## Testing & Verification

### Send Test Trace (OTLP gRPC)

```bash
# Using otel-cli (install: go install github.com/equinix-labs/otel-cli@latest)
otel-cli exec \
  --endpoint localhost:4317 \
  --insecure \
  --service test-service \
  --name "test-span" \
  -- echo "ADOT collector test"
```

### Send Test Metrics (OTLP HTTP)

```bash
# Using curl
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{
    "resourceMetrics": [{
      "resource": {"attributes": [{"key": "service.name", "value": {"stringValue": "test-service"}}]},
      "scopeMetrics": [{
        "metrics": [{
          "name": "test.counter",
          "unit": "1",
          "sum": {"dataPoints": [{"asInt": "1", "timeUnixNano": "1234567890000000000"}]}
        }]
      }]
    }]
  }'
```

### Check Health

```bash
# Health check endpoint
curl http://localhost:13133/

# Prometheus metrics
curl http://localhost:8888/metrics
```

### Verify in SigNoz

```bash
# Navigate to SigNoz UI
open http://localhost:8080

# Check Services tab for "test-service"
# Check Traces for "test-span"
# Check Metrics for "test.counter"
```

---

## Configuration Reference

### Key Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SIGNOZ_ENDPOINT` | `localhost:4317` | SigNoz OTLP gRPC endpoint |
| `SIGNOZ_INSECURE` | `true` | Skip TLS verification (false in prod) |
| `AWS_REGION` | `us-east-1` | AWS region for CloudWatch/X-Ray |
| `COLLECTOR_LOG_LEVEL` | `info` | Logging verbosity (debug/info/warn/error) |

### Pipeline Optimization

**For Low Latency** (current: 200ms):

```yaml
processors:
  batch:
    timeout: 200ms  # Fast batching
    send_batch_size: 1024
```

**For High Throughput**:

```yaml
processors:
  batch:
    timeout: 10s  # Larger batches
    send_batch_size: 8192
```

**For Memory Constrained**:

```yaml
processors:
  memory_limiter:
    limit_mib: 256  # Reduce from 512
    spike_limit_mib: 64
```

---

## Troubleshooting

### Issue: Collector won't start

**Check logs**:

```bash
# EKS
kubectl logs -n observability -l app.kubernetes.io/name=resonai-otel-collector

# Docker
docker logs adot-collector

# EC2
sudo journalctl -u aws-otel-collector -n 100
```

**Common causes**:

- Invalid YAML syntax → Run `yamllint .aws/adot-collector-config.yaml`
- Missing environment variables → Check SIGNOZ_ENDPOINT, AWS_REGION
- Port conflicts → Check if 4317/4318 already in use

---

### Issue: No data in SigNoz

**Verify connectivity**:

```bash
# Test SigNoz endpoint
curl http://YOUR_SIGNOZ_ENDPOINT:4317

# Check collector logs for export errors
docker logs adot-collector | grep -i error
```

**Check exporters**:

```yaml
# Temporarily add logging exporter for debugging
exporters:
  logging:
    loglevel: debug
service:
  pipelines:
    traces:
      exporters: [otlp/signoz, logging]  # Add logging
```

---

### Issue: High memory usage

**Tune memory limiter**:

```yaml
processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 512  # Reduce if needed
    spike_limit_mib: 128
```

**Reduce batch size**:

```yaml
processors:
  batch:
    timeout: 200ms
    send_batch_size: 512  # Reduce from 1024
```

---

## Migration from Windows OTel Collector

**Compatibility**: ADOT collector is **drop-in compatible** with current setup:

| Current Setup | ADOT Equivalent | Notes |
|---------------|-----------------|-------|
| OTLP gRPC :4317 | Same | No app changes needed |
| OTLP HTTP :4318 | Same | No app changes needed |
| SigNoz exporter | otlp/signoz | Uses standard OTLP protocol |
| 200ms batching | Same | Low-latency preserved |
| 48 workers | Auto-scaled | Kubernetes HPA handles scaling |

**Migration steps**:

1. Deploy ADOT collector (EKS/ECS/EC2)
2. Point apps to ADOT endpoint (DNS or service mesh)
3. Verify data flowing to SigNoz
4. Decommission Windows collector (when ready)

**Hybrid operation**: Both collectors can run simultaneously (different ports or DNS)

---

## CI/CD Integration

### GitHub Actions Workflow

Workflow `.github/workflows/adot-config-gate.yml` runs on:

- Pull requests touching `.aws/**` or `deploy/adot/**`
- Manual trigger via `workflow_dispatch`

**Validation steps**:

1. YAML lint (syntax check)
2. ADOT collector dry-run (config validation)
3. Kubernetes manifest validation (if operator CR present)

**Local validation**:

```bash
# YAML lint
yamllint .aws/

# Dry-run
docker run --rm -v $(pwd)/.aws:/config \
  -e SIGNOZ_ENDPOINT=localhost:4317 \
  public.ecr.aws/aws-observability/aws-otel-collector:latest \
  --config /config/adot-collector-config.yaml --dry-run

# Kubernetes validation (requires kubeval)
kubeval --strict .aws/adot-operator-cr.yaml
```

---

## BossCat Compliance

### ECRR Methodology

**Examine**: ADOT config validated in CI before deployment  
**Clean**: Dry-run checks prevent invalid configs reaching prod  
**Report**: CI generates validation artifacts  
**Role**: cursor{implementer} maintains config, BossCat approves gates

### GitHub Actions Standards

✅ **Concurrency control**: Cancel superseded PR runs  
✅ **Artifact retention**: Validation logs kept 14 days  
✅ **Job summaries**: Instant validation status

---

## Additional Resources

- [ADOT Documentation](https://aws-otel.github.io/docs/introduction)
- [ADOT Collector GitHub](https://github.com/aws-observability/aws-otel-collector)
- [EKS Add-ons Guide](https://docs.aws.amazon.com/eks/latest/userguide/opentelemetry.html)
- [SigNoz instrumentation docs](https://signoz.io/docs/instrumentation/)

---

**Last Updated**: 2025-10-15  
**Maintained By**: cursor{implementer} → BossCat OEM  
**Status**: Production-ready, CI-validated

