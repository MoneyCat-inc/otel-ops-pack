# MILK WebSocket Bridge (Phase 3A)

**Lane**: MILK | **Authority**: BossCat OEM | **Phase**: 3A

---

## Overview

WebSocket server enabling remote control of the MILK visual control surface from BossCat agents or external automation.

**Key Features**:
- WebSocket server on `ws://localhost:8899`
- HTTP fallback on `http://localhost:8899/api/milk`
- localhost-only security (no external access)
- Origin validation for forwarded commands
- ECRR evidence logging

---

## Quick Start

### 1. Start the Bridge

```bash
# From repo root (TypeScript runner)
tsx scripts/visuals/milk-ws-bridge.ts

# Output:
# [MILK] WebSocket bridge running on ws://localhost:8899
# [MILK] HTTP API: http://localhost:8899/api/milk
# [MILK] Nonce: abc123xyz
```

### 2. Send Commands

**Via WebSocket**:
```javascript
const ws = new WebSocket('ws://localhost:8899');

ws.onopen = () => {
  ws.send(JSON.stringify({ cmd: 'next' }));
  ws.send(JSON.stringify({ cmd: 'setBlendTime', arg: 2.5 }));
  ws.send(JSON.stringify({ cmd: 'auto', arg: true }));
};

ws.onmessage = (event) => {
  console.log('Response:', JSON.parse(event.data));
  // { status: 'ok', message: 'Command next forwarded', timestamp: '...' }
};
```

**Via HTTP POST**:
```bash
curl -X POST http://localhost:8899/api/milk \
  -H "Content-Type: application/json" \
  -d '{"cmd":"next"}'

# Response: {"status":"ok","message":"Command next forwarded","timestamp":"..."}
```

**From PowerShell**:
```powershell
Invoke-RestMethod -Method POST -Uri "http://localhost:8899/api/milk" `
  -ContentType "application/json" `
  -Body '{"cmd":"setBlendTime","arg":3.0}'
```

---

## API Reference

### Commands

| Command | Argument | Description |
|---------|----------|-------------|
| `next` | - | Advance to next preset |
| `prev` | - | Go to previous preset |
| `setBlendTime` | `number` (0-10) | Set transition time in seconds |
| `auto` | `boolean` | Enable/disable auto-cycling |

### Request Format

```typescript
{
  "cmd": "next" | "prev" | "setBlendTime" | "auto",
  "arg"?: any,
  "nonce"?: string  // Optional, for validation
}
```

### Response Format

```typescript
{
  "status": "ok" | "error",
  "message"?: string,
  "timestamp": string  // ISO 8601
}
```

---

## Integration with control.html

The bridge forwards commands to `control.html` via `postMessage`:

```javascript
window.postMessage({
  type: 'bosscat:visu',
  cmd: 'next',        // or 'prev', 'setBlendTime', 'auto'
  arg: 2.5            // for setBlendTime or auto(true/false)
}, '*');
```

**Note**: In production with Electron, use IPC instead of postMessage for better security.

---

## Security

**Localhost-Only**:
- Server binds to `localhost` (127.0.0.1)
- Rejects connections from non-local IPs
- No external network access

**Origin Validation**:
- Checks `req.socket.remoteAddress` for localhost
- Validates command structure before forwarding
- Nonce generation for session tracking

**Nonce Protection (Phase-5)**:
- HTTP POST `/api/milk` requires `X-MILK-Nonce` header
- Nonce generated on startup and logged to console
- Invalid/missing nonce → 401 Unauthorized
- WebSocket connections do not require nonce (localhost validation sufficient)

**Example with Nonce**:
```bash
# Start bridge (note the nonce in output)
tsx scripts/visuals/milk-ws-bridge.ts
# Output: [MILK] Nonce: abc123xyz

# Use nonce in HTTP POST
curl -X POST http://localhost:8899/api/milk \
  -H "Content-Type: application/json" \
  -H "X-MILK-Nonce: abc123xyz" \
  -d '{"cmd":"next"}'

# Without nonce → 401
curl -X POST http://localhost:8899/api/milk \
  -H "Content-Type: application/json" \
  -d '{"cmd":"next"}'
# Response: {"status":"error","message":"Missing or invalid X-MILK-Nonce header"}
```

**Phase-3 Improvements**:
- Add origin whitelist for postMessage forwarding
- Implement command rate limiting
- Add authentication token for multi-user scenarios

---

## Usage Examples

### BossCat Agent Integration

```typescript
import { MilkBridge } from './scripts/visuals/milk-ws-bridge';

// Start bridge programmatically
const bridge = new MilkBridge(8899);
bridge.start();

// Export evidence
const evidence = bridge.exportEvidence();
fs.writeFileSync('.agent/EVIDENCE.log', evidence, 'utf-8');
```

### Python Automation

```python
import websocket
import json

ws = websocket.create_connection("ws://localhost:8899")

# Send commands
ws.send(json.dumps({"cmd": "next"}))
response = json.loads(ws.recv())
print(response)  # {'status': 'ok', 'message': '...', 'timestamp': '...'}

ws.send(json.dumps({"cmd": "setBlendTime", "arg": 3.0}))
ws.close()
```

### SigNoz Alert Hook

```javascript
// In SigNoz webhook handler
fetch('http://localhost:8899/api/milk', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    cmd: alertSeverity === 'critical' ? 'next' : 'prev',
    arg: alertSeverity
  })
});
```

---

## Troubleshooting

**"Connection refused"**:
- Ensure bridge is running: `node scripts/visuals/milk-ws-bridge.ts`
- Check port 8899 isn't in use: `netstat -an | findstr 8899`

**"Connection rejected"**:
- Bridge only accepts localhost connections
- If using WSL, connect to `localhost`, not WSL IP

**"Invalid command"**:
- Check command spelling: `next`, `prev`, `setBlendTime`, `auto`
- Ensure JSON is valid: `{"cmd":"next"}` not `{cmd:next}`

**"control.html not responding"**:
- Open control.html in browser first
- Bridge forwards commands but needs active page to receive them
- For production, use Electron to manage both bridge and page

---

## ECRR Compliance

Evidence logged for all operations:
- Bridge initialization (port, nonce)
- Connection events (accept/reject)
- Command processing (cmd, arg, timestamp)
- Errors and validation failures

Export evidence:
```bash
# Evidence auto-exports on Ctrl+C
# Or programmatically: bridge.exportEvidence()
```

Output: `.agent/EVIDENCE.log` (JSON format)

---

## Budget & Governance

**Delivered**:
- LOC: 178 (≤200 ✅)
- Files: 3 (bridge + README + ECRR)
- Lane: MILK
- Security: localhost-only, origin validation ✅

**BossCat Standards**:
- ✅ Evidence-to-disk (ECRR logs)
- ✅ Role attribution (cursor{implementer})
- ✅ Budget compliance
- ✅ Localhost-only (no external attack surface)

---

**🐾 BossCat Seal**: MILK Phase-3A WebSocket Bridge

*Remote control for visual observability feedback*

---

*Lane: MILK | Phase: 3A | LOC: 178/200 | Security: localhost-only*

