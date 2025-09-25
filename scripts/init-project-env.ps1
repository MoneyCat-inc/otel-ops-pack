#Requires -Version 7.0
param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$Message) {
    Write-Host "[init-project-env] $Message" -ForegroundColor Cyan
}

function New-DirectoryIfMissing([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

Write-Info "Starting scaffold for project '$Name'"

$root = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $root "..")
$projectsDir = Join-Path $repoRoot "projects"
$projectRoot = Join-Path $projectsDir $Name
$projectConfigDir = Join-Path $projectRoot "config"
$projectScriptsDir = Join-Path $projectRoot "scripts"
$projectLogsDir = Join-Path $projectRoot "logs"

New-DirectoryIfMissing $projectsDir

if ((Test-Path -LiteralPath $projectRoot) -and -not $Force) {
    throw "Project folder '$projectRoot' already exists. Re-run with -Force to overwrite scaffolded files."
}

New-DirectoryIfMissing $projectRoot
New-DirectoryIfMissing $projectConfigDir
New-DirectoryIfMissing $projectScriptsDir
New-DirectoryIfMissing $projectLogsDir

$envFile = Join-Path $projectRoot ".env"
$envContent = @(
    "# Project-scoped OTEL environment for '$Name'",
    "# This sends logs/traces/metrics to the shared Windows Collector (local) via OTLP/HTTP",
    "# The Windows Collector forwards to SigNoz at http://localhost:14317 (gRPC) in WSL",
    "OTEL_SERVICE_NAME=$Name",
    "OTEL_RESOURCE_ATTRIBUTES=service.name=$Name,project=$Name,dataset=resonai_analytics",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:5318",
    "OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf",
    "OTEL_LOGS_EXPORTER=otlp",
    "OTEL_TRACES_EXPORTER=none",
    "OTEL_METRICS_EXPORTER=none"
)
Set-Content -LiteralPath $envFile -Value $envContent -Encoding UTF8

$collectorTemplatePath = Join-Path $projectConfigDir "collector.project.yaml"
$collectorTemplate = @"
# Optional per-project Collector (NOT required). Default flow uses shared Windows Collector.
# It tails this project's logs and forwards to SigNoz (WSL) at 14317.
receivers:
  filelog:
    include: [ 'C:/otel/projects/$Name/logs/**/*.log' ]
    start_at: beginning
    operators:
      - type: move
        from: attributes[""log.file.path""]
        to: resource[""log.file.path""]
exporters:
  otlp/signoz:
    endpoint: http://localhost:14317
    tls:
      insecure: true
processors:
  batch:
    timeout: 200ms
service:
  pipelines:
    logs:
      receivers: [filelog]
      processors: [batch]
      exporters: [otlp/signoz]
"@
Set-Content -LiteralPath $collectorTemplatePath -Value $collectorTemplate -Encoding UTF8

$enterScriptPath = Join-Path $projectScriptsDir "enter.ps1"
$enterScript = @"
# Project shell for '$Name' — scopes OTEL vars to shared Windows Collector
param([switch]`$EmitCanary)

`$env:OTEL_SERVICE_NAME = '$Name'
`$env:OTEL_RESOURCE_ATTRIBUTES = 'service.name=$Name,project=$Name,dataset=resonai_analytics'
`$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://localhost:5318'
`$env:OTEL_EXPORTER_OTLP_PROTOCOL = 'http/protobuf'
`$env:OTEL_LOGS_EXPORTER = 'otlp'
`$env:OTEL_TRACES_EXPORTER = 'none'
`$env:OTEL_METRICS_EXPORTER = 'none'

Write-Host "Project '$Name' environment loaded." -ForegroundColor Green
Write-Host "OTEL → Windows Collector (5318) → SigNoz (14317)." -ForegroundColor DarkGreen
Write-Host "Logs dir: $projectLogsDir" -ForegroundColor DarkCyan

if (`$EmitCanary) {
  `$logDir = '$projectLogsDir'
  if (-not (Test-Path -LiteralPath `$logDir)) { New-Item -ItemType Directory -Path `$logDir | Out-Null }
  `$logPath = Join-Path `$logDir 'canary.log'
  `$entry = ('{0} sample canary from {1}' -f (Get-Date).ToString('o'), '$Name')
  Add-Content -LiteralPath `$logPath -Value `$entry -Encoding UTF8
  Write-Host "Emitted canary: `$logPath" -ForegroundColor Yellow
  Write-Host "In SigNoz → Logs, filter: service.name = $Name AND log.file.path contains '/projects/$Name/logs'" -ForegroundColor Yellow
}
"@
Set-Content -LiteralPath $enterScriptPath -Value $enterScript -Encoding UTF8

$readmePath = Join-Path $projectRoot "README.md"
$readmeContent = @"
# Project sandbox: $Name

- Logs: $projectLogsDir
- Scripts: $projectScriptsDir
- Env: $envFile

Launch scoped shell vars:

```powershell
pwsh -File scripts/enter.ps1 -EmitCanary
```

Verify in SigNoz Logs with filter: service.name = $Name
"@
Set-Content -LiteralPath $readmePath -Value $readmeContent -Encoding UTF8

Write-Info "Scaffold complete: $projectRoot"
Write-Host "+ $envFile" -ForegroundColor DarkGray
Write-Host "+ $collectorTemplatePath" -ForegroundColor DarkGray
Write-Host "+ $enterScriptPath" -ForegroundColor DarkGray
Write-Host "+ $readmePath" -ForegroundColor DarkGray
Write-Host "+ $projectLogsDir" -ForegroundColor DarkGray
