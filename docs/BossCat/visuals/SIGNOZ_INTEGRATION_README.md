# MILK SigNoz Integration (Phase 3C)

**Lane**: MILK | **Authority**: BossCat OEM | **Phase**: 3C | **Priority**: HIGH

---

## Overview

Connects SigNoz observability alerts to MILK visual control, providing real-time visual feedback for system state changes.

**Flow**:
```
SigNoz Alert → milk-signoz-mapper.ts → WebSocket Bridge → control.html → Visual Change
```

**Key Value**: System state becomes immediately visible through preset changes

---

## Quick Start

### 1. Start the Full Stack

```bash
# Terminal 1: Start WebSocket bridge
tsx scripts/visuals/milk-ws-bridge.ts

# Terminal 2: Open control surface
start docs\BossCat\visuals\control.html

# Terminal 3: Test mapper
tsx scripts/visuals/milk-signoz-mapper.ts test
```

### 2. Configure SigNoz Webhook

In SigNoz UI (http://localhost:8080):
1. Navigate to **Alerts** → **Alert Rules**
2. Edit alert rule → **Notification Channels**
3. Add webhook: `http://localhost:8899/api/milk`
4. Or use mapper as webhook server (future enhancement)

---

## Alert Severity Mapping

### Default Mapping

| Severity | Visual Response | Blend Time | Auto-Cycle |
|----------|-----------------|------------|------------|
| **critical** | Next preset (alert visual) | 0.5s | OFF |
| **high** | Next preset (attention) | 1.0s | OFF |
| **medium** | Current preset | 2.0s | OFF |
| **low** | Current preset | 3.0s | ON |
| **info** | Default (calm) | 2.7s | ON |

### Custom Mapping

Create `config/milk-preset-mapping.json`:

```json
{
  "critical": {
    "level": "critical",
    "preset": "Geiss - Strobe Alert",
    "blendTime": 0.3,
    "autoCycle": false
  },
  "high": {
    "level": "high",
    "blendTime": 1.0,
    "autoCycle": false
  },
  "info": {
    "level": "info",
    "blendTime": 2.7,
    "autoCycle": true
  }
}
```

Mapper will merge custom config with defaults.

---

## API Reference

### CLI Commands

```bash
# Test alert mapping
tsx milk-signoz-mapper.ts test

# Check bridge connectivity
tsx milk-signoz-mapper.ts health

# Export evidence log
tsx milk-signoz-mapper.ts evidence
```

### Programmatic Usage

```typescript
import { SigNozMapper } from './scripts/visuals/milk-signoz-mapper';

const mapper = new SigNozMapper('http://localhost:8899/api/milk');

// Process alert
await mapper.processWebhook({
  severity: 'critical',
  state: 'firing',
  value: 95.5,
  labels: { service: 'api', environment: 'production' }
});

// Check bridge health
const bridgeOk = await mapper.checkBridge();

// Export evidence
const evidence = mapper.exportEvidence();
```

---

## Integration Examples

### SigNoz Alert Rule (Direct)

Configure SigNoz to POST directly to bridge:

**Webhook URL**: `http://localhost:8899/api/milk`

**Headers** (Phase-5):
```
Content-Type: application/json
X-MILK-Nonce: <nonce from bridge startup>
```

**Payload Template**:
```json
{
  "cmd": "{{if eq .Severity \"critical\"}}next{{else}}prev{{end}}",
  "arg": "{{.Severity}}"
}
```

**Note**: Phase-5 adds nonce security. Check bridge startup logs for current nonce.

### SigNoz Alert Rule (via Mapper)

For advanced mapping, run mapper as webhook listener:

```bash
# Future enhancement: mapper with HTTP server
tsx milk-signoz-mapper.ts serve --port 8898
```

Then configure SigNoz webhook to `http://localhost:8898/webhook`.

### PowerShell Automation

```powershell
# Simulate alert
$alert = @{
  severity = "critical"
  state = "firing"
  value = 98.5
} | ConvertTo-Json

Invoke-RestMethod -Method POST -Uri "http://localhost:8899/api/milk" `
  -ContentType "application/json" -Body '{"cmd":"next"}'
```

### BossCat Agent Integration

```typescript
// In BossCat alert handler
import { SigNozMapper } from './scripts/visuals/milk-signoz-mapper';

const mapper = new SigNozMapper();

// On alert received
alertStream.subscribe(async (alert) => {
  await mapper.processWebhook({
    severity: alert.severity,
    state: alert.state,
    labels: alert.labels
  });
});
```

---

## Preset Recommendations

### Alert Visuals (Suggested Presets)

**Critical Alerts**:
- "Geiss - Strobe (Red Mix)" - Intense, alerting
- "Rovastar - Red Alert" - Sharp, rapid
- "Flexi - Emergency Flash" - Attention-grabbing

**High Severity**:
- "Unchained - Active Pulse" - Energetic, focused
- "Krash - Warning Wave" - Moderate intensity

**Medium/Low**:
- "Resonai - Default (Neon Pulse)" - Calm monitoring
- "Geiss - Kaleidoscope (Calm)" - Gentle, soothing

**All Clear**:
- "Flexi - Ocean Calm" - Peaceful flow
- "Unchained - Gentle Drift" - Minimal activity

**Note**: Preset names depend on your butterchurn-presets library. Adjust mapping config accordingly.

---

## Architecture

### Component Interaction

```
┌─────────────┐     Webhook      ┌──────────────────┐
│   SigNoz    │ ───────────────> │ milk-signoz-     │
│   Alerts    │                  │ mapper.ts        │
└─────────────┘                  └──────────────────┘
                                          │
                                          │ HTTP POST
                                          ↓
                                 ┌──────────────────┐
                                 │ milk-ws-bridge   │
                                 │ :8899/api/milk   │
                                 └──────────────────┘
                                          │
                                          │ postMessage
                                          ↓
                                 ┌──────────────────┐
                                 │  control.html    │
                                 │  (Butterchurn)   │
                                 └──────────────────┘
```

### Data Flow

1. **SigNoz**: Alert fires → webhook payload
2. **Mapper**: Analyzes severity → selects visual response
3. **Bridge**: Validates command → forwards to control surface
4. **Control**: Receives postMessage → changes preset/blend/cycle
5. **Visual**: User sees immediate feedback

**Latency**: Typically <500ms end-to-end

---

## Configuration

### Environment Variables

```bash
# Bridge URL (default: localhost:8899)
export MILK_BRIDGE_URL=http://localhost:8899/api/milk

# Mapping config path (optional)
export MILK_MAPPING_CONFIG=config/milk-preset-mapping.json
```

### Custom Preset Mapping

Create `config/milk-preset-mapping.json`:

```json
{
  "critical": {
    "preset": "Your Custom Critical Preset",
    "blendTime": 0.2,
    "autoCycle": false
  },
  "baseline": {
    "preset": "Resonai - Default (Neon Pulse)",
    "blendTime": 2.7,
    "autoCycle": true
  }
}
```

---

## Security

**Production Considerations**:
- Mapper → Bridge: localhost-only (no auth needed)
- SigNoz → Mapper: Add webhook signature validation (Phase-4)
- Bridge → Browser: postMessage origin whitelist (Phase-4)

**Current**: Suitable for single-user local development

---

## Troubleshooting

**"Bridge unreachable"**:
- Check bridge is running: `curl http://localhost:8899/health`
- Verify port 8899 open: `netstat -an | findstr 8899`

**"Alerts not changing visuals"**:
- Verify control.html is open in browser
- Check browser console for postMessage errors
- Test mapper directly: `tsx milk-signoz-mapper.ts test`

**"Wrong presets selected"**:
- Review mapping config: `config/milk-preset-mapping.json`
- Check severity values in SigNoz alerts
- Test individual alerts with mapper CLI

---

## ECRR Compliance

Evidence logged:
- Mapper initialization (bridge URL, config load)
- Alert processing (severity, commands generated)
- Command transmission (success/failure)
- Bridge health checks

Export: `tsx milk-signoz-mapper.ts evidence > .agent/MILK_EVIDENCE.json`

---

## Budget & Governance

**Delivered**:
- LOC: 191 (≤200 ✅)
- Files: 4 (mapper + README + ECRR + config example)
- Lane: MILK
- Dependencies: Node fetch API (built-in Node 18+)

**BossCat Standards**:
- ✅ Evidence-to-disk
- ✅ Role attribution
- ✅ Budget compliance
- ✅ Integration-ready

---

**🐾 BossCat Seal**: MILK Phase-3C SigNoz Integration

*Observability-driven visual feedback - system state becomes visible*

---

*Lane: MILK | Phase: 3C | LOC: 191/200 | Priority: HIGH*

