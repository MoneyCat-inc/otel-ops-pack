# Secrets Configuration Guide

## Overview

This guide provides detailed instructions for configuring the required GitHub Secrets to enable cloud provider authentication and deployment in the deployment pipeline.

## Required GitHub Secrets

### Google Kubernetes Engine (GKE) Secrets

**Required Secrets:**
```
GCP_PROJECT_ID: your-gcp-project-id
GCP_SA_KEY: base64-encoded-service-account-key
GKE_CLUSTER_NAME: your-cluster-name
GKE_ZONE: us-central1-a
```

**Setup Instructions:**

1. **Create Service Account:**
```bash
# Create service account
gcloud iam service-accounts create github-actions-k8s \
    --description="GitHub Actions Kubernetes deployment" \
    --display-name="GitHub Actions K8s"

# Grant Kubernetes Engine Admin role
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions-k8s@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"

# Create and download key
gcloud iam service-accounts keys create key.json \
    --iam-account=github-actions-k8s@PROJECT_ID.iam.gserviceaccount.com

# Base64 encode the key
base64 -i key.json
```

2. **Configure GitHub Secrets:**
- Go to your repository Settings → Secrets and variables → Actions
- Add each secret with the values from your GCP setup

### Amazon Elastic Kubernetes Service (EKS) Secrets

**Required Secrets:**
```
AWS_ACCESS_KEY_ID: your-access-key-id
AWS_SECRET_ACCESS_KEY: your-secret-access-key
AWS_REGION: us-west-2
EKS_CLUSTER_NAME: your-cluster-name
```

**Setup Instructions:**

1. **Create IAM User:**
```bash
# Create IAM user
aws iam create-user --user-name github-actions-k8s

# Attach EKS policy
aws iam attach-user-policy \
    --user-name github-actions-k8s \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Create access keys
aws iam create-access-key --user-name github-actions-k8s
```

2. **Configure GitHub Secrets:**
- Add the access key ID and secret access key from the IAM user creation
- Set the AWS region where your EKS cluster is located
- Set the EKS cluster name

### Azure Kubernetes Service (AKS) Secrets

**Required Secrets:**
```
AZURE_CLIENT_ID: your-client-id
AZURE_CLIENT_SECRET: your-client-secret
AZURE_SUBSCRIPTION_ID: your-subscription-id
AZURE_TENANT_ID: your-tenant-id
AKS_RESOURCE_GROUP: your-resource-group
AKS_CLUSTER_NAME: your-cluster-name
```

**Setup Instructions:**

1. **Create Service Principal:**
```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-k8s" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP

# Get AKS credentials
az aks get-credentials --resource-group RESOURCE_GROUP \
  --name CLUSTER_NAME
```

2. **Configure GitHub Secrets:**
- Add the client ID, client secret, subscription ID, and tenant ID from service principal creation
- Set the resource group and cluster name for your AKS cluster

### Optional Security Scanning Secrets

**Snyk Security Scanning:**
```
SNYK_TOKEN: your-snyk-api-token
```

**Setup Instructions:**
1. Create a Snyk account at https://snyk.io
2. Generate an API token from your account settings
3. Add the token as a GitHub Secret

## Environment-Specific Configuration

### Staging Environment

**GitHub Environment Setup:**
1. Go to repository Settings → Environments
2. Create a new environment called "staging"
3. Add environment-specific secrets:
   - `GCP_PROJECT_ID_STAGING`
   - `GCP_SA_KEY_STAGING`
   - `GKE_CLUSTER_NAME_STAGING`
   - `GKE_ZONE_STAGING`

**Or use the same secrets with staging-specific values:**
```
GCP_PROJECT_ID: staging-project-id
GCP_SA_KEY: staging-service-account-key
GKE_CLUSTER_NAME: staging-cluster
GKE_ZONE: us-central1-a
```

### Production Environment

**GitHub Environment Setup:**
1. Create a new environment called "production"
2. Add environment-specific secrets:
   - `GCP_PROJECT_ID_PRODUCTION`
   - `GCP_SA_KEY_PRODUCTION`
   - `GKE_CLUSTER_NAME_PRODUCTION`
   - `GKE_ZONE_PRODUCTION`

**Or use the same secrets with production-specific values:**
```
GCP_PROJECT_ID: production-project-id
GCP_SA_KEY: production-service-account-key
GKE_CLUSTER_NAME: production-cluster
GKE_ZONE: us-central1-a
```

## Workflow Authentication Logic

The workflow automatically detects which cloud provider to use based on available secrets:

```yaml
# GKE Authentication
- name: Authenticate to GKE
  if: ${{ (inputs.environment == "staging" || inputs.environment == "production") && secrets.GCP_PROJECT_ID }}
  uses: google-github-actions/auth@v1
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}

# EKS Authentication  
- name: Configure AWS credentials for EKS
  if: ${{ (inputs.environment == "staging" || inputs.environment == "production") && secrets.AWS_ACCESS_KEY_ID }}
  uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}

# AKS Authentication
- name: Azure Login for AKS
  if: ${{ (inputs.environment == "staging" || inputs.environment == "production") && secrets.AZURE_CLIENT_ID }}
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Health Check Configuration

The workflow automatically handles health checks for different deployment scenarios:

### Docker Compose (Local Testing)
- **Health Check URL**: `http://localhost:3000/health`
- **Port**: 3000 (direct service port)

### Kubernetes with Port Forward
- **Health Check URL**: `http://localhost:8080/health`
- **Port Forward**: `kubectl port-forward service/deployment-pipeline-api-service 8080:80`
- **Service Port**: 80 (Kubernetes service port)
- **Forwarded Port**: 8080 (localhost port)

### Automatic Endpoint Detection
The workflow automatically detects which service endpoint is available:

```bash
# Check both local Docker Compose and forwarded Kubernetes ports
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
  SERVICE_BASE="http://localhost:3000"
  echo "Testing against Docker Compose service"
elif curl -f http://localhost:8080/health >/dev/null 2>&1; then
  SERVICE_BASE="http://localhost:8080"
  echo "Testing against Kubernetes port-forwarded service"
else
  echo "❌ No service endpoint available for testing"
  exit 1
fi
```

## Troubleshooting

### Common Issues

**Authentication Failures:**
```bash
# Check secret configuration
echo "Checking if secrets are properly configured..."

# Verify GCP authentication
gcloud auth list

# Verify AWS authentication
aws sts get-caller-identity

# Verify Azure authentication
az account show
```

**Health Check Failures:**
```bash
# Check service status
kubectl get pods -l app=deployment-pipeline-api
kubectl get services deployment-pipeline-api-service

# Check port forwarding
kubectl port-forward service/deployment-pipeline-api-service 8080:80 &
netstat -tulpn | grep :8080

# Test health endpoint
curl -v http://localhost:8080/health
```

**Deployment Issues:**
```bash
# Check deployment status
kubectl get deployments
kubectl describe deployment deployment-pipeline-api

# Check rollout status
kubectl rollout status deployment/deployment-pipeline-api

# Check pod logs
kubectl logs -l app=deployment-pipeline-api
```

### Debug Commands

**Service Debugging:**
```bash
# Port forward for local access
kubectl port-forward service/deployment-pipeline-api-service 3000:80

# Check service endpoints
kubectl get endpoints deployment-pipeline-api-service

# Test from within cluster
kubectl run test-pod --image=curlimages/curl --rm -it -- \
  curl http://deployment-pipeline-api-service:80/health
```

## Security Best Practices

### Secret Management
1. **Rotate credentials regularly** - Update service account keys and access keys
2. **Use least privilege** - Grant minimal required permissions
3. **Environment separation** - Use different credentials for staging and production
4. **Monitor access** - Review access logs and usage patterns

### Network Security
1. **Use private clusters** - Deploy Kubernetes clusters in private networks
2. **Implement network policies** - Control ingress and egress traffic
3. **Use TLS encryption** - Enable TLS for all service communications
4. **Regular security updates** - Keep cluster and node images updated

## Validation

### Pre-Deployment Checks
```bash
# Verify secrets are configured
if [ -z "$GCP_PROJECT_ID" ] && [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AZURE_CLIENT_ID" ]; then
  echo "❌ No cloud provider secrets configured"
  exit 1
fi

# Verify cluster connectivity
kubectl cluster-info
kubectl get nodes

# Verify service manifests
kubectl apply --dry-run=client -f k8s/deployment.yaml
```

### Post-Deployment Validation
```bash
# Verify deployment
kubectl get pods -l app=deployment-pipeline-api
kubectl get services deployment-pipeline-api-service

# Health check
curl -f http://localhost:8080/health

# Metrics validation
curl -f http://localhost:8080/api/v1/metrics
```

---

**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**Security**: Multi-cloud authentication with proper secret management  
**Deployment**: Production-ready with health check validation  
**Monitoring**: Comprehensive service endpoint detection and validation**
