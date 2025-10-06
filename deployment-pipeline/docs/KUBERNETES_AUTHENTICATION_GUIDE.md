# Kubernetes Authentication Guide

## Overview

This guide provides comprehensive instructions for setting up Kubernetes cluster authentication in the deployment pipeline for different cloud providers and environments.

## Cloud Provider Authentication

### Google Kubernetes Engine (GKE)

**Prerequisites:**
- Google Cloud Project with GKE cluster
- Service Account with Kubernetes Engine Admin role
- GitHub Secrets configured with GCP credentials

**Setup Steps:**

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
```

2. **GitHub Secrets Configuration:**
```
GCP_PROJECT_ID: your-project-id
GCP_SA_KEY: base64-encoded service account key
GKE_CLUSTER_NAME: your-cluster-name
GKE_ZONE: us-central1-a
```

3. **GitHub Actions Workflow:**
```yaml
- name: Authenticate to GKE
  uses: google-github-actions/auth@v1
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}

- name: Set up Cloud SDK
  uses: google-github-actions/setup-gcloud@v1

- name: Configure kubectl
  run: |
    gcloud container clusters get-credentials ${{ secrets.GKE_CLUSTER_NAME }} \
      --zone ${{ secrets.GKE_ZONE }} \
      --project ${{ secrets.GCP_PROJECT_ID }}
```

### Amazon Elastic Kubernetes Service (EKS)

**Prerequisites:**
- AWS Account with EKS cluster
- IAM user with EKS cluster access
- GitHub Secrets configured with AWS credentials

**Setup Steps:**

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

2. **GitHub Secrets Configuration:**
```
AWS_ACCESS_KEY_ID: your-access-key
AWS_SECRET_ACCESS_KEY: your-secret-key
AWS_REGION: us-west-2
EKS_CLUSTER_NAME: your-cluster-name
```

3. **GitHub Actions Workflow:**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}

- name: Update kubeconfig
  run: |
    aws eks update-kubeconfig \
      --region ${{ secrets.AWS_REGION }} \
      --name ${{ secrets.EKS_CLUSTER_NAME }}
```

### Azure Kubernetes Service (AKS)

**Prerequisites:**
- Azure subscription with AKS cluster
- Service Principal with AKS access
- GitHub Secrets configured with Azure credentials

**Setup Steps:**

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

2. **GitHub Secrets Configuration:**
```
AZURE_CLIENT_ID: your-client-id
AZURE_CLIENT_SECRET: your-client-secret
AZURE_SUBSCRIPTION_ID: your-subscription-id
AZURE_TENANT_ID: your-tenant-id
AKS_RESOURCE_GROUP: your-resource-group
AKS_CLUSTER_NAME: your-cluster-name
```

3. **GitHub Actions Workflow:**
```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- name: Configure kubectl
  run: |
    az aks get-credentials \
      --resource-group ${{ secrets.AKS_RESOURCE_GROUP }} \
      --name ${{ secrets.AKS_CLUSTER_NAME }}
```

## Local Development Authentication

### Minikube

**Setup:**
```bash
# Start Minikube
minikube start

# Verify kubectl configuration
kubectl config current-context
kubectl get nodes
```

### Kind (Kubernetes in Docker)

**Setup:**
```bash
# Create Kind cluster
kind create cluster --name deployment-pipeline

# Verify cluster
kubectl cluster-info --context kind-deployment-pipeline
```

### Docker Desktop Kubernetes

**Setup:**
1. Enable Kubernetes in Docker Desktop settings
2. Verify kubectl configuration:
```bash
kubectl config current-context
kubectl get nodes
```

## Deployment Pipeline Integration

### Environment-Specific Configuration

**Staging Environment:**
```yaml
- name: Deploy to Kubernetes (Staging)
  if: ${{ inputs.environment == "staging" }}
  run: |
    # Update image in deployment manifest
    sed -i "s|image: .*|image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest|g" k8s/deployment.yaml
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/deployment.yaml
    
    # Wait for deployment rollout
    kubectl rollout status deployment/deployment-pipeline-api --timeout=300s
    
    # Verify deployment
    kubectl get pods -l app=deployment-pipeline-api
    kubectl get services deployment-pipeline-api-service
```

**Production Environment:**
```yaml
- name: Deploy to Kubernetes (Production)
  if: ${{ inputs.environment == "production" }}
  run: |
    # Update image in deployment manifest
    sed -i "s|image: .*|image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest|g" k8s/deployment.yaml
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/deployment.yaml
    
    # Wait for deployment rollout (longer timeout for production)
    kubectl rollout status deployment/deployment-pipeline-api --timeout=600s
    
    # Verify deployment
    kubectl get pods -l app=deployment-pipeline-api
    kubectl get services deployment-pipeline-api-service
    
    # Health check with external URL
    SERVICE_URL=$(kubectl get service deployment-pipeline-api-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    curl -f http://$SERVICE_URL/health
```

### Health Check Configuration

**Service Health Check:**
```yaml
# k8s/deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: deployment-pipeline-api
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

**External Health Check:**
```bash
# Get service external IP
SERVICE_URL=$(kubectl get service deployment-pipeline-api-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Health check
curl -f http://$SERVICE_URL/health

# Or for port-forward testing
kubectl port-forward service/deployment-pipeline-api-service 8080:80 &
curl -f http://localhost:8080/health
```

## Security Best Practices

### RBAC Configuration

**Service Account:**
```yaml
# k8s/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: deployment-pipeline-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-pipeline-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["services", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-pipeline-rolebinding
subjects:
- kind: ServiceAccount
  name: deployment-pipeline-sa
roleRef:
  kind: Role
  name: deployment-pipeline-role
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies

**Network Security:**
```yaml
# k8s/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deployment-pipeline-netpol
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

## Troubleshooting

### Common Issues

**Authentication Errors:**
```bash
# Check kubectl configuration
kubectl config current-context
kubectl config get-contexts

# Test cluster connectivity
kubectl cluster-info
kubectl get nodes
```

**Deployment Issues:**
```bash
# Check deployment status
kubectl get deployments
kubectl describe deployment deployment-pipeline-api

# Check pod status
kubectl get pods -l app=deployment-pipeline-api
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check service status
kubectl get services
kubectl describe service deployment-pipeline-api-service
```

**Rollout Issues:**
```bash
# Check rollout status
kubectl rollout status deployment/deployment-pipeline-api

# Check rollout history
kubectl rollout history deployment/deployment-pipeline-api

# Rollback if needed
kubectl rollout undo deployment/deployment-pipeline-api
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

## Best Practices

### Security
1. **Use least privilege** - Grant minimal required permissions
2. **Rotate credentials** - Regularly update service account keys
3. **Network segmentation** - Use network policies for security
4. **Secret management** - Use Kubernetes secrets or external secret management

### Reliability
1. **Health checks** - Implement comprehensive liveness and readiness probes
2. **Rollout strategies** - Use rolling updates with proper timeouts
3. **Resource limits** - Set appropriate CPU and memory limits
4. **Monitoring** - Implement comprehensive monitoring and alerting

### Performance
1. **Resource optimization** - Right-size containers and requests
2. **Scaling** - Configure horizontal pod autoscaling
3. **Caching** - Implement appropriate caching strategies
4. **Load balancing** - Use proper service load balancing

---

**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**Platform**: Multi-cloud Kubernetes support  
**Security**: RBAC and network policies  
**Monitoring**: Health checks and external validation**
