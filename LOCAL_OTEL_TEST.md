# 🐾 Local OTel Test Guide

## **Quick Local Poke (Optional)**

Test the OTLP canary locally before pushing:

```bash
# Start collector with CI config
docker run --rm -p 4318:4318 -v "$PWD/otel/ci-config.yaml:/etc/otel/config.yaml" \
  ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector:0.114.0 \
  --config=/etc/otel/config.yaml &

# Send test span
curl -sS -X POST http://localhost:4318/v1/traces \
  -H 'Content-Type: application/json' \
  -d @- <<'JSON'
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"local-ci"}}]},"scopeSpans":[{"spans":[{"traceId":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","spanId":"bbbbbbbbbbbbbbbb","name":"local-smoke","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"}]}]}]}
JSON

# Check logs
docker logs $(docker ps -q --filter "ancestor=ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector:0.114.0")
```

## **Expected Output**

You should see:
- Collector starting with `verbosity: detailed`
- OTLP receiver listening on `0.0.0.0:4318`
- Span received and logged with detailed verbosity
- No errors in the collector logs

## **Troubleshooting**

If anything squeaks:
1. Check collector logs for errors
2. Verify port 4318 is available
3. Confirm YAML config syntax is valid
4. Check Docker is running

---

**Ready for the real test? Push and watch the bots prowl! 🐱‍💻**
