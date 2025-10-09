# Secure Environment Configuration Template

**🐾 BossCat OEM - Environment Variable Security Guide**

## Environment Variables Template

Create a `.env.local` file in your project root with the following template:

```bash
# BossCat OEM - Environment Configuration Template
# Copy this template to .env.local and fill in your actual values
# NEVER commit .env.local to version control

# SigNoz Configuration
SIGNOZ_API_KEY=your-signoz-api-key-here
SIGNOZ_API_URL=http://localhost:8080/api/v1
SIGNOZ_JWT_SECRET=your-jwt-secret-here

# OpenTelemetry Configuration
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:14317
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer your-signoz-api-key-here
OTEL_SERVICE_NAME=resonai-backend
OTEL_SERVICE_VERSION=1.0.0
OTEL_ENVIRONMENT=development

# Authentication & Security
NEXTAUTH_SECRET=your-nextauth-secret-key-here
NEXTAUTH_URL=http://localhost:3000

# Magic Link Configuration
MAGIC_LINK_SECRET=your-magic-link-secret-here

# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Third-Party API Keys (Optional)
# SENDGRID_API_KEY=your-sendgrid-api-key
# RESEND_API_KEY=re_your_resend_api_key
# DATADOG_API_KEY=your-datadog-api-key
# NEW_RELIC_API_KEY=your-newrelic-api-key

# Webhook Configuration
SIGNOZ_WEBHOOK_SECRET=your-secure-webhook-secret-here

# Development Settings
NODE_ENV=development
DEBUG=signoz:*

# Vercel Configuration (if deploying to Vercel)
VERCEL_REGION=iad1
VERCEL_URL=http://localhost:3000

# Cron Jobs Secret (for Vercel Cron)
CRON_SECRET=your-cron-secret-here
```

## Security Best Practices

### 1. Secret Generation
```bash
# Generate secure secrets using Node.js crypto
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Or using OpenSSL
openssl rand -hex 32
```

### 2. Environment Variable Loading
```typescript
// Use dotenv to load environment variables
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

// Validate required environment variables
const requiredEnvVars = [
  'SIGNOZ_API_KEY',
  'NEXTAUTH_SECRET',
  'MAGIC_LINK_SECRET'
];

requiredEnvVars.forEach(envVar => {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`);
  }
});
```

### 3. Secure Configuration Loading
```typescript
// lib/config.ts
export const config = {
  signoz: {
    apiKey: process.env.SIGNOZ_API_KEY!,
    apiUrl: process.env.SIGNOZ_API_URL || 'http://localhost:8080/api/v1',
    jwtSecret: process.env.SIGNOZ_JWT_SECRET!,
  },
  auth: {
    secret: process.env.NEXTAUTH_SECRET!,
    url: process.env.NEXTAUTH_URL || 'http://localhost:3000',
    magicLinkSecret: process.env.MAGIC_LINK_SECRET!,
  },
  email: {
    smtpHost: process.env.SMTP_HOST,
    smtpPort: parseInt(process.env.SMTP_PORT || '587'),
    smtpUser: process.env.SMTP_USER,
    smtpPassword: process.env.SMTP_PASSWORD,
  },
  webhooks: {
    signozSecret: process.env.SIGNOZ_WEBHOOK_SECRET!,
  },
  otel: {
    endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:14317',
    serviceName: process.env.OTEL_SERVICE_NAME || 'resonai-backend',
    serviceVersion: process.env.OTEL_SERVICE_VERSION || '1.0.0',
    environment: process.env.OTEL_ENVIRONMENT || 'development',
  },
};
```

## Secret Rotation Procedures

### 1. SigNoz API Key Rotation
```bash
# 1. Generate new API key in SigNoz UI
# 2. Update environment variable
export SIGNOZ_API_KEY="new-api-key-here"

# 3. Restart services
docker-compose restart signoz

# 4. Verify connectivity
curl -H "Authorization: Bearer $SIGNOZ_API_KEY" http://localhost:8080/api/v1/health
```

### 2. JWT Secret Rotation
```bash
# 1. Generate new JWT secret
JWT_SECRET=$(openssl rand -hex 32)

# 2. Update environment variable
export SIGNOZ_JWT_SECRET="$JWT_SECRET"

# 3. Update docker-compose.yml
sed -i "s/SIGNOZ_JWT_SECRET=.*/SIGNOZ_JWT_SECRET=$JWT_SECRET/" docker-compose.yml

# 4. Restart SigNoz
docker-compose restart signoz
```

## Security Validation

### 1. Pre-commit Hook for Secret Detection
```bash
#!/bin/bash
# .git/hooks/pre-commit
echo "🔍 Scanning for secrets..."

# Check for common secret patterns
if grep -r -E "(api[_-]?key|secret|password|token|auth[_-]?key|private[_-]?key|access[_-]?token)\s*[:=]\s*[\"'][^\"']{10,}[\"']" --exclude-dir=.git --exclude-dir=node_modules .; then
  echo "❌ Potential secrets detected! Please remove hardcoded secrets."
  exit 1
fi

echo "✅ No secrets detected."
exit 0
```

### 2. Environment Variable Validation
```typescript
// scripts/validate-env.ts
import { config } from '../lib/config';

function validateEnvironment() {
  const errors: string[] = [];
  
  // Check for placeholder values
  if (config.signoz.apiKey.includes('your-') || config.signoz.apiKey.includes('placeholder')) {
    errors.push('SIGNOZ_API_KEY appears to be a placeholder value');
  }
  
  if (config.auth.secret.includes('your-') || config.auth.secret.includes('placeholder')) {
    errors.push('NEXTAUTH_SECRET appears to be a placeholder value');
  }
  
  // Check secret strength
  if (config.auth.secret.length < 32) {
    errors.push('NEXTAUTH_SECRET should be at least 32 characters long');
  }
  
  if (errors.length > 0) {
    console.error('❌ Environment validation failed:');
    errors.forEach(error => console.error(`  - ${error}`));
    process.exit(1);
  }
  
  console.log('✅ Environment validation passed');
}

validateEnvironment();
```

## GitIgnore Configuration

Ensure `.env.local` is in your `.gitignore`:

```gitignore
# Environment files
.env.local
.env.production
.env.staging
.env.development

# Secrets and keys
*.key
*.pem
*.p12
secrets/
keys/

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock
```

## Production Deployment

### 1. Environment Variables in Production
- Use your cloud provider's secret management service
- Never store secrets in code or configuration files
- Rotate secrets regularly
- Monitor for secret leaks

### 2. Secret Scanning in CI/CD
```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Run GitGuardian
        uses: GitGuardian/ggshield-action@main
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
```

---

**🐾 BossCat OEM - Secure Environment Configuration**

*All secrets must be managed via environment variables, never hardcoded in source code.*
