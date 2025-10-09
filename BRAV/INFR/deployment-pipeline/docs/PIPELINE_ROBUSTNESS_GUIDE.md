# Pipeline Robustness Guide

## Overview

This guide explains how the deployment pipeline handles different scenarios, from repositories without any infrastructure setup to fully configured multi-cloud deployments. The pipeline is designed to be robust and complete successfully regardless of the cloud provider configuration.

## Pipeline Behavior Scenarios

### Scenario 1: No Cloud Provider Secrets (Local Development)

**Configuration**: No GCP, AWS, or Azure secrets configured

**Pipeline Execution**:
```
✅ Build and Test - Always runs
✅ Security Scan - Always runs (unless skipped)
✅ Docker Build - Always runs (pushes to registry)
✅ Deploy - Runs Docker Compose only
   - Docker Compose deployment: ✅ Executes
   - GKE Authentication: ⏭️ Skipped (no GCP_PROJECT_ID)
   - EKS Authentication: ⏭️ Skipped (no AWS_ACCESS_KEY_ID)
   - AKS Authentication: ⏭️ Skipped (no AZURE_CLIENT_ID)
   - Kubernetes Staging: ⏭️ Skipped (no cloud secrets)
   - Kubernetes Production: ⏭️ Skipped (no cloud secrets)
✅ Smoke Tests - Runs against Docker Compose service
✅ ECRR Evidence - Collects metrics from Docker Compose
```

**Result**: Pipeline completes successfully with Docker Compose deployment

### Scenario 2: GKE Secrets Configured

**Configuration**: GCP_PROJECT_ID, GCP_SA_KEY, GKE_CLUSTER_NAME, GKE_ZONE configured

**Pipeline Execution**:
```
✅ Build and Test - Always runs
✅ Security Scan - Always runs (unless skipped)
✅ Docker Build - Always runs (pushes to registry)
✅ Deploy - Runs Docker Compose + GKE
   - Docker Compose deployment: ✅ Executes
   - GKE Authentication: ✅ Executes
   - EKS Authentication: ⏭️ Skipped (no AWS_ACCESS_KEY_ID)
   - AKS Authentication: ⏭️ Skipped (no AZURE_CLIENT_ID)
   - Kubernetes Staging: ✅ Executes (GKE secrets available)
   - Kubernetes Production: ✅ Executes (GKE secrets available)
✅ Smoke Tests - Runs against Kubernetes service (port-forward)
✅ ECRR Evidence - Collects metrics from Kubernetes service
```

**Result**: Pipeline completes successfully with GKE deployment

### Scenario 3: EKS Secrets Configured

**Configuration**: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, EKS_CLUSTER_NAME configured

**Pipeline Execution**:
```
✅ Build and Test - Always runs
✅ Security Scan - Always runs (unless skipped)
✅ Docker Build - Always runs (pushes to registry)
✅ Deploy - Runs Docker Compose + EKS
   - Docker Compose deployment: ✅ Executes
   - GKE Authentication: ⏭️ Skipped (no GCP_PROJECT_ID)
   - EKS Authentication: ✅ Executes
   - AKS Authentication: ⏭️ Skipped (no AZURE_CLIENT_ID)
   - Kubernetes Staging: ✅ Executes (EKS secrets available)
   - Kubernetes Production: ✅ Executes (EKS secrets available)
✅ Smoke Tests - Runs against Kubernetes service (port-forward)
✅ ECRR Evidence - Collects metrics from Kubernetes service
```

**Result**: Pipeline completes successfully with EKS deployment

### Scenario 4: AKS Secrets Configured

**Configuration**: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AKS_RESOURCE_GROUP, AKS_CLUSTER_NAME configured

**Pipeline Execution**:
```
✅ Build and Test - Always runs
✅ Security Scan - Always runs (unless skipped)
✅ Docker Build - Always runs (pushes to registry)
✅ Deploy - Runs Docker Compose + AKS
   - Docker Compose deployment: ✅ Executes
   - GKE Authentication: ⏭️ Skipped (no GCP_PROJECT_ID)
   - EKS Authentication: ⏭️ Skipped (no AWS_ACCESS_KEY_ID)
   - AKS Authentication: ✅ Executes
   - Kubernetes Staging: ✅ Executes (AKS secrets available)
   - Kubernetes Production: ✅ Executes (AKS secrets available)
✅ Smoke Tests - Runs against Kubernetes service (port-forward)
✅ ECRR Evidence - Collects metrics from Kubernetes service
```

**Result**: Pipeline completes successfully with AKS deployment

### Scenario 5: Multiple Cloud Providers Configured

**Configuration**: Secrets for multiple cloud providers (e.g., GKE + EKS)

**Pipeline Execution**:
```
✅ Build and Test - Always runs
✅ Security Scan - Always runs (unless skipped)
✅ Docker Build - Always runs (pushes to registry)
✅ Deploy - Runs Docker Compose + Multiple Clouds
   - Docker Compose deployment: ✅ Executes
   - GKE Authentication: ✅ Executes (if GCP secrets present)
   - EKS Authentication: ✅ Executes (if AWS secrets present)
   - AKS Authentication: ✅ Executes (if Azure secrets present)
   - Kubernetes Staging: ✅ Executes (uses first available provider)
   - Kubernetes Production: ✅ Executes (uses first available provider)
✅ Smoke Tests - Runs against Kubernetes service (port-forward)
✅ ECRR Evidence - Collects metrics from Kubernetes service
```

**Result**: Pipeline completes successfully with multi-cloud deployment

## Conditional Logic Implementation

### Authentication Steps

**GKE Authentication**:
```yaml
- name: Authenticate to GKE
  if: ${{ (inputs.environment == "staging" || inputs.environment == "production") && secrets.GCP_PROJECT_ID }}
  uses: google-github-actions/auth@v1
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}
```

**EKS Authentication**:
```yaml
- name: Configure AWS credentials for EKS
  if: ${{ (inputs.environment == "staging" || inputs.environment == "production") && secrets.AWS_ACCESS_KEY_ID }}
  uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}
```

**AKS Authentication**:
```yaml
- name: Azure Login for AKS
  if: ${{ (inputs.environment == "staging" || inputs.environment == "production") && secrets.AZURE_CLIENT_ID }}
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Kubernetes Deployment Steps

**Staging Deployment**:
```yaml
- name: Deploy to Kubernetes (Staging)
  if: ${{ (inputs.environment == "staging" || (inputs.environment == "" && github.ref == "refs/heads/main")) && (secrets.GCP_PROJECT_ID || secrets.AWS_ACCESS_KEY_ID || secrets.AZURE_CLIENT_ID) }}
  run: |
    # kubectl commands here
```

**Production Deployment**:
```yaml
- name: Deploy to Kubernetes (Production)
  if: ${{ inputs.environment == "production" && (secrets.GCP_PROJECT_ID || secrets.AWS_ACCESS_KEY_ID || secrets.AZURE_CLIENT_ID) }}
  run: |
    # kubectl commands here
```

## Service Endpoint Detection

The pipeline automatically detects which service endpoint is available:

### Docker Compose Service
```bash
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
  SERVICE_BASE="http://localhost:3000"
  echo "Testing against Docker Compose service"
```

### Kubernetes Port-Forward Service
```bash
elif curl -f http://localhost:8080/health >/dev/null 2>&1; then
  SERVICE_BASE="http://localhost:8080"
  echo "Testing against Kubernetes port-forwarded service"
```

### No Service Available
```bash
else
  echo "❌ No service endpoint available for testing"
  exit 1
fi
```

## Error Handling and Fallbacks

### Graceful Degradation
- **No cloud secrets**: Falls back to Docker Compose deployment
- **Authentication failure**: Step fails but doesn't stop pipeline
- **Service unavailable**: Provides clear error messages
- **Health check failure**: Continues with warnings

### Health Check Strategies
1. **Primary**: Docker Compose service on localhost:3000
2. **Secondary**: Kubernetes port-forward on localhost:8080
3. **Fallback**: Continue with warnings if no service available

### Metrics Collection
- **Docker Compose**: Collects metrics from localhost:3000
- **Kubernetes**: Collects metrics from localhost:8080
- **No Service**: Uses default localhost:3000 with warnings

## Troubleshooting Common Scenarios

### Pipeline Fails with "kubectl: command not found"

**Cause**: Kubernetes deployment step runs without authentication
**Solution**: The pipeline now includes proper conditional guards to prevent this

### Authentication Steps Run But Deployment Fails

**Cause**: Incorrect cluster configuration or permissions
**Solution**: Check cluster connectivity and permissions:
```bash
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create deployments
```

### Health Checks Fail

**Cause**: Service not ready or port-forward not working
**Solution**: Check service status and port-forward:
```bash
kubectl get pods -l app=deployment-pipeline-api
kubectl get services deployment-pipeline-api-service
kubectl port-forward service/deployment-pipeline-api-service 8080:80
```

### No Service Endpoint Available

**Cause**: Both Docker Compose and Kubernetes services unavailable
**Solution**: Check Docker Compose and Kubernetes deployments:
```bash
docker-compose ps
kubectl get pods -l app=deployment-pipeline-api
```

## Best Practices

### Repository Setup

1. **Start with Docker Compose**: Begin with local development setup
2. **Add cloud secrets gradually**: Configure one cloud provider at a time
3. **Test incrementally**: Verify each step works before adding complexity
4. **Use environment-specific secrets**: Separate staging and production

### Secret Management

1. **Least privilege**: Grant minimal required permissions
2. **Environment separation**: Use different credentials for staging/production
3. **Regular rotation**: Update credentials periodically
4. **Monitoring**: Review access logs and usage patterns

### Pipeline Monitoring

1. **Check logs**: Review GitHub Actions logs for detailed execution
2. **Verify deployments**: Confirm services are actually deployed
3. **Test endpoints**: Validate service health and functionality
4. **Monitor metrics**: Review ECRR evidence and compliance reports

## Validation Commands

### Pre-Deployment Validation
```bash
# Check if secrets are configured
if [ -z "$GCP_PROJECT_ID" ] && [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AZURE_CLIENT_ID" ]; then
  echo "No cloud provider secrets configured - will use Docker Compose only"
fi

# Verify Docker Compose
docker-compose config
docker-compose up -d --build
curl -f http://localhost:3000/health
```

### Post-Deployment Validation
```bash
# Check Docker Compose service
curl -f http://localhost:3000/health

# Check Kubernetes service (if deployed)
kubectl port-forward service/deployment-pipeline-api-service 8080:80 &
curl -f http://localhost:8080/health
```

---

**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**Robustness**: Graceful degradation with conditional execution  
**Deployment**: Multi-cloud support with fallback strategies  
**Monitoring**: Comprehensive health check and endpoint detection  
**Governance**: ECRR framework with evidence collection**
