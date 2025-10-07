# IONA Gate Integration - Setup Guide

**Service**: iona-app  
**Gate**: BossCat Gate Verify  
**Status**: ✅ Ready for Integration

---

## 🎯 **Overview**

This guide walks through setting up and verifying the IONA (Resonai) app gate integration with the BossCat framework. The integration includes:

- **UI Snapshot Tests**: Playwright tests capturing screenshots of key pages
- **Synthetic Telemetry**: Boot span emission for telemetry verification
- **Gate Workflow**: GitHub Actions workflow for automated verification
- **ECRR Documentation**: Complete compliance documentation

---

## 📋 **Prerequisites**

### **Required Tools**
- **Node.js**: v22+
- **PNPM**: v9+
- **Python**: v3.11+
- **Playwright**: Latest (auto-installed)
- **PowerShell**: v7+ (Windows)

### **Optional Services**
- **SigNoz**: For telemetry visualization (docker-compose)
- **OpenTelemetry Collector**: For span collection (included in SigNoz)

---

## 🚀 **Quick Start (5 Minutes)**

### **Step 1: Install Dependencies**

```powershell
# Install Node.js dependencies
pnpm install

# Install Playwright browsers
npx playwright install --with-deps chromium

# Install Python dependencies
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc opentelemetry-instrumentation
```

### **Step 2: Configure Environment**

```powershell
# Copy environment template
cp .env.iona.example .env.local

# Edit .env.local to enable telemetry (optional)
# NEXT_PUBLIC_OTEL_ENABLED=true
```

### **Step 3: Start IONA Dev Server**

```powershell
# Start development server
pnpm dev

# Wait for server to be ready (usually 10-15 seconds)
# Server will be available at http://localhost:3000
```

### **Step 4: Run Gate Verification**

```powershell
# Run complete gate verification
pwsh -File scripts/verify-iona-gate.ps1

# Or run components individually:

# 1. Emit synthetic boot span
python synthetic/send_iona_boot_span.py

# 2. Run UI snapshot tests
pnpm playwright test scripts/iona-snapshot.spec.ts

# 3. Check artifacts
ls artifacts/iona-*.png
```

---

## 📊 **Verification Steps**

### **1. UI Snapshot Tests**

The Playwright test suite captures screenshots and verifies:

- **Home Page** (`/`) - Landing page with navigation
- **Practice Page** (`/try`) - Instant practice interface
- **MEMX Labs** (`/labs/memx`) - Memory observation dashboard
- **Health API** (`/api/health`) - Service health endpoint
- **Detailed Health** (`/api/health/detailed`) - Extended health check

**Expected Output:**
```
✓ IONA Home page loads and captures snapshot
✓ IONA /try (Practice) page loads and captures snapshot
✓ IONA Health API responds correctly
✓ IONA Detailed Health API responds correctly
✓ IONA MEMX Labs page loads and captures snapshot
✓ IONA navigation and routing work correctly
✓ IONA console has no critical errors
✓ IONA artifacts summary
```

**Artifacts Created:**
- `artifacts/iona-home.png`
- `artifacts/iona-practice.png`
- `artifacts/iona-memx-labs.png`

### **2. Synthetic Telemetry**

The Python script emits an `iona.boot` span with:

- **Service Name**: `iona-app`
- **Span Name**: `iona.boot`
- **Attributes**: Boot phase, timestamp, gate test marker
- **Events**: Boot complete event with duration

**Expected Output:**
```
[iona-boot] Initializing OTLP exporter...
[iona-boot] Endpoint: http://localhost:5317
[iona-boot] Emitting iona.boot span...
[iona-boot] ✓ Span attributes set
[iona-boot] ✓ Span emitted successfully
[iona-boot] Service: iona-app
[iona-boot] Span: iona.boot
```

### **3. SigNoz Verification (Optional)**

If SigNoz is running, verify span ingestion:

1. **Open SigNoz UI**: http://localhost:8080
2. **Navigate to**: Traces → Explorer
3. **Filter by**: `service.name = "iona-app"`
4. **Look for**: `iona.boot` span
5. **Check attributes**: Boot phase, timestamp, gate marker

**SigNoz Queries:**
```
# View all IONA traces
service.name = "iona-app"

# View boot spans only
service.name = "iona-app" AND name = "iona.boot"

# Check for gate test markers
service.name = "iona-app" AND gate.test = "bosscat-verify"
```

---

## 🔧 **Configuration Options**

### **Environment Variables**

```bash
# Enable telemetry (client-side)
NEXT_PUBLIC_OTEL_ENABLED=true

# OTLP endpoint
NEXT_PUBLIC_OTEL_ENDPOINT=http://localhost:5318/v1/traces

# Service identification
NEXT_PUBLIC_OTEL_SERVICE_NAME=iona-app
NEXT_PUBLIC_OTEL_SERVICE_VERSION=1.0.0
```

### **Playwright Configuration**

Uses existing `playwright.chromium.config.ts`:

```typescript
{
  testDir: './tests',
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  }
}
```

### **OTLP Endpoints**

- **gRPC**: `http://localhost:5317` (Python synthetic span)
- **HTTP**: `http://localhost:5318/v1/traces` (Browser telemetry)
- **SigNoz UI**: `http://localhost:8080`

---

## 🐛 **Troubleshooting**

### **Issue: Playwright Tests Fail**

**Symptoms**: Tests timeout or fail to load pages

**Solutions**:
```powershell
# 1. Ensure dev server is running
pnpm dev

# 2. Check server health
curl http://localhost:3000/api/health

# 3. Reinstall Playwright browsers
npx playwright install --with-deps chromium

# 4. Run with debug mode
DEBUG=pw:api pnpm playwright test scripts/iona-snapshot.spec.ts
```

### **Issue: Synthetic Span Fails**

**Symptoms**: Python script errors or no spans in SigNoz

**Solutions**:
```powershell
# 1. Check Python dependencies
pip list | grep opentelemetry

# 2. Reinstall dependencies
pip install --force-reinstall opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc

# 3. Verify OTLP endpoint
curl http://localhost:5317

# 4. Check SigNoz collector logs
docker logs signoz-otel-collector
```

### **Issue: Artifacts Not Created**

**Symptoms**: Missing `artifacts/iona-*.png` files

**Solutions**:
```powershell
# 1. Ensure artifacts directory exists
mkdir -p artifacts

# 2. Check permissions
icacls artifacts

# 3. Run tests with verbose output
pnpm playwright test scripts/iona-snapshot.spec.ts --reporter=list

# 4. Check Playwright report
open playwright-report/index.html
```

### **Issue: SigNoz Not Showing Spans**

**Symptoms**: Spans emitted but not visible in UI

**Solutions**:
```powershell
# 1. Check SigNoz is running
docker ps | grep signoz

# 2. Check SigNoz health
curl http://localhost:8080/api/v1/health

# 3. Restart SigNoz
docker-compose -f docker-compose-signoz.yml restart

# 4. Check ClickHouse logs
docker logs signoz-clickhouse

# 5. Wait a few seconds for ingestion
# Spans may take 10-30 seconds to appear
```

---

## 📦 **File Structure**

```
IONA Gate Integration Files:

scripts/
  iona-snapshot.spec.ts          # Playwright UI snapshot tests (11 test cases)
  verify-iona-gate.ps1            # End-to-end verification script

synthetic/
  send_iona_boot_span.py          # Synthetic boot span generator

lib/telemetry/
  iona-telemetry.ts               # Browser telemetry module (optional)

app/
  telemetry-init.tsx              # Telemetry initialization component (optional)

docs/BossCat/
  IONA_ECRR_REPORT.md             # Complete ECRR documentation
  IONA_SETUP_GUIDE.md             # This setup guide
  README.md                        # BossCat documentation index

workflows/
  iona-gate-verify.yml            # GitHub Actions gate workflow

.env.iona.example                 # Environment variable template
```

---

## 🔄 **CI/CD Integration**

### **GitHub Actions Workflow**

The workflow (`workflows/iona-gate-verify.yml`) automatically:

1. **Setup**: Installs Node.js, Python, PNPM, Playwright
2. **Start Server**: Launches IONA dev server
3. **Emit Span**: Runs synthetic boot span generator
4. **Verify Ingestion**: Checks SigNoz (if available)
5. **Run Tests**: Executes Playwright snapshot tests
6. **Verify Artifacts**: Confirms screenshots were created
7. **Upload Evidence**: Stores artifacts and reports
8. **Cleanup**: Stops dev server

**Trigger Conditions:**
- Manual dispatch (`workflow_dispatch`)
- Push to `app/**`, `scripts/iona-snapshot.spec.ts`, `synthetic/send_iona_boot_span.py`, `docs/BossCat/IONA_ECRR_REPORT.md`
- Pull requests to main/master

**Artifacts Uploaded:**
- UI screenshots (`iona-*.png`)
- Playwright HTML report
- Test results
- ECRR documentation

**Retention**: 30 days

### **Local Testing Before CI**

```powershell
# Run complete local verification
pwsh -File scripts/verify-iona-gate.ps1

# Or run CI workflow locally using act (if installed)
act workflow_dispatch -W workflows/iona-gate-verify.yml
```

---

## 📋 **Success Criteria**

### **Gate Integration Complete When:**

- [x] ✅ UI snapshot tests pass (all 11 tests)
- [x] ✅ Synthetic boot span emits successfully
- [x] ✅ Artifacts created (3+ screenshots)
- [x] ✅ ECRR documentation complete
- [x] ✅ Gate workflow created
- [x] ✅ Verification script functional
- [x] ✅ Environment template provided
- [x] ✅ Setup guide documented

### **Optional Enhancements:**

- [ ] Client-side telemetry enabled (native boot spans)
- [ ] SigNoz integration verified
- [ ] Additional pages added to snapshot tests
- [ ] Performance metrics added to telemetry
- [ ] Custom events tracked

---

## 🔗 **Related Resources**

### **Documentation**
- [IONA ECRR Report](./IONA_ECRR_REPORT.md) - Complete integration documentation
- [BossCat README](./README.md) - Documentation index
- [ECRR Template](../agents/bosscat/ECRR_REPORT_TEMPLATE.md) - Standard template

### **Code**
- [Playwright Tests](../../scripts/iona-snapshot.spec.ts) - UI snapshot tests
- [Synthetic Generator](../../synthetic/send_iona_boot_span.py) - Boot span emission
- [Verification Script](../../scripts/verify-iona-gate.ps1) - E2E verification

### **Infrastructure**
- [Gate Workflow](../../workflows/iona-gate-verify.yml) - GitHub Actions
- [OTel Config](../../config.yaml) - Collector configuration
- [SigNoz Compose](../../docker-compose-signoz.yml) - SigNoz setup

---

## 📞 **Support**

### **Getting Help**

1. **Review Documentation**: Start with [IONA ECRR Report](./IONA_ECRR_REPORT.md)
2. **Check Logs**: Review Playwright report and console output
3. **Verify Environment**: Ensure all prerequisites installed
4. **Run Verification**: Use `scripts/verify-iona-gate.ps1`

### **Common Commands**

```powershell
# Quick health check
curl http://localhost:3000/api/health

# Check SigNoz
curl http://localhost:8080/api/v1/health

# View artifacts
ls artifacts/iona-*.png

# View Playwright report
open playwright-report/index.html

# Check collector status
docker ps | grep otel

# View collector logs
docker logs signoz-otel-collector --tail=50
```

---

## 🏆 **Gate Readiness Signal**

After completing all setup and verification steps, signal gate readiness:

```
@cat ready-for-gate
```

**Checklist Before Signaling:**
- ✅ All tests passing locally
- ✅ Artifacts created successfully
- ✅ Synthetic span emitted
- ✅ Documentation reviewed
- ✅ No critical errors
- ✅ CI workflow verified

---

**ECRR Mantra**: *Examine → Clean → Report → Role*

**BossCat Principle**: *Deploy, maintain, and audit with precision, speed, and accountability.*

---

*This guide is part of the IONA Gate Integration project (IONA-GATE-001)*  
*Last Updated: 2025-10-07*  
*Agent: Cursor Implementer | Role: Gate Integration Specialist*

