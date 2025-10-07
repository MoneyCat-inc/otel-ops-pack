# BossCat Local Testing Guide

## Overview

This guide provides instructions for running BossCat performance testing and gate verification locally on your development machine. This ensures environment parity between local development and CI/CD pipelines.

## Prerequisites

### Required Software
- **Python 3.9+** with pip
- **Node.js 16+** with npm
- **k6** performance testing tool
- **Locust** load testing framework
- **Docker** and **Docker Compose**
- **kubectl** (for Kubernetes testing)

### Required Services
- **SigNoz** observability stack
- **OpenTelemetry Collector**
- **Prometheus** (optional)

## Local Environment Setup

### 1. Install Dependencies

```bash
# Install Python dependencies
pip install -r requirements.txt

# Install k6
# On macOS
brew install k6

# On Ubuntu/Debian
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# On Windows
choco install k6

# Install Locust
pip install locust
```

### 2. Start SigNoz Stack

```bash
# Start SigNoz with Docker Compose
docker-compose -f docker-compose-signoz.yml up -d

# Verify SigNoz is running
curl -f http://localhost:8080/api/v1/health
```

### 3. Configure Environment Variables

```bash
# Set environment variables
export SIGNOZ_URL=http://localhost:8080
export OTLP_ENDPOINT=http://localhost:4317
export KUBERNETES_NAMESPACE=bosscat-testing
export ARTIFACTS_DIR=artifacts

# Create artifacts directory
mkdir -p artifacts
```

## Running Tests Locally

### 1. Synthetic Trace Testing

```bash
# Generate synthetic traces
python scripts/send_synthetic_otel_simple.py \
  --endpoint http://localhost:4317 \
  --service-name "bosscat-local-test" \
  --trace-count 10 \
  --verbose

# Verify trace ingestion
python scripts/verify-synthetic-ingestion-enhanced.py \
  --signoz-url http://localhost:8080 \
  --timeout 60 \
  --wait-for-traces \
  --verbose
```

### 2. k6 Performance Testing

#### Baseline Test
```bash
k6 run tests/k6/baseline-test.js \
  --env BASE_URL=http://localhost:8080 \
  --env VUS=10 \
  --env DURATION=30s \
  --out json=artifacts/baseline-test-results.json
```

#### Load Test
```bash
k6 run tests/k6/load-test.js \
  --env BASE_URL=http://localhost:8080 \
  --env VUS=50 \
  --env DURATION=2m \
  --out json=artifacts/load-test-results.json
```

#### Stress Test
```bash
k6 run tests/k6/stress-test.js \
  --env BASE_URL=http://localhost:8080 \
  --env VUS=100 \
  --env DURATION=5m \
  --out json=artifacts/stress-test-results.json
```

#### Soak Test
```bash
k6 run tests/k6/soak-test.js \
  --env BASE_URL=http://localhost:8080 \
  --env VUS=20 \
  --env DURATION=30m \
  --out json=artifacts/soak-test-results.json
```

### 3. Locust User Journey Testing

```bash
# Run user journey simulation
locust -f tests/locust/signoz_user_journey.py \
  --host http://localhost:8080 \
  --users 20 \
  --spawn-rate 2 \
  --run-time 5m \
  --headless \
  --csv artifacts/locust-results

# Run gate verification simulation
locust -f tests/locust/bosscat_gate_verification.py \
  --host http://localhost:8080 \
  --users 10 \
  --spawn-rate 1 \
  --run-time 3m \
  --headless \
  --csv artifacts/gate-verification-results
```

### 4. Comprehensive Gate Verification

```bash
# Run full gate verification
python scripts/verify-gate-readiness.py \
  --artifacts-dir artifacts \
  --signoz-url http://localhost:8080 \
  --threshold-p95 500 \
  --threshold-error-rate 0.05 \
  --output artifacts/gate-verification-results.json \
  --verbose
```

## Environment Parity

### Local vs CI/CD Differences

| Component | Local | CI/CD |
|-----------|-------|-------|
| SigNoz URL | http://localhost:8080 | http://signoz-frontend:8080 |
| OTLP Endpoint | http://localhost:4317 | http://otel-collector:4317 |
| Test Duration | Shorter (for development) | Full duration |
| Resource Limits | Local machine limits | Kubernetes limits |
| Network | Localhost | Kubernetes networking |

### Ensuring Parity

1. **Use Environment Variables**: Always use environment variables for configuration
2. **Same Test Scripts**: Use identical test scripts for local and CI/CD
3. **Consistent Thresholds**: Use the same performance thresholds
4. **Same Dependencies**: Use identical dependency versions

## Local Development Workflow

### One-Shot Local Runner

The easiest way to run the complete BossCat pipeline locally is using the one-shot runner:

```bash
# Run complete pipeline with mock SigNoz
python scripts/run-local-pipeline.py --use-mock --test-types baseline load

# Run with real SigNoz instance
python scripts/run-local-pipeline.py --test-types baseline load stress soak

# Run with custom artifacts directory
python scripts/run-local-pipeline.py --artifacts-dir my-artifacts --use-mock
```

The runner will:
1. Start mock SigNoz API (if `--use-mock` is specified)
2. Generate synthetic traces
3. Run k6 performance tests
4. Run Locust user journey tests
5. Verify gate readiness
6. Generate ECRR and BOSS v2 reports
7. Clean up and provide summary

### 2. Debugging Tests

```bash
# Enable verbose logging
export LOG_LEVEL=DEBUG

# Run tests with detailed output
k6 run tests/k6/baseline-test.js --env DURATION=30s --verbose

# Check SigNoz logs
docker logs signoz-frontend

# Verify trace data
curl "http://localhost:8080/api/v1/traces?query=attributes.test.type%20=%20%22synthetic%22&start=$(date -d '5 minutes ago' +%s)&end=$(date +%s)"
```

## Troubleshooting

### Common Issues

1. **SigNoz Not Accessible**
   ```bash
   # Check if SigNoz is running
   docker ps | grep signoz
   
   # Check SigNoz logs
   docker logs signoz-frontend
   
   # Restart SigNoz
   docker-compose -f docker-compose-signoz.yml restart
   ```

2. **OTLP Endpoint Not Available**
   ```bash
   # Check OTLP endpoint
   curl -f http://localhost:4317
   
   # Check collector logs
   docker logs otel-collector
   ```

3. **Test Failures**
   ```bash
   # Check test logs
   tail -f artifacts/*.log
   
   # Verify environment variables
   env | grep -E "(SIGNOZ|OTLP|KUBERNETES)"
   ```

4. **Performance Issues**
   ```bash
   # Check system resources
   docker stats
   
   # Monitor SigNoz performance
   curl http://localhost:8080/api/v1/metrics
   ```

### Debug Commands

```bash
# Check all services
docker-compose -f docker-compose-signoz.yml ps

# View SigNoz UI
open http://localhost:8080

# Check test artifacts
ls -la artifacts/

# Verify trace ingestion
python scripts/verify-synthetic-ingestion-enhanced.py --signoz-url http://localhost:8080 --verbose
```

## Best Practices

### 1. Test Development
- Start with small tests and gradually increase complexity
- Use environment variables for all configuration
- Test locally before committing changes
- Maintain test data quality

### 2. Performance Testing
- Use realistic test scenarios
- Monitor system resources during tests
- Set appropriate thresholds
- Document performance expectations

### 3. Observability
- Verify trace ingestion before running tests
- Monitor SigNoz health during tests
- Check metrics collection
- Validate log aggregation

### 4. Environment Management
- Use consistent environment variables
- Document local setup requirements
- Maintain environment parity
- Regular dependency updates

## Integration with CI/CD

### Pre-commit Testing
```bash
# Run quick tests before commit
./scripts/pre-commit-tests.sh
```

### Local CI Simulation
```bash
# Simulate CI/CD pipeline locally
./scripts/simulate-ci-pipeline.sh
```

### Artifact Validation
```bash
# Validate artifacts match CI/CD format
python scripts/validate-artifacts.py --artifacts-dir artifacts
```

## Support

For local testing issues:
- Check SigNoz UI: http://localhost:8080
- Review logs in `artifacts/` directory
- Consult troubleshooting guide
- Contact BossCat team for assistance

## Quick Reference

### Essential Commands
```bash
# Start services
docker-compose -f docker-compose-signoz.yml up -d

# Run tests
python scripts/send_synthetic_otel_simple.py --trace-count 10
k6 run tests/k6/baseline-test.js --env DURATION=30s
locust -f tests/locust/signoz_user_journey.py --host http://localhost:8080 --users 10 --run-time 2m --headless

# Verify results
python scripts/verify-gate-readiness.py --artifacts-dir artifacts --signoz-url http://localhost:8080

# Generate reports
python scripts/generate-ecrr-report.py --artifacts-dir artifacts --output docs/BossCat/reports/ECRR_LOCAL_$(date +%Y-%m-%d).md
```

### Environment Variables
```bash
export SIGNOZ_URL=http://localhost:8080
export OTLP_ENDPOINT=http://localhost:4317
export KUBERNETES_NAMESPACE=bosscat-testing
export ARTIFACTS_DIR=artifacts
export LOG_LEVEL=INFO
```
