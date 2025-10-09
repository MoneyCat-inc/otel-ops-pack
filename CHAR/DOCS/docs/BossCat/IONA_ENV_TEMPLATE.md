# IONA Environment Configuration Template

**Service**: iona-app  
**Purpose**: Configure OpenTelemetry for IONA gate integration

---

## 📋 **Environment Variables**

Copy these variables to your `.env.local` file to enable telemetry:

```bash
# IONA Telemetry Configuration
# Enable/disable OpenTelemetry (default: false in production, true in development)
NEXT_PUBLIC_OTEL_ENABLED=true

# OTLP HTTP endpoint (default: http://localhost:5318/v1/traces)
NEXT_PUBLIC_OTEL_ENDPOINT=http://localhost:5318/v1/traces

# Service name (default: iona-app)
NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app

# Service version (default: 1.0.0)
NEXT_PUBLIC_OTEL_SERVICE_VERSION=1.0.0

# Node environment
NODE_ENV=development
```

---

## 🚀 **Quick Setup**

### **Option 1: Manual Setup**

```powershell
# Create .env.local file
echo "NEXT_PUBLIC_OTEL_ENABLED=true" > .env.local
echo "NEXT_PUBLIC_OTEL_ENDPOINT=http://localhost:5318/v1/traces" >> .env.local
echo "NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app" >> .env.local
echo "NEXT_PUBLIC_OTEL_SERVICE_VERSION=1.0.0" >> .env.local
```

### **Option 2: Copy from Template**

```powershell
# If you have .env.iona.example (create it first):
cp .env.iona.example .env.local
```

---

## ⚙️ **Configuration Details**

### **NEXT_PUBLIC_OTEL_ENABLED**

Controls whether OpenTelemetry is active.

- **Type**: Boolean string (`"true"` or `"false"`)
- **Default**: `false` (production), `true` (development)
- **Usage**: Set to `"true"` to enable client-side telemetry

```bash
# Enable telemetry
NEXT_PUBLIC_OTEL_ENABLED=true

# Disable telemetry
NEXT_PUBLIC_OTEL_ENABLED=false
```

### **NEXT_PUBLIC_OTEL_ENDPOINT**

The OTLP HTTP endpoint for trace export.

- **Type**: URL string
- **Default**: `http://localhost:5318/v1/traces`
- **Usage**: Points to OpenTelemetry Collector or SigNoz

```bash
# Local collector
NEXT_PUBLIC_OTEL_ENDPOINT=http://localhost:5318/v1/traces

# Custom endpoint
NEXT_PUBLIC_OTEL_ENDPOINT=https://otel.example.com/v1/traces
```

### **NEXT_PUBLIC_OTEL_SERVICE_NAME**

Identifies the service in telemetry data.

- **Type**: String
- **Default**: `iona-app`
- **Usage**: Service name for filtering traces

```bash
# Default service name
NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app

# Custom service name
NEXT_PUBLIC_OTEL_SERVICE_NAME=resonai-frontend
```

### **NEXT_PUBLIC_OTEL_SERVICE_VERSION**

Service version for telemetry tracking.

- **Type**: Semantic version string
- **Default**: `1.0.0`
- **Usage**: Version tracking for deployments

```bash
# Version 1.0.0
NEXT_PUBLIC_OTEL_SERVICE_VERSION=1.0.0

# Version 1.2.3
NEXT_PUBLIC_OTEL_SERVICE_VERSION=1.2.3
```

---

## 🔍 **Verification**

After setting environment variables:

```powershell
# 1. Restart dev server
pnpm dev

# 2. Check browser console for telemetry logs
# Look for: "[iona-telemetry] ✓ OpenTelemetry initialized"

# 3. Verify span emission
# Look for: "[iona-telemetry] ✓ Boot span emitted"

# 4. Check SigNoz UI
# Navigate to: http://localhost:8080
# Filter by: service.name = "iona-app"
```

---

## 🐛 **Troubleshooting**

### **Telemetry Not Starting**

**Symptoms**: No telemetry logs in console

**Check**:
```bash
# 1. Verify environment variable is set correctly
echo $env:NEXT_PUBLIC_OTEL_ENABLED

# 2. Restart dev server after changing .env.local
pnpm dev

# 3. Clear Next.js cache
rm -rf .next/
pnpm dev
```

### **Spans Not Appearing in SigNoz**

**Symptoms**: Telemetry initialized but no traces in UI

**Check**:
```powershell
# 1. Verify OTLP endpoint is reachable
curl http://localhost:5318/v1/traces

# 2. Check SigNoz is running
docker ps | grep signoz

# 3. Check collector logs
docker logs signoz-otel-collector --tail=50

# 4. Wait for ingestion (10-30 seconds)
```

### **CORS Errors**

**Symptoms**: Browser console shows CORS errors

**Solution**:
```yaml
# Update collector config (config.yaml) to allow CORS:
receivers:
  otlp:
    protocols:
      http:
        cors:
          allowed_origins:
            - "http://localhost:3000"
            - "http://127.0.0.1:3000"
```

---

## 📚 **Examples**

### **Example 1: Development Setup**

```bash
# .env.local for local development
NEXT_PUBLIC_OTEL_ENABLED=true
NEXT_PUBLIC_OTEL_ENDPOINT=http://localhost:5318/v1/traces
NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app
NEXT_PUBLIC_OTEL_SERVICE_VERSION=1.0.0
NODE_ENV=development
```

### **Example 2: Production Setup**

```bash
# .env.production for production deployment
NEXT_PUBLIC_OTEL_ENABLED=true
NEXT_PUBLIC_OTEL_ENDPOINT=https://otel.production.com/v1/traces
NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app
NEXT_PUBLIC_OTEL_SERVICE_VERSION=2.1.0
NODE_ENV=production
```

### **Example 3: Testing Setup**

```bash
# .env.test for CI/CD testing
NEXT_PUBLIC_OTEL_ENABLED=false
NEXT_PUBLIC_OTEL_ENDPOINT=http://localhost:5318/v1/traces
NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app-test
NEXT_PUBLIC_OTEL_SERVICE_VERSION=0.0.0-test
NODE_ENV=test
```

---

## 🔗 **Related Resources**

- [IONA Setup Guide](./IONA_SETUP_GUIDE.md) - Complete setup instructions
- [IONA ECRR Report](./IONA_ECRR_REPORT.md) - Integration documentation
- [Telemetry Module](../../lib/telemetry/iona-telemetry.ts) - Implementation code

---

*This template is part of the IONA Gate Integration project (IONA-GATE-001)*  
*Last Updated: 2025-10-07*  
*Agent: Cursor Implementer | Role: Gate Integration Specialist*

