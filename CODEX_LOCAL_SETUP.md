# 🤖 Codex-Local Agent Setup Complete

**Test Bed Environment**: `C:\otel\third_party\resonai`  
**Agent Type**: Embedded GPT-5-Codex operator  
**Purpose**: Local developer ergonomics and background maintenance

## ✅ What's Been Set Up

### 1. Agent Configuration
- **`.agent/config.json`** - Agent settings, budgets, and job definitions
- **`.agent/state.json`** - Current state and metrics tracking
- **`.agent/agent_queue.json`** - Job queue and processing status
- **`.agent/README.md`** - Comprehensive documentation

### 2. Agent Scripts
- **`scripts/agent/runner.js`** - Main agent execution engine
- **`scripts/agent/doctor.js`** - Health check and validation tool
- **Package.json scripts** - Easy command-line interface

### 3. Integration Features
- **OTel Integration** - Telemetry to `http://localhost:14318`
- **SigNoz Monitoring** - Dashboard at `http://localhost:8080`
- **Budget Controls** - Strict limits on jobs, files, and LOC
- **Kill Switch** - `.agent/LOCK` file for safe pausing

## 🚀 Available Commands

```bash
# Health check
pnpm agent:local:doctor

# Run agent once
pnpm agent:local

# Start agent in watch mode
pnpm agent:local:start

# Stop agent (create lock)
pnpm agent:local:stop

# Resume agent (remove lock)
pnpm agent:local:resume
```

## 🎯 Agent Capabilities

### Job Types
- **SSOT Refresh** - Regenerate single source of truth artifacts
- **Flake Quarantine** - Tag and isolate flaky tests
- **Selector Hygiene** - Add data-testid and ARIA attributes
- **CSP/A11y Fixes** - Remove inline styles, enforce accessibility
- **Docs Drift** - Update TASKS.md and DECISIONS.md

### Guardrails
- **No Inline Styles** - Enforce CSS classes
- **No dangerouslySetInnerHTML** - Prevent XSS
- **ARIA Live Regions** - Accessibility for dynamic content
- **Reduced Motion Support** - Respect user preferences
- **Strict CSP** - Content Security Policy compliance

### Budgets
- **Max Jobs Per Pass**: 2
- **Max Files Per Job**: 10
- **Max Lines of Code**: 200
- **Max Execution Time**: 300 seconds

## 🔍 Monitoring & Observability

### Local Monitoring
- **State File**: `.agent/state.json` - Current agent status
- **Queue File**: `.agent/agent_queue.json` - Job processing status
- **Health Checks**: `pnpm agent:local:doctor` - Comprehensive validation

### OTel Integration
- **Service Name**: `resonai-local`
- **Endpoint**: `http://localhost:14318`
- **Metrics**: Job processing, health status, error rates

### SigNoz Dashboards
- **Agent Health**: Monitor agent status and performance
- **Job Processing**: Track success/failure rates
- **Error Tracking**: Monitor and alert on issues

## 🛠️ Development Workflow

### 1. Start Development
```bash
# Start Resonai dev server
pnpm dev

# Start OTel collector (if not running)
# (Already running as Windows service)

# Start SigNoz (if not running)
# (Already running in Docker)

# Start codex-local agent
pnpm agent:local:start
```

### 2. Monitor Health
```bash
# Check agent health
pnpm agent:local:doctor

# Check OTel integration
.\Test-ResonaiStack.ps1

# Check SigNoz dashboards
# Open http://localhost:8080
```

### 3. Debug Issues
```bash
# Pause agent for debugging
pnpm agent:local:stop

# Check agent logs
# (Logs are in state.json and queue files)

# Resume agent
pnpm agent:local:resume
```

## 📊 Expected Data Flow

```
Resonai Code Changes
        ↓
Codex-Local Agent (Background)
        ↓
OTel Collector (14317/14318)
        ↓
SigNoz (8080)
        ↓
Dashboards & Alerts
```

## 🎯 Success Criteria

- **Agent Running**: `pnpm agent:local:doctor` shows all green
- **OTel Integration**: Canaries flowing to SigNoz
- **Resonai Working**: http://localhost:3003 accessible
- **Mic Debug**: http://localhost:3003/labs/mic-debug working
- **Observability**: Data visible in SigNoz dashboards

## 🔧 Troubleshooting

### Agent Not Starting
```bash
# Check health
pnpm agent:local:doctor

# Verify dependencies
pnpm install

# Check lock status
ls .agent/LOCK
```

### OTel Integration Issues
```bash
# Check collector status
Get-Service otelcol-contrib

# Test canaries
.\Test-ResonaiStack.ps1

# Check SigNoz
wsl -e bash -lc "docker ps | grep signoz"
```

### Resonai Issues
```bash
# Check dev server
pnpm dev

# Test mic debug
# Open http://localhost:3003/labs/mic-debug

# Check browser console
# Look for crossOriginIsolated = true
```

## 🎉 Ready for Development!

The codex-local agent is now set up and ready to maintain healthy local developer workflows in the Resonai test bed environment. It will:

- **Monitor** pnpm scripts, devcontainers, and environment parity
- **Enforce** CSP/a11y guardrails and remove unsafe patterns
- **Process** background maintenance jobs within strict budgets
- **Integrate** with OTel observability for monitoring and alerting

**Next Steps:**
1. Run `pnpm agent:local:doctor` to verify setup
2. Start the agent with `pnpm agent:local:start`
3. Begin development and watch the agent maintain code quality
4. Monitor progress in SigNoz dashboards

---

**Test Bed Status**: ✅ **Ready**  
**Agent Status**: ✅ **Configured**  
**Integration Status**: ✅ **Connected**  
**Development Status**: 🚀 **Go!**



