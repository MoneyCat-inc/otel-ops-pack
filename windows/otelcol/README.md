# Windows Collector Configuration

**Canonical config (loaded by the service):** `C:\otel\config.yaml`

The Windows service `otelcol-contrib` is registered with:

```
"C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\otel\config.yaml"
```

`otelcol-contrib-config.yaml` in this directory is a reference template. Edit `config.yaml` for production changes, then restart the service:

```powershell
Restart-Service otelcol-contrib
```

**OTLP export target:** `localhost:4317` (SigNoz Docker `signoz-otel-collector`)

**Collector listen ports:** `5320` (gRPC), `5321` (HTTP), health `13134` (avoids PlariumPlay 5300–5319)
