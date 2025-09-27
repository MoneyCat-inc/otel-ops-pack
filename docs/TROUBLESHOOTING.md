# Troubleshooting Quick Hits Guide
# ECRR Compliance: Examine → Clean → Report → Role

## 🔍 Common Issues and Solutions

### No Traces/Metrics at All

**Symptoms:**
- No traces or metrics appearing in SigNoz
- Empty dashboards and graphs
- No data in observability pipeline

**Quick Checks:**
```bash
# Check OTEL environment variables
echo $OTEL_ENABLED
echo $OTEL_EXPORTER_OTLP_ENDPOINT

# Verify collector is running
docker ps | grep otel-collector
sc query otelcol-contrib

# Check collector logs
docker logs otel-collector
```

**Solutions:**
1. **Set environment variables:**
   ```bash
   export OTEL_ENABLED=1
   export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
   ```

2. **Start collector:**
   ```bash
   # Docker
   docker run -d --name otel-collector \
     -p 4317:4317 -p 4318:4318 -p 8888:8888 \
     -v $(pwd)/config.yaml:/etc/otelcol-contrib/config.yaml \
     otel/opentelemetry-collector-contrib:latest
   
   # Windows Service
   sc start otelcol-contrib
   ```

3. **Verify endpoint:**
   ```bash
   curl http://localhost:4318/v1/logs
   curl http://localhost:8888/metrics
   ```

### Trace Exists, Metrics Empty

**Symptoms:**
- Traces visible in SigNoz
- Metrics not appearing
- Meter not created or process dies too early

**Quick Checks:**
```bash
# Check if Meter is created
grep -r "MeterProvider" scripts/
grep -r "createMeter" scripts/

# Verify process stays alive
ps aux | grep node
ps aux | grep pwsh
```

**Solutions:**
1. **Ensure Meter is created once (bootstrap):**
   ```javascript
   const meterProvider = new MeterProvider({
     resource: new Resource({
       [SemanticResourceAttributes.SERVICE_NAME]: 'your-service',
     }),
     readers: [new OTLPMetricExporter({ url: endpoint })],
   });
   
   const meter = meterProvider.getMeter('your-service');
   ```

2. **Keep process alive long enough for collection:**
   ```javascript
   // Add delay or keep process running
   setTimeout(() => process.exit(0), 5000);
   ```

3. **Force flush metrics:**
   ```javascript
   await meterProvider.forceFlush();
   ```

### Cardinality Spikes

**Symptoms:**
- High memory usage
- Slow queries
- Metrics storage issues
- Performance degradation

**Quick Checks:**
```bash
# Check metric cardinality
curl http://localhost:8888/metrics | grep -c "test_id"
curl http://localhost:8888/metrics | grep -c "browser"
```

**Solutions:**
1. **Hash long test IDs:**
   ```javascript
   const hashedTestId = crypto.createHash('md5')
     .update(testId)
     .digest('hex')
     .substring(0, 8);
   ```

2. **Limit labels to essential ones:**
   ```javascript
   // Good: Limited labels
   counter.add(1, {
     test_id: hashedTestId,
     suite: 'smoke',
     browser: 'chrome',
     branch: 'main'
   });
   
   // Bad: Too many labels
   counter.add(1, {
     test_id: longTestId,
     suite: 'smoke',
     browser: 'chrome',
     branch: 'main',
     timestamp: Date.now(),
     user_id: userId,
     session_id: sessionId
   });
   ```

3. **Use aggregation:**
   ```javascript
   // Aggregate by suite instead of individual tests
   counter.add(1, {
     suite: 'smoke',
     browser: 'chrome',
     branch: 'main'
   });
   ```

### Agent Stalls

**Symptoms:**
- Agent not processing tasks
- Queue backing up
- No new jobs running
- System unresponsive

**Quick Checks:**
```bash
# Check for lock file
ls -la .agent/LOCK
cat .agent/LOCK

# Check agent status
cat .agent/status.json
ps aux | grep agent

# Check queue depth
wc -l .agent/state/queue.jsonl
```

**Solutions:**
1. **Remove lock file:**
   ```bash
   rm .agent/LOCK
   ```

2. **Check budgets:**
   ```bash
   # Verify file count
   find . -name "*.ps1" -o -name "*.js" -o -name "*.ts" | wc -l
   
   # Verify LOC count
   find . -name "*.ps1" -o -name "*.js" -o -name "*.ts" -exec wc -l {} + | tail -1
   ```

3. **Restart agent:**
   ```bash
   # Kill existing processes
   pkill -f "agent"
   
   # Restart agent
   pwsh -File .agent/scripts/status-synchronizer.ps1
   ```

### Port Conflicts

**Symptoms:**
- "Address already in use" errors
- Collector won't start
- Connection refused errors

**Quick Checks:**
```bash
# Check port usage
netstat -tulpn | grep :4317
netstat -tulpn | grep :4318
lsof -i :4317
lsof -i :4318
```

**Solutions:**
1. **Kill conflicting processes:**
   ```bash
   # Find and kill process using port
   lsof -ti:4317 | xargs kill -9
   lsof -ti:4318 | xargs kill -9
   ```

2. **Use different ports:**
   ```yaml
   # config.yaml
   receivers:
     otlp:
       protocols:
         grpc:
           endpoint: 0.0.0.0:14317
         http:
           endpoint: 0.0.0.0:14318
   ```

3. **Update endpoint configuration:**
   ```bash
   export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:14318
   ```

### OpAMP Chatter

**Symptoms:**
- "cannot create agent without orgId" errors
- Noisy logs
- Unnecessary network traffic

**Quick Checks:**
```bash
# Check for OpAMP configuration
grep -r "opamp" config.yaml
grep -r "orgId" logs/
```

**Solutions:**
1. **Disable OpAMP for local development:**
   ```yaml
   # config.yaml
   extensions:
     opamp:
       # Disabled for local development
       # server:
       #   endpoint: wss://example.com:4320/v1/opamp
   ```

2. **Filter out OpAMP logs:**
   ```yaml
   # config.yaml
   processors:
     filter:
       logs:
         exclude:
           match_type: regexp
           record_attributes:
             - key: message
               value: ".*opamp.*"
   ```

### Cross-Origin Isolation Issues

**Symptoms:**
- Analytics pages not loading
- Worker errors
- CORS issues

**Quick Checks:**
```bash
# Check COOP/COEP headers
curl -I http://localhost:3000 | grep -i "cross-origin"
```

**Solutions:**
1. **Add COOP/COEP headers:**
   ```javascript
   // Next.js config
   module.exports = {
     async headers() {
       return [
         {
           source: '/(.*)',
           headers: [
             {
               key: 'Cross-Origin-Opener-Policy',
               value: 'same-origin',
             },
             {
               key: 'Cross-Origin-Embedder-Policy',
               value: 'require-corp',
             },
           ],
         },
       ];
     },
   };
   ```

2. **Configure service worker:**
   ```javascript
   // sw.js
   self.addEventListener('fetch', (event) => {
     event.respondWith(
       fetch(event.request, {
         mode: 'cors',
         credentials: 'same-origin',
       })
     );
   });
   ```

## 🚨 Emergency Procedures

### System Down
1. **Check kill-switch:**
   ```bash
   ls -la .agent/LOCK
   ```

2. **Restart services:**
   ```bash
   # Restart collector
   docker restart otel-collector
   sc restart otelcol-contrib
   
   # Restart agent
   pwsh -File .agent/scripts/status-synchronizer.ps1
   ```

3. **Verify health:**
   ```bash
   curl http://localhost:8080/api/v1/health
   curl http://localhost:8888/metrics
   ```

### Data Loss
1. **Check backups:**
   ```bash
   ls -la .agent/state/queue.jsonl.backup*
   ls -la artifacts/*.backup*
   ```

2. **Restore from backup:**
   ```bash
   cp .agent/state/queue.jsonl.backup.20250927-042809 .agent/state/queue.jsonl
   ```

3. **Verify restoration:**
   ```bash
   wc -l .agent/state/queue.jsonl
   head -5 .agent/state/queue.jsonl
   ```

### Performance Issues
1. **Check resource usage:**
   ```bash
   top
   htop
   docker stats
   ```

2. **Check queue depth:**
   ```bash
   wc -l .agent/state/queue.jsonl
   ```

3. **Scale resources:**
   ```bash
   # Increase memory
   docker run --memory=4g otel-collector
   
   # Increase CPU
   docker run --cpus=2 otel-collector
   ```

## 📞 Escalation

### When to Escalate
- System down for > 30 minutes
- Data loss detected
- Security incident
- Performance degradation > 50%

### Escalation Contacts
- **Primary**: On-call engineer
- **Secondary**: Team lead
- **Emergency**: CTO

### Information to Provide
- Error messages
- Log snippets
- System state
- Steps already taken
- Impact assessment

## 🔧 Maintenance

### Daily Checks
- [ ] System health status
- [ ] Queue depth
- [ ] Error rates
- [ ] Performance metrics

### Weekly Checks
- [ ] Log rotation
- [ ] Backup verification
- [ ] Security updates
- [ ] Capacity planning

### Monthly Checks
- [ ] Full system backup
- [ ] Disaster recovery test
- [ ] Performance review
- [ ] Documentation update

---

**Last Updated**: 2025-09-27  
**Version**: 1.0.0  
**Maintainer**: Cursor Agent (Observability Copilot)