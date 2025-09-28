# Resonai Backend Environment Configuration

## Required Environment Variables

Copy this file to `.env.local` and fill in your values:

```env
# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

# PostgreSQL connection string (required)
# Format: postgresql://username:password@host:port/database
DATABASE_URL="postgresql://resonai:your_password@localhost:5432/resonai_db"

# Alternative: SQLite for development (optional)
# DATABASE_URL="file:./dev.db"

# =============================================================================
# AUTHENTICATION & SECURITY
# =============================================================================

# NextAuth.js secret (required) - generate with: openssl rand -base64 32
NEXTAUTH_SECRET="your-nextauth-secret-key-here"

# NextAuth.js URL (required)
NEXTAUTH_URL="http://localhost:3000"

# User ID hashing salt (required) - generate with: openssl rand -base64 32
USER_HASH_SALT="your-user-hash-salt-here"

# Session configuration
SESSION_DURATION="86400000"  # 24 hours in milliseconds
REFRESH_TOKEN_DURATION="604800000"  # 7 days in milliseconds

# =============================================================================
# CORS & SECURITY
# =============================================================================

# Allowed origins for CORS (required)
ALLOWED_ORIGIN="http://localhost:3000"

# Additional allowed origins (comma-separated)
ADDITIONAL_ALLOWED_ORIGINS="https://resonai.app,https://staging.resonai.app"

# =============================================================================
# OBSERVABILITY (OPENTELEMETRY)
# =============================================================================

# SigNoz OTLP endpoint (required for observability)
OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:14317"

# Service name for tracing
OTEL_SERVICE_NAME="resonai-backend"

# Service version
OTEL_SERVICE_VERSION="1.0.0"

# Environment (development, staging, production)
OTEL_ENVIRONMENT="development"

# =============================================================================
# EMAIL CONFIGURATION (for magic links)
# =============================================================================

# SMTP configuration for magic link emails
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"
SMTP_FROM="Resonai <noreply@resonai.app>"

# Alternative: SendGrid
# SENDGRID_API_KEY="your-sendgrid-api-key"
# SENDGRID_FROM_EMAIL="noreply@resonai.app"

# =============================================================================
# RATE LIMITING
# =============================================================================

# Redis URL for rate limiting (optional - uses in-memory if not set)
REDIS_URL="redis://localhost:6379"

# Rate limit configurations
RATE_LIMIT_AUTH_REQUESTS="5"
RATE_LIMIT_AUTH_WINDOW_MS="900000"  # 15 minutes

RATE_LIMIT_USER_REQUESTS="100"
RATE_LIMIT_USER_WINDOW_MS="900000"  # 15 minutes

RATE_LIMIT_EVENTS_REQUESTS="1000"
RATE_LIMIT_EVENTS_WINDOW_MS="60000"  # 1 minute

# =============================================================================
# FEATURE FLAGS
# =============================================================================

# Enable/disable features
FEATURE_MAGIC_LINK_AUTH="true"
FEATURE_PASSKEY_AUTH="true"
FEATURE_COACH_PORTAL="true"
FEATURE_STORY_PROGRESS="true"
FEATURE_FEEDBACK_SYSTEM="true"

# =============================================================================
# DATA RETENTION & PRIVACY
# =============================================================================

# Event retention period (in milliseconds)
EVENT_RETENTION_MS="3600000"  # 1 hour

# Session cleanup interval (in milliseconds)
SESSION_CLEANUP_INTERVAL_MS="3600000"  # 1 hour

# Coach grant expiration (in milliseconds)
COACH_GRANT_MAX_DURATION_MS="2592000000"  # 30 days

# =============================================================================
# DEVELOPMENT & DEBUGGING
# =============================================================================

# Node environment
NODE_ENV="development"

# Enable debug logging
DEBUG="resonai:*"

# Database query logging (development only)
PRISMA_LOG_LEVEL="query"

# =============================================================================
# PRODUCTION CONFIGURATION
# =============================================================================

# Production-specific settings (uncomment for production)

# # Database connection pooling
# DATABASE_CONNECTION_LIMIT="10"
# DATABASE_POOL_TIMEOUT="20000"

# # Security headers
# SECURE_HEADERS="true"
# CSP_REPORT_URI="https://your-domain.report-uri.com/r/d/csp/enforce"

# # Monitoring
# SENTRY_DSN="your-sentry-dsn"
# LOG_LEVEL="info"

# # CDN and static assets
# CDN_URL="https://cdn.resonai.app"
# STATIC_ASSETS_URL="https://assets.resonai.app"
```

## Environment-Specific Configurations

### Development (.env.local)
```env
NODE_ENV="development"
DEBUG="resonai:*"
PRISMA_LOG_LEVEL="query"
DATABASE_URL="file:./dev.db"
OTEL_ENVIRONMENT="development"
```

### Staging (.env.staging)
```env
NODE_ENV="production"
DEBUG=""
PRISMA_LOG_LEVEL="error"
DATABASE_URL="postgresql://resonai:password@staging-db:5432/resonai"
OTEL_ENVIRONMENT="staging"
ALLOWED_ORIGIN="https://staging.resonai.app"
```

### Production (.env.production)
```env
NODE_ENV="production"
DEBUG=""
PRISMA_LOG_LEVEL="error"
DATABASE_URL="postgresql://resonai:secure_password@prod-db:5432/resonai"
OTEL_ENVIRONMENT="production"
ALLOWED_ORIGIN="https://resonai.app"
SECURE_HEADERS="true"
```

## Security Checklist

### Required Secrets
- [ ] `NEXTAUTH_SECRET` - Generate with `openssl rand -base64 32`
- [ ] `USER_HASH_SALT` - Generate with `openssl rand -base64 32`
- [ ] `DATABASE_URL` - Use strong password
- [ ] `SMTP_PASSWORD` - Use app-specific password

### Optional Security Enhancements
- [ ] `REDIS_URL` - For distributed rate limiting
- [ ] `SENTRY_DSN` - For error monitoring
- [ ] `CSP_REPORT_URI` - For Content Security Policy monitoring

## Validation Script

Create `scripts/validate-env.js`:

```javascript
const requiredEnvVars = [
  'DATABASE_URL',
  'NEXTAUTH_SECRET',
  'NEXTAUTH_URL',
  'USER_HASH_SALT',
  'ALLOWED_ORIGIN',
  'OTEL_EXPORTER_OTLP_ENDPOINT',
];

const missing = requiredEnvVars.filter(key => !process.env[key]);

if (missing.length > 0) {
  console.error('❌ Missing required environment variables:');
  missing.forEach(key => console.error(`   - ${key}`));
  process.exit(1);
}

console.log('✅ All required environment variables are set');
```

Run with: `node scripts/validate-env.js`

## Docker Configuration

For Docker deployments, use environment files:

```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  resonai-backend:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://resonai:password@postgres:5432/resonai
      - NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
      - USER_HASH_SALT=${USER_HASH_SALT}
    env_file:
      - .env.production
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=resonai
      - POSTGRES_USER=resonai
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Vercel Configuration

For Vercel deployments, set environment variables in the dashboard or use `vercel env`:

```bash
# Set environment variables
vercel env add DATABASE_URL
vercel env add NEXTAUTH_SECRET
vercel env add USER_HASH_SALT
vercel env add ALLOWED_ORIGIN
vercel env add OTEL_EXPORTER_OTLP_ENDPOINT

# Deploy
vercel --prod
```

## Health Check Endpoint

The backend includes a health check endpoint that validates environment configuration:

```typescript
// GET /api/health
{
  "status": "healthy",
  "timestamp": "2024-01-27T10:00:00Z",
  "services": {
    "database": {
      "status": "healthy",
      "latency": 15
    },
    "otel": {
      "status": "healthy",
      "endpoint": "http://localhost:14317"
    }
  },
  "environment": {
    "nodeEnv": "development",
    "version": "1.0.0"
  }
}
```

## Troubleshooting

### Common Issues

**Database Connection Failed**
```bash
# Check database URL format
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1;"
```

**OTel Endpoint Unreachable**
```bash
# Check SigNoz is running
curl http://localhost:8080/api/v1/health

# Check OTLP endpoint
curl http://localhost:14317/v1/traces
```

**Rate Limiting Issues**
```bash
# Check Redis connection
redis-cli ping

# Or use in-memory fallback
unset REDIS_URL
```

**Missing Environment Variables**
```bash
# Validate all required variables
node scripts/validate-env.js
```

This configuration template ensures your Resonai backend is properly configured for development, staging, and production environments while maintaining security and privacy compliance.
