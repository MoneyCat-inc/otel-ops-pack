# Deployment Pipeline User Guide

## Overview

This guide provides comprehensive instructions for using the Deployment Pipeline API, implementing the Tetragrammaton YHWH (Yod-He-Vav-He) architecture for end-to-end deployment validation.

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

### Docker Development

```bash
# Build and run with Docker Compose
docker-compose up -d

# Check service health
curl http://localhost:3000/health

# View logs
docker-compose logs -f deployment-pipeline-api
```

### Kubernetes Deployment

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml

# Check deployment status
kubectl get pods -l app=deployment-pipeline-api

# Port forward for local access
kubectl port-forward service/deployment-pipeline-api-service 3000:80
```

## API Endpoints

### Health Check
```bash
GET /health
```
Returns service health status, uptime, and basic metrics.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-06T01:00:00.000Z",
  "service": "deployment-pipeline-api",
  "version": "1.0.0",
  "environment": "production",
  "uptime": 3600
}
```

### API Status
```bash
GET /api/v1/status
```
Returns API status and available endpoints.

**Response:**
```json
{
  "message": "Deployment Pipeline API is operational",
  "timestamp": "2025-10-06T01:00:00.000Z",
  "endpoints": [
    "GET /health",
    "GET /api/v1/status",
    "POST /api/v1/echo",
    "GET /api/v1/metrics"
  ]
}
```

### Echo Endpoint
```bash
POST /api/v1/echo
Content-Type: application/json

{
  "message": "Hello, Tetragrammaton!"
}
```

**Response:**
```json
{
  "echo": "Hello, Tetragrammaton!",
  "timestamp": "2025-10-06T01:00:00.000Z",
  "processed": true,
  "length": 23
}
```

### Metrics Endpoint
```bash
GET /api/v1/metrics
```
Returns comprehensive service metrics and Tetragrammaton validation.

**Response:**
```json
{
  "timestamp": "2025-10-06T01:00:00.000Z",
  "service": "deployment-pipeline-api",
  "version": "1.0.0",
  "environment": "production",
  "uptime": 3600,
  "memory": {
    "used": 45,
    "total": 128
  },
  "tetragrammaton": {
    "architecture": "YHWH (Yod-He-Vav-He)",
    "yod_foundation": "Core service logic implemented",
    "he_interface": "HTTP API endpoints operational",
    "vav_validation": "Input validation active",
    "he_integration": "Service orchestration complete"
  }
}
```

## Tetragrammaton Architecture

### YOD (Foundation)
Core service logic and routing implementation:
- Express.js application setup
- Middleware configuration
- Route definitions
- Core business logic

### HE (Interface)
HTTP API endpoints and request handling:
- RESTful endpoint implementation
- Request/response processing
- Content negotiation
- API documentation

### VAV (Validation)
Input validation and error handling:
- Request validation middleware
- Error handling and formatting
- Security middleware (Helmet, CORS)
- Input sanitization

### HE (Integration)
Service orchestration and middleware integration:
- Health check implementation
- Metrics collection
- Service lifecycle management
- External integrations

## CI/CD Pipeline Usage

### Manual Workflow Dispatch

Access: GitHub Actions → Workflows → Deployment Pipeline CI/CD → "Run workflow"

**Configuration Options:**
- `environment`: Choose deployment target (staging/production)
- `skip_tests`: Skip test execution (default: false)
- `skip_security`: Skip security scans (default: false)

### Pipeline Phases

1. **Build and Test** - Node.js setup, dependencies, linting, testing
2. **Security Scan** - npm audit and vulnerability scanning
3. **Docker Build** - Multi-architecture image build and push
4. **Deploy** - Docker Compose or Kubernetes deployment
5. **Smoke Tests** - Automated endpoint validation
6. **ECRR Evidence** - Metrics capture and compliance reporting

### Monitoring Deployment

```bash
# Check pipeline status
gh run list --workflow="Deployment Pipeline CI/CD"

# View pipeline logs
gh run view <run-id> --log

# Download artifacts
gh run download <run-id>
```

## Metrics and Monitoring

### Deployment Metrics Script

```powershell
# Capture all metrics
pwsh scripts/deployment-metrics.ps1 -Action capture

# Generate ECRR report
pwsh scripts/deployment-metrics.ps1 -Action ecrr

# Validate pipeline configuration
pwsh scripts/deployment-metrics.ps1 -Action validate
```

### Metrics Collection

The deployment metrics script captures:
- Build duration and dependency audit results
- Test coverage and execution results
- Docker image size and build metrics
- Deployment status and service health
- Tetragrammaton architecture validation

### ECRR Framework Integration

All deployments follow the ECRR (Examine → Clean → Report → Role) framework:
- **Examine**: Environment validation and build setup
- **Clean**: Build, test, and deployment execution
- **Report**: Evidence collection and compliance documentation
- **Role**: Assigned actor responsibility (Deployment Pipeline Metrics)

## Troubleshooting

### Common Issues

**Service Not Starting:**
```bash
# Check logs
docker-compose logs deployment-pipeline-api

# Verify port availability
netstat -tulpn | grep :3000

# Check dependencies
npm install
```

**Health Check Failing:**
```bash
# Manual health check
curl -v http://localhost:3000/health

# Check service status
docker-compose ps

# Restart service
docker-compose restart deployment-pipeline-api
```

**Tests Failing:**
```bash
# Run tests with verbose output
npm test -- --verbose

# Check test coverage
npm run test:coverage

# Run specific test
npm test -- --testNamePattern="Health Check"
```

### Debug Mode

```bash
# Enable debug logging
DEBUG=* npm start

# Verbose test output
npm test -- --verbose

# Docker debug mode
docker-compose -f docker-compose.yml -f docker-compose.debug.yml up
```

## Best Practices

### Development Workflow

1. **Always test locally first**
2. **Run full test suite before committing**
3. **Use meaningful commit messages**
4. **Document API changes**
5. **Monitor deployment metrics**

### Security Considerations

- Use non-root user in Docker containers
- Regular dependency updates and vulnerability scans
- Input validation and sanitization
- Security headers via Helmet middleware
- CORS configuration for cross-origin requests

### Performance Optimization

- Multi-stage Docker builds for smaller images
- Resource limits in Kubernetes deployments
- Health checks for service reliability
- Metrics collection for monitoring
- Caching strategies for improved performance

## Environment Configuration

### Environment Variables

- `NODE_ENV`: Environment mode (development/production)
- `PORT`: Service port (default: 3000)
- `HEALTH_CHECK_URL`: Health check endpoint URL

### Docker Environment

```yaml
environment:
  - NODE_ENV=production
  - PORT=3000
```

### Kubernetes Environment

```yaml
env:
- name: NODE_ENV
  value: "production"
- name: PORT
  value: "3000"
```

## Support and Documentation

### Additional Resources

- [API Documentation](API_REFERENCE.md)
- [Tetragrammaton Architecture](TETRAGRAMMATON_ARCHITECTURE.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

### Contact

For issues or questions:
- Check existing documentation
- Review ECRR reports in `docs/ecrr/ECRR_REPORTS/`
- Examine deployment metrics in `docs/metrics/`
- Submit GitHub issues with detailed information

---

**Architecture**: Tetragrammaton YHWH (Yod-He-Vav-He)  
**Framework**: Node.js + Express  
**Container**: Docker with multi-stage build  
**Orchestration**: Kubernetes + Docker Compose  
**CI/CD**: GitHub Actions  
**Governance**: ECRR Framework + BossCat Compliance**
