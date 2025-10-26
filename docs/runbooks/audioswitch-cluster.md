# Distributed AudioSwitch — Runbook (BOSSCAT-023A)

**Authority:** BossCat OEM  
**Gate:** #023  
**Purpose:** Cluster-aware audio gating with Redis pub/sub + file-based fallback

---

## Summary

The Distributed AudioSwitch extends BOSSCAT-021A's file-based audio kill switch with cluster-wide coordination via Redis pub/sub. This enables one-shot, zero-restart audio control across N replicas while maintaining local file authority as a fallback.

**Key Features:**
- ✅ Cluster-wide propagation within ≤2s
- ✅ Redis pub/sub for state distribution
- ✅ Atomic versioning prevents split-brain
- ✅ File-based fallback when Redis unavailable
- ✅ Same `/admin/audio` API as BOSSCAT-021A

---

## Architecture

### Components

**1. Local Switch (BOSSCAT-021A)**
- File: `viz-engine-projectm/lib/audio-switch.js`
- Storage: `config/audio-state.json` (bind-mounted)
- Authority: Single source of truth per replica

**2. Cluster Module (BOSSCAT-023A)**
- File: `viz-engine-projectm/lib/audio-switch-cluster.js`
- Coordination: Redis pub/sub + atomic version counter
- Fallback: Local file switch when Redis unavailable

**3. Redis Backend**
- Image: `redis:7-alpine`
- Persistence: AOF (append-only file)
- Keys:
  - `audioswitch:state` - Current cluster state (JSON)
  - `audioswitch:version` - Monotonic version counter
- Channel: `audioswitch:events` - Pub/sub for state changes

### Data Flow

**Write Path:**
```
POST /admin/audio
  ↓
audioSwitch.enable/disable(reason)
  ↓
localSwitch.enable/disable(reason)  [file persisted]
  ↓
INCR audioswitch:version
  ↓
SET audioswitch:state {enabled, reason, version, sourceId}
  ↓
PUBLISH audioswitch:events {enabled, reason, version, sourceId}
  ↓
All other replicas receive pub/sub message
  ↓
Each replica updates local file switch
```

**Read Path:**
```
GET /health or GET /admin/audio
  ↓
audioSwitch.getState()
  ↓
localSwitch.getState() + cluster metadata
  ↓
Return {enabled, reason, changedAt, cluster: {connected, sourceId, version}}
```

---

## Operations

### Toggle Audio (Cluster-Wide)

**Disable:**
```bash
curl -X POST http://localhost:7020/admin/audio \
  -H 'Content-Type: application/json' \
  -H 'X-Admin-Token: <token>' \
  -d '{"enabled":false,"reason":"maintenance"}'
```

**Enable:**
```bash
curl -X POST http://localhost:7020/admin/audio \
  -H 'Content-Type: application/json' \
  -H 'X-Admin-Token: <token>' \
  -d '{"enabled":true,"reason":"maintenance-complete"}'
```

**Effect:** All replicas update within ≤2s

### Check Audio State

**Health Endpoint:**
```bash
curl http://localhost:7020/health | jq '.audio'
```

**Response:**
```json
{
  "enabled": false,
  "reason": "maintenance",
  "changedAt": "2025-10-26T23:00:00.000Z",
  "cluster": {
    "connected": true,
    "sourceId": "pm-engine-1:12345",
    "version": 42
  }
}
```

**Admin Endpoint:**
```bash
curl http://localhost:7020/admin/audio | jq '.'
```

**Same response structure**

---

## Configuration

### Environment Variables

**Redis Connection:**
- `REDIS_URL` - Redis connection string (default: `redis://redis:6379`)
- If not set or connection fails, falls back to file-based only

**Redis Keys:**
- `AUDIO_STATE_KEY` - State storage key (default: `audioswitch:state`)
- `AUDIO_VERSION_KEY` - Version counter key (default: `audioswitch:version`)
- `AUDIO_PUBSUB_CHANNEL` - Pub/sub channel (default: `audioswitch:events`)

**Security:**
- `ADMIN_TOKEN` - Optional token for `/admin/audio` protection

### Docker Compose

**Example:**
```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
    volumes:
      - redis-data:/data
  
  pm-engine:
    environment:
      - REDIS_URL=redis://redis:6379
      - AUDIO_STATE_KEY=audioswitch:state
      - AUDIO_PUBSUB_CHANNEL=audioswitch:events
      - AUDIO_VERSION_KEY=audioswitch:version
    depends_on:
      redis:
        condition: service_healthy
```

---

## Scaling

### Deploy Multiple Replicas

**Command:**
```bash
docker compose -f docker-compose.viz.yml up -d --build --scale pm-engine=3
```

**Verification:**
```bash
docker ps --filter "name=pm-engine"
```

**Expected:** N containers running, all healthy

### Verify Cluster Coordination

**Script:**
```powershell
pwsh -File .\scripts\cluster\verify-audioswitch-cluster.ps1 -Replicas 3
```

**Expected Output:**
```
=== BOSSCAT-023A :: Cluster AudioSwitch Verification ===
[1/6] Scaling service to 3 replicas... ✓
[2/6] Discovering replica containers... ✓
[3/6] Testing cluster-wide DISABLE... ✓
  All replicas disabled in <XXX>ms
[4/6] Testing cluster-wide ENABLE... ✓
  All replicas enabled in <XXX>ms
[5/6] Testing Redis failover... ✓
[6/6] Generating evidence... ✓
✅ Cluster AudioSwitch Verification PASS
```

---

## Failure Modes

### Redis Unavailable (Startup)

**Behavior:**
- Cluster module initialization fails gracefully
- Falls back to local file-based switch
- Log message: `[audio-cluster] No REDIS_URL - using local file-based switch only`
- No cluster propagation (each replica operates independently)
- `/admin/audio` still works locally

**Detection:**
```bash
curl http://localhost:7020/health | jq '.audio.cluster.connected'
# false = local-only mode
# true = cluster mode
```

**Recovery:**
- Fix Redis connectivity
- Restart pm-engine replicas
- Cluster coordination resumes automatically

### Redis Unavailable (Runtime)

**Behavior:**
- Publish operations fail silently (logged)
- Subscribe connection drops
- Local file switch remains authoritative
- No deadlock (operations continue)

**Detection:**
- Log messages: `[audio-cluster] Failed to publish state`
- `/health` shows `cluster.connected: false`

**Recovery:**
- Restart Redis
- Replicas auto-reconnect on next state change

### Split-Brain Scenario

**Problem:** Network partition causes state divergence

**Resolution:**
- Monotonic version counter (`INCR audioswitch:version`)
- Last-write-wins based on version number
- Each replica ignores messages with version ≤ lastVersion
- Self-messages ignored via `sourceId` check

**Recovery:** Automatic when partition heals

---

## Monitoring

### Health Checks

**Per-Replica State:**
```bash
for i in {1..3}; do
  docker exec pm-engine-$i curl -s http://localhost:7020/health | jq '.audio'
done
```

**Expected:** All replicas show same `enabled` state

### Redis Metrics

**Check Redis:**
```bash
docker exec redis-audioswitch redis-cli INFO replication
docker exec redis-audioswitch redis-cli PUBSUB NUMSUB audioswitch:events
```

**Check Version Counter:**
```bash
docker exec redis-audioswitch redis-cli GET audioswitch:version
```

**Check State:**
```bash
docker exec redis-audioswitch redis-cli GET audioswitch:state
```

### Logs

**Cluster Module Logs:**
```bash
docker logs pm-engine 2>&1 | grep "audio-cluster"
```

**Key Messages:**
- `Redis connected` - Successful initialization
- `Received state change from <sourceId>` - Pub/sub working
- `Published state to Redis` - Write propagated
- `Failed to publish state` - Redis connectivity issue

---

## Troubleshooting

### Replicas Not Syncing

**Symptoms:** POST /admin/audio on one replica doesn't affect others

**Diagnosis:**
```bash
# Check Redis connectivity from replicas
docker exec pm-engine-1 sh -c "curl -s http://localhost:7020/health | jq '.audio.cluster.connected'"

# Check Redis logs
docker logs redis-audioswitch

# Check pub/sub subscriptions
docker exec redis-audioswitch redis-cli PUBSUB NUMSUB audioswitch:events
```

**Common Causes:**
- Redis not healthy: `docker ps --filter "name=redis"`
- Network isolation: Check `depends_on` in compose file
- Version conflict: Check logs for "stale version" messages

**Resolution:**
1. Verify Redis healthy: `docker compose ps redis`
2. Restart replicas: `docker compose restart pm-engine`
3. Check Redis reachable: `docker exec pm-engine-1 nc -zv redis 6379`

### Slow Propagation (>2s)

**Symptoms:** Cluster-wide toggle takes >2s

**Diagnosis:**
```powershell
pwsh -File .\scripts\cluster\verify-audioswitch-cluster.ps1
# Check timing.disable_ms and timing.enable_ms in evidence JSON
```

**Common Causes:**
- Network latency between containers
- Redis under load
- Too many replicas (scaling issue)

**Resolution:**
1. Reduce replica count for testing
2. Check Redis performance: `docker stats redis-audioswitch`
3. Increase timeout if network is slow
4. Check for resource contention

### File Fallback Not Working

**Symptoms:** When Redis down, audio control fails entirely

**Diagnosis:**
```bash
# Stop Redis
docker compose stop redis

# Check if local file switch still works
curl http://localhost:7020/health | jq '.audio'

# Should still return state (from local file)
```

**Common Causes:**
- File permissions on `config/audio-state.json`
- Volume mount not configured
- Initialization error

**Resolution:**
1. Check volume mount: `docker inspect pm-engine | jq '.[0].Mounts'`
2. Check file exists: `docker exec pm-engine ls -la /app/config/`
3. Review logs: `docker logs pm-engine | grep "audio-switch"`

---

## Security Considerations

### Redis Access Control

**Default:** No authentication (trusted network)

**Production Recommendations:**
1. Enable Redis AUTH: `requirepass <strong-password>`
2. Update REDIS_URL: `redis://:password@redis:6379`
3. Network isolation: Restrict Redis to viz-net only
4. TLS encryption for sensitive environments

### Admin API Protection

**Enable Token Auth:**
```yaml
environment:
  - ADMIN_TOKEN=your-secret-token-here
```

**Usage:**
```bash
curl -X POST http://localhost:7020/admin/audio \
  -H 'X-Admin-Token: your-secret-token-here' \
  -d '{"enabled":false}'
```

### State Visibility

**Health Endpoint Exposure:**
- `/health` shows full audio state (enabled, reason, cluster metadata)
- Consider limiting in production if state details are sensitive
- Detailed state always available via `/admin/audio` (can be protected)

---

## Performance Tuning

### High-Frequency Deployments

**Reduce Propagation Checks:**
```javascript
// In audio-switch-cluster.js, reduce poll interval
Start-Sleep -Milliseconds 100  // Faster but more Redis load
```

**Increase Timeout:**
```powershell
pwsh -File .\scripts\cluster\verify-audioswitch-cluster.ps1 -TimeoutSec 10
```

### Large Clusters (>10 replicas)

**Redis Performance:**
- Monitor pub/sub lag
- Consider Redis Cluster mode for high availability
- Add connection pooling if needed

**Network:**
- Ensure low latency between replicas and Redis
- Monitor pub/sub message delivery times

---

## Testing

### Manual Cluster Test

**1. Scale to 3 replicas:**
```bash
docker compose -f docker-compose.viz.yml up -d --scale pm-engine=3
```

**2. Disable via one replica:**
```bash
curl -X POST http://localhost:7020/admin/audio \
  -d '{"enabled":false,"reason":"test"}'
```

**3. Check all replicas:**
```bash
docker ps --filter "name=pm-engine" --format "{{.Names}}" | while read name; do
  echo "=== $name ==="
  docker exec $name curl -s http://localhost:7020/health | jq '.audio.enabled'
done
```

**Expected:** All show `false`

### Automated Cluster Test

**Command:**
```powershell
pwsh -File .\scripts\cluster\verify-audioswitch-cluster.ps1 -Replicas 3
```

**Pass Criteria:**
- Disable time ≤ 2000ms
- Enable time ≤ 2000ms
- Redis failover works
- Evidence JSON generated

---

## Related Documentation

- **BOSSCAT-021A:** Single-replica audio switch (foundation)
- **Gate #021:** AudioSwitch implementation and approval
- **Gate #023:** Distributed AudioSwitch specification
- **Verification Script:** `scripts/cluster/verify-audioswitch-cluster.ps1`
- **Implementation:** `viz-engine-projectm/lib/audio-switch-cluster.js`

---

**Last Updated:** 2025-10-26 (Gate #023)  
**Authority:** BossCat OEM  
**Status:** Production-ready

🐾

