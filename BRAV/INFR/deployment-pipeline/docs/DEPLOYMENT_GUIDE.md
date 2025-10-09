# Deployment Guide

## Overview

This guide provides detailed instructions for deploying the Deployment Pipeline API across different environments using the Tetragrammaton YHWH architecture.

## Deployment Environments

### Staging Environment

**Purpose**: Pre-production testing and validation
**Access**: Internal team access
**Configuration**: Production-like setup with test data

### Production Environment

**Purpose**: Live production service
**Access**: Public internet access
**Configuration**: Full production setup with monitoring

## Deployment Methods

### 1. Docker Compose (Local Development)

**Prerequisites:**
- Docker and Docker Compose installed
- Port 3000 available

**Deployment Steps:**
```bash
# Navigate to deployment directory
cd deployment-pipeline

# Build and start services
docker-compose up -d --build

# Verify deployment
curl http://localhost:3000/health

# View logs
docker-compose logs -f deployment-pipeline-api

# Stop services
docker-compose down
```

**Configuration:**
```yaml
# docker-compose.yml
services:
  deployment-pipeline-api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 2. Kubernetes Deployment

**Prerequisites:**
- Kubernetes cluster access
- kubectl configured
- Container registry access

**Deployment Steps:**
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml

# Check deployment status
kubectl get pods -l app=deployment-pipeline-api

# Verify service
kubectl get services deployment-pipeline-api-service

# Port forward for local access
kubectl port-forward service/deployment-pipeline-api-service 3000:80

# Check logs
kubectl logs -l app=deployment-pipeline-api -f
```

**Kubernetes Configuration:**
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-pipeline-api
  labels:
    app: deployment-pipeline-api
    architecture: tetragrammaton
spec:
  replicas: 3
  selector:
    matchLabels:
      app: deployment-pipeline-api
  template:
    metadata:
      labels:
        app: deployment-pipeline-api
        architecture: tetragrammaton
    spec:
      containers:
      - name: deployment-pipeline-api
        image: ghcr.io/owner/deployment-pipeline-api:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 3. GitHub Actions CI/CD

**Prerequisites:**
- GitHub repository with Actions enabled
- Container registry access
- Environment secrets configured

**Workflow Configuration:**
```yaml
# .github/workflows/deployment-pipeline-complete.yml
name: Deployment Pipeline CI/CD - Complete

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

**Deployment Phases:**
1. **Build and Test** - Node.js setup, dependencies, testing
2. **Security Scan** - npm audit and vulnerability scanning
3. **Docker Build** - Multi-architecture image build and push
4. **Deploy** - Environment-specific deployment
5. **Smoke Tests** - Automated endpoint validation
6. **ECRR Evidence** - Metrics capture and compliance reporting

## Environment-Specific Configuration

### Staging Environment

**Configuration:**
- Node.js environment: production
- Port: 3000
- Replicas: 1
- Resource limits: Basic
- Monitoring: Basic metrics

**Deployment Command:**
```bash
# Manual deployment
kubectl apply -f k8s/deployment-staging.yaml

# Or via GitHub Actions
gh workflow run "Deployment Pipeline CI/CD" -f environment=staging
```

### Production Environment

**Configuration:**
- Node.js environment: production
- Port: 80 (via nginx)
- Replicas: 3
- Resource limits: Production-grade
- Monitoring: Full metrics and alerting

**Deployment Command:**
```bash
# Manual deployment
kubectl apply -f k8s/deployment-production.yaml

# Or via GitHub Actions
gh workflow run "Deployment Pipeline CI/CD" -f environment=production
```

## Health Checks and Monitoring

### Health Check Endpoints

**Basic Health Check:**
```bash
curl http://localhost:3000/health
```

**Detailed Status:**
```bash
curl http://localhost:3000/api/v1/status
```

**Metrics:**
```bash
curl http://localhost:3000/api/v1/metrics
```

### Monitoring Setup

**Prometheus Metrics:**
```javascript
// Add to app.js
const prometheus = require('prom-client');

const register = new prometheus.Registry();
prometheus.collectDefaultMetrics({ register });

// Add metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  register.metrics().then(data => res.send(data));
});
```

### Deployment Metrics Script

Use the deployment metrics capture script for comprehensive reporting:

```powershell
# Capture all metrics (default localhost:3000)
pwsh scripts/deployment-metrics.ps1 -Action capture

# Capture metrics from specific environment
pwsh scripts/deployment-metrics.ps1 -Action capture -Environment production -BaseUrl "https://api.example.com"

# Capture metrics from Kubernetes cluster
pwsh scripts/deployment-metrics.ps1 -Action capture -Environment staging -BaseUrl "http://deployment-pipeline-api-service:3000"

# Generate ECRR report with custom base URL
pwsh scripts/deployment-metrics.ps1 -Action ecrr -Environment production -BaseUrl "https://api.example.com" -Port 443

# Validate pipeline configuration
pwsh scripts/deployment-metrics.ps1 -Action validate
```

**Configuration Parameters:**
- `-BaseUrl`: Service base URL (overrides default localhost)
- `-Port`: Service port (default: 3000)
- `-Environment`: Target environment (staging/production)
- `-OutputPath`: Metrics output directory
- `-ECRRReportDir`: ECRR reports directory

**Grafana Dashboard:**
- Import dashboard configuration
- Configure data source (Prometheus)
- Set up alerting rules

## Security Configuration

### Docker Security

**Non-root User:**
```dockerfile
# Add to Dockerfile
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs
```

**Security Headers:**
```javascript
// Add to app.js
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  }
}));
```

### Kubernetes Security

**Security Context:**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
```

**Network Policies:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deployment-pipeline-api-netpol
spec:
  podSelector:
    matchLabels:
      app: deployment-pipeline-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000
```

## Rollback Procedures

### Docker Compose Rollback

```bash
# Stop current version
docker-compose down

# Deploy previous version
docker-compose -f docker-compose.yml -f docker-compose.previous.yml up -d

# Verify rollback
curl http://localhost:3000/health
```

### Kubernetes Rollback

```bash
# Check deployment history
kubectl rollout history deployment/deployment-pipeline-api

# Rollback to previous version
kubectl rollout undo deployment/deployment-pipeline-api

# Check rollback status
kubectl rollout status deployment/deployment-pipeline-api
```

## Troubleshooting

### Common Deployment Issues

**Service Not Starting:**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Health Check Failures:**
```bash
# Manual health check
curl -v http://localhost:3000/health

# Check service endpoints
kubectl get endpoints deployment-pipeline-api-service

# Test from within cluster
kubectl run test-pod --image=curlimages/curl --rm -it -- curl http://deployment-pipeline-api-service:3000/health
```

**Resource Issues:**
```bash
# Check resource usage
kubectl top pods

# Check resource limits
kubectl describe pod <pod-name>

# Adjust resource limits if needed
kubectl patch deployment deployment-pipeline-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"deployment-pipeline-api","resources":{"limits":{"memory":"512Mi","cpu":"500m"}}}]}}}}'
```

## Best Practices

### Deployment Best Practices

1. **Always test in staging first**
2. **Use blue-green deployments for production**
3. **Monitor deployment metrics**
4. **Have rollback procedures ready**
5. **Document all configuration changes**

### Security Best Practices

1. **Use non-root containers**
2. **Implement security headers**
3. **Regular security scans**
4. **Network segmentation**
5. **Secret management**

### Monitoring Best Practices

1. **Set up comprehensive health checks**
2. **Monitor resource usage**
3. **Track deployment metrics**
4. **Set up alerting**
5. **Regular log analysis**

---

**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**Deployment**: Multi-environment support  
**Security**: Production-grade security configuration  
**Monitoring**: Comprehensive health checks and metrics  
**Governance**: ECRR Framework + BossCat Compliance**
