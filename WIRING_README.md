# OTel Pipeline Wiring System

> **Turn-key autowiring** for the OTel observability pipeline with automated maintenance, health monitoring, and ECRR integration.

## 🚀 One-Command Setup

```bash
# Complete wiring initialization
pnpm wire:init

# Verify everything is working
pnpm wire:verify

# Check pipeline health
pnpm wire:health
```

## 📋 What Gets Wired

### ✅ Agent Infrastructure
- Background watchdog with budgets (max 2 jobs, 10 files, 200 lines)
- Kill-switch support (`.agent/LOCK`)
- Job queue with retry logic and TTL
- Health monitoring and diagnostics

### ✅ ECRR Integration
- Automatic report ingestion from `ecrr/reports/`
- Gap extraction and task generation
- Index maintenance and backlog management
- Summary report generation

### ✅ Health Monitoring
- Docker service status (SigNoz containers)
- Windows OTel Collector service health
- SigNoz endpoint verification
- Real-time status reporting

### ✅ Verification Suite
- Infrastructure validation
- Configuration integrity checks
- Script availability verification
- Comprehensive health reports

## 🎯 Available Commands

| Command | Purpose |
|---------|---------|
| `pnpm wire:init` | Initialize complete wiring system |
| `pnpm wire:verify` | Verify all components are healthy |
| `pnpm wire:health` | Check pipeline health status |
| `pnpm agent:start` | Start background agent |
| `pnpm agent:doctor` | Agent health diagnostics |
| `pnpm ecrr:wire` | Process ECRR reports and generate tasks |

## 🔧 Agent Management

### Start/Stop Agent
```bash
# Start background agent
pnpm agent:start

# Pause agent (kill switch)
echo > .agent/LOCK

# Resume agent
rm .agent/LOCK

# Check agent health
pnpm agent:doctor
```

### Agent Budgets
- **Max Jobs**: 2 concurrent jobs
- **Max Files**: 10 files per job
- **Max Lines**: 200 lines per job
- **Job TTL**: 12 hours
- **Max Attempts**: 3 retries
- **Backoff**: 15 minutes between retries

## 📊 Health Monitoring

### Automated Checks
- **Every 5 minutes**: Health checks
- **Every 15 minutes**: Canary tests
- **Every hour**: ECRR reports

### Health Reports
- `artifacts/agent-health-report.json` - Agent status
- `artifacts/ecrr-wiring-report.json` - ECRR processing status

## 📝 ECRR Report Format

Place reports in `ecrr/reports/` with `.md` extension:

```markdown
# ECRR Report: Pipeline Health

## Critical Gaps
- Missing health check automation
- Inadequate error handling

## Recommendations
- Implement automated health checks
- Add comprehensive error handling

## Action Items
- [ ] Deploy health check script
- [ ] Update collector configuration
```

## 🛠️ Troubleshooting

### Common Issues

1. **Agent not starting**
   ```bash
   # Check Node.js version (18+ required)
   node --version
   
   # Recreate agent infrastructure
   pnpm wire:init
   ```

2. **Health checks failing**
   ```bash
   # Verify Docker services
   docker ps
   
   # Check Windows service
   sc query otelcol-contrib
   
   # Test SigNoz endpoint
   curl http://localhost:8080/api/v1/health
   ```

3. **ECRR reports not processing**
   ```bash
   # Check report directory
   ls -la ecrr/reports/
   
   # Verify report format
   head -20 ecrr/reports/your-report.md
   ```

### Debug Commands

```bash
# Check agent state
cat .agent/state.json

# Review job queue
cat .agent/agent_queue.json

# Check health reports
ls -la artifacts/

# Verify ECRR index
cat ecrr/index.json
```

## 🔒 Security & Performance

### Security
- Agent runs with local permissions only
- No external network access required
- Kill-switch provides immediate control
- All operations are logged and auditable

### Performance
- Agent budgets prevent resource exhaustion
- Health checks are lightweight and fast
- ECRR processing is incremental
- Reports are generated on-demand

## 📈 Integration

### SigNoz Integration
- Health checks verify SigNoz endpoints
- Canary tests generate logs for verification
- ECRR reports can reference SigNoz metrics

### Windows Service Integration
- Service status monitoring
- Configuration validation
- Restart capabilities

### Docker Integration
- Container health monitoring
- Service discovery
- Port conflict detection

## 🎯 Best Practices

1. **Respect budgets** - Never exceed maxJobs, maxFiles, maxLines
2. **Use kill-switch** - Create `.agent/LOCK` when needed
3. **Monitor health** - Run `pnpm agent:doctor` regularly
4. **Review reports** - Check artifacts for insights
5. **Update regularly** - Keep Node.js dependencies current

## 📚 Documentation

- [Wiring Guide](docs/WIRING_GUIDE.md) - Detailed documentation
- [Agent Infrastructure](docs/AGENT_INFRASTRUCTURE_SUMMARY.md) - Agent system details
- [ECRR Framework](docs/ECRR_PROJECT_REPORT.md) - ECRR methodology

## 🚀 Getting Started

1. **Initialize**: `pnpm wire:init`
2. **Verify**: `pnpm wire:verify`
3. **Health Check**: `pnpm wire:health`
4. **Start Agent**: `pnpm agent:start` (optional)
5. **Monitor**: `pnpm agent:doctor`

The wiring system is now ready to maintain your OTel observability pipeline automatically!

---

**Note**: This system follows the ECRR (Examine → Clean → Report → Role) methodology and integrates with the existing Comfort Cat guidelines for consistent, maintainable operations.
