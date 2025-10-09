# 🚀 Resonai Backend Implementation Guide

## Quick Start

This guide will help you implement the Resonai backend architecture with local-first, consent-first principles.

### Prerequisites

- Node.js 18+ 
- PostgreSQL (or SQLite for development)
- SigNoz running locally (for observability)

### 1. Setup

```bash
# Install dependencies
npm install

# Setup environment variables
cp .env.example .env.local
# Edit .env.local with your configuration

# Setup database
npm run db:push
npm run db:seed

# Start development server
npm run dev
```

### 2. Environment Configuration

Create `.env.local`:

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/resonai"

# Authentication
NEXTAUTH_SECRET="your-secret-key"
NEXTAUTH_URL="http://localhost:3000"

# Privacy & Security
USER_HASH_SALT="your-server-salt-for-hashing"

# Observability (SigNoz)
OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:14317"
OTEL_SERVICE_NAME="resonai-backend"

# CORS
ALLOWED_ORIGIN="http://localhost:3000"
```

### 3. Core API Endpoints

#### Events (Analytics)
```typescript
POST /api/events/batch
{
  "events": [
    {
      "kind": "session_start",
      "props": {
        "userId": "user_123",
        "sessionId": "session_456",
        "duration": 30000
      }
    }
  ]
}
```

#### Engagement Profile
```typescript
GET /api/me/engagement
PUT /api/me/engagement
{
  "streakDays": 7,
  "lastPracticeAt": "2024-01-27T10:00:00Z",
  "theme": "dark"
}
```

#### Consent Management
```typescript
GET /api/me/consent
PUT /api/me/consent
{
  "shareMetrics": true,
  "coachPortal": false
}
```

### 4. Privacy Compliance

#### Data Minimization
- Maximum 10 properties per event
- Maximum 50 events per batch
- No PII fields allowed
- Events expire after 1 hour

#### Consent Tracking
- All consent changes logged
- Audit trail maintained
- One-click data export/deletion

#### PII Prevention
```typescript
// ❌ These fields are rejected
{
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890"
}

// ✅ These fields are allowed
{
  "userIdHash": "a1b2c3d4e5f6",
  "sessionId": "session_456",
  "streakDays": 7
}
```

### 5. Observability Integration

#### OTel Tracing
All API routes automatically include:
- Request/response tracing
- Performance metrics
- Error tracking
- Custom attributes

#### SigNoz Queries
```sql
-- API Performance
SELECT 
  route,
  percentile(99, duration_ms) as p99_latency
FROM api_requests
WHERE timestamp > NOW() - INTERVAL '1 day'

-- Cohort Analytics
SELECT 
  cohort,
  COUNT(*) as events
FROM events 
WHERE kind = 'session_start'
GROUP BY cohort
```

### 6. Testing

#### Contract Tests
```bash
npm run test:contract
```
Ensures API contracts remain stable and privacy-compliant.

#### Privacy Validation
```bash
npm run test:privacy
```
Validates PII prevention and data minimization.

#### Full Test Suite
```bash
npm run test:coverage
```
Runs all tests with coverage reporting.

### 7. Deployment

#### Vercel (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

#### Environment Variables
Set these in your deployment environment:
- `DATABASE_URL`
- `NEXTAUTH_SECRET`
- `USER_HASH_SALT`
- `OTEL_EXPORTER_OTLP_ENDPOINT`

### 8. Monitoring & Alerting

#### Health Checks
- `GET /api/health` - Basic health check
- `GET /api/health/detailed` - Detailed system status

#### Key Metrics
- API response times (p95 < 200ms)
- Error rates (< 1%)
- Rate limit hits
- Privacy violations (should be 0)

#### SigNoz Dashboards
Import the provided dashboard configuration:
```bash
npm run otel:setup
```

### 9. Security Best Practices

#### Rate Limiting
- Authentication: 5 requests/15min
- User actions: 100 requests/15min  
- Events: 1000 requests/min
- Feedback: 10 requests/hour

#### Input Validation
- Zod schemas for all inputs
- PII detection and rejection
- Property count limits
- Data type validation

#### CORS & CSP
- Strict origin checking
- No inline scripts/styles
- Secure headers on all responses

### 10. Troubleshooting

#### Common Issues

**Database Connection**
```bash
# Check database status
npm run db:studio

# Reset database
npm run db:push --force-reset
```

**OTel Integration**
```bash
# Check SigNoz health
curl http://localhost:8080/api/v1/health

# Verify traces
# Check SigNoz UI at http://localhost:8080
```

**Privacy Violations**
```bash
# Run privacy audit
npm run privacy-audit

# Check for PII in logs
grep -r "email\|phone\|name" logs/
```

### 11. Development Workflow

#### Making Changes
1. Update schemas in `lib/validation/schemas.ts`
2. Add tests in `tests/contract/` and `tests/privacy/`
3. Update API routes in `app/api/`
4. Run validation: `npm run validate`
5. Deploy with confidence

#### Code Review Checklist
- [ ] Privacy compliance validated
- [ ] Contract tests pass
- [ ] OTel tracing included
- [ ] Rate limiting configured
- [ ] Input validation added
- [ ] Documentation updated

### 12. Next Steps

#### Phase 1: Core APIs (Week 1-2)
- [ ] Events batch endpoint
- [ ] Engagement profile sync
- [ ] Consent management
- [ ] Basic authentication

#### Phase 2: Advanced Features (Week 3-4)
- [ ] Coach portal with E2E encryption
- [ ] Narrative content API
- [ ] Feature flags system
- [ ] Data export/deletion

#### Phase 3: Scale & Polish (Week 5-6)
- [ ] Performance optimization
- [ ] Advanced monitoring
- [ ] Security hardening
- [ ] Documentation completion

---

This implementation provides a solid foundation for Resonai's backend while maintaining strict privacy compliance and local-first principles. The architecture scales from development to production while keeping audio processing entirely client-side.
