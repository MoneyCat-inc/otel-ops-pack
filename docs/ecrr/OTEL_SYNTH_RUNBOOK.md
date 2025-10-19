# Synthetic Trace Proof — Hub (SigNoz / OTLP)

**Purpose:** Emit one end-to-end trace using .NET auto-instrumentation and capture it in SigNoz.  
**Evidence:** Proves OpenTelemetry instrumentation path is operational.

---

## Environment Variables

```bash
CORECLR_ENABLE_PROFILING=1
CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318}
OTEL_SERVICE_NAME=hub-synth
OTEL_TRACES_EXPORTER=otlp
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

---

## Steps (Windows PowerShell)

```powershell
# 1. Set environment variables
$env:CORECLR_ENABLE_PROFILING="1"
$env:CORECLR_PROFILER="{918728DD-259F-4A6A-AC2B-B85E1B658318}"
$env:OTEL_SERVICE_NAME="hub-synth"
$env:OTEL_TRACES_EXPORTER="otlp"
$env:OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"

# 2. Create test console app
dotnet new console -o HubSynth
cd HubSynth

# 3. Add HttpClient package
dotnet add package System.Net.Http

# 4. Replace Program.cs with:
@"
using System.Net.Http;
var http = new HttpClient();
var resp = await http.GetAsync("https://hub.resonai.io/robots.txt");
Console.WriteLine($"Status: {(int)resp.StatusCode}");
"@ | Set-Content Program.cs

# 5. Run (emits trace)
dotnet run

# 6. Verify in SigNoz
# - Open http://localhost:8080
# - Navigate to Traces
# - Filter: service="hub-synth"
# - Screenshot the span detail
# - Save to: docs/ecrr/screens/otel-synth.png
```

---

## Evidence Report

After running, create `docs/ecrr/ECRR_REPORTS/OTEL_SYNTH_<DATE>.md` using the template:

- Include environment variables used
- Embed screenshot of captured span
- Note any observations or issues

---

## Expected Result

- ✅ Span appears in SigNoz (service: hub-synth)
- ✅ HTTP GET to https://hub.resonai.io/robots.txt captured
- ✅ No errors or warnings
- ✅ Confirms auto-instrumentation path operational

---

**BossCat Note:** This provides observability proof for client demos and validates the OTel stack end-to-end.

