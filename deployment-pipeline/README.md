# Deployment Pipeline API

A minimal REST API service implementing the Tetragrammaton YHWH (Yod-He-Vav-He) architecture for comprehensive deployment pipeline validation and codex-local capability demonstration.

## Architecture Overview

### Tetragrammaton YHWH Structure

```
YOD (Foundation) ──► Core service logic and routing
     │
     ▼
HE (Interface) ────► HTTP API endpoints and request handling
     │
     ▼
VAV (Validation) ──► Input validation and error handling
     │
     ▼
HE (Integration) ──► Service orchestration and middleware integration
```

## Service Endpoints

### Health and Status
- `GET /health` - Service health check
- `GET /api/v1/status` - API status and available endpoints
- `GET /api/v1/metrics` - Service metrics and Tetragrammaton validation

### Core Functionality
- `POST /api/v1/echo` - Echo endpoint for testing request/response cycle

## Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

### Docker

```bash
# Build Docker image
docker build -t deployment-pipeline-api .

# Run container
docker run -p 3000:3000 deployment-pipeline-api

# Using Docker Compose
docker-compose up -d
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml

# Check deployment status
kubectl get pods -l app=deployment-pipeline-api

# Port forward for local access
kubectl port-forward service/deployment-pipeline-api-service 3000:80
```

## CI/CD Pipeline

The deployment pipeline includes:

1. **Build and Test** - Node.js dependency installation, linting, and test execution
2. **Docker Build** - Multi-stage Docker build with multi-architecture support
3. **Security Scan** - Trivy vulnerability scanning
4. **Deployment** - Kubernetes deployment to staging/production environments
5. **Smoke Tests** - Automated validation of deployed service endpoints

### GitHub Actions Workflow

The pipeline is triggered by:
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch with environment selection

### Metrics and Reporting

Comprehensive metrics collection includes:
- Build duration and dependency audit results
- Test coverage and execution results
- Docker image size and build metrics
- Deployment status and service health
- Tetragrammaton architecture validation

## Testing

### Unit Tests

The test suite validates all Tetragrammaton YHWH components:

- **YOD (Foundation)** - Core service logic and health checks
- **HE (Interface)** - API endpoints and request handling
- **VAV (Validation)** - Input validation and error handling
- **HE (Integration)** - Service orchestration and middleware

### Smoke Tests

Automated smoke tests validate:
- Health endpoint responsiveness
- API status endpoint functionality
- Echo endpoint request/response cycle
- Metrics endpoint accessibility

## Tetragrammaton Validation

The service implements comprehensive Tetragrammaton architecture validation:

### YOD (Foundation)
- Core service logic implemented
- Express.js routing configured
- Middleware integration complete

### HE (Interface)
- HTTP API endpoints operational
- Request handling implemented
- Response formatting standardized

### VAV (Validation)
- Input validation active
- Error handling implemented
- Security middleware configured

### HE (Integration)
- Service orchestration complete
- Health checks implemented
- Metrics collection active

## Metrics Capture

### Deployment Metrics Script

Use the deployment metrics capture script for comprehensive reporting:

```powershell
# Capture all metrics
pwsh -File scripts/deployment-metrics.ps1 -Action capture

# Generate ECRR report
pwsh -File scripts/deployment-metrics.ps1 -Action ecrr

# Validate pipeline configuration
pwsh -File scripts/deployment-metrics.ps1 -Action validate
```

### ECRR Framework Integration

All deployments follow the ECRR (Examine → Clean → Report → Role) framework:

- **Examine** - Environment validation and build setup
- **Clean** - Build, test, and deployment execution
- **Report** - Evidence collection and compliance documentation
- **Role** - Assigned actor responsibility (Deployment Pipeline Metrics)

## BossCat Governance Compliance

The deployment pipeline provides:

- **Evidence Collection** - Comprehensive metrics and artifact generation
- **ECRR Reporting** - Automated compliance documentation
- **Governance Visibility** - Executive-level deployment reports
- **Tetragrammaton Validation** - Architecture compliance verification

## Development Commands

```bash
# Development
npm run dev          # Start development server
npm run build        # Build application
npm run start        # Start production server

# Testing
npm test             # Run test suite
npm run test:watch   # Run tests in watch mode
npm run test:coverage # Run tests with coverage

# Quality
npm run lint         # Run ESLint
npm run lint:fix     # Fix ESLint issues

# Docker
npm run docker:build # Build Docker image
npm run docker:run   # Run Docker container
```

## Environment Variables

- `NODE_ENV` - Environment (development, production)
- `PORT` - Service port (default: 3000)

## Dependencies

### Production
- `express` - Web framework
- `cors` - Cross-origin resource sharing
- `helmet` - Security middleware
- `morgan` - HTTP request logger

### Development
- `jest` - Testing framework
- `supertest` - HTTP assertion library
- `nodemon` - Development server
- `eslint` - Code linting

## License

MIT License - see LICENSE file for details.

---

**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**Framework**: Node.js + Express  
**Container**: Docker with multi-stage build  
**Orchestration**: Kubernetes + Docker Compose  
**CI/CD**: GitHub Actions  
**Governance**: ECRR Framework + BossCat Compliance**
