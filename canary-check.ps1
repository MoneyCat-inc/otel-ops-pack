# C:\otel\canary-check.ps1
# Wrapper for deterministic canary verification with optional SigNoz API and ClickHouse fallbacks.

[CmdletBinding(DefaultParameterSetName = 'SigNoz')]
param(
  [Parameter(ParameterSetName = 'SigNoz')]
  [string]$SigNozApi = 'http://127.0.0.1:3301',

  [Parameter(ParameterSetName = 'SigNoz')]
  [string]$SigNozApiKey,

  [Parameter(ParameterSetName = 'ClickHouse')]
  [switch]$UseClickHouse,

  [Parameter(ParameterSetName = 'ClickHouse')]
  [string]$ClickHouseHttp = 'http://127.0.0.1:8123',

  [Parameter(ParameterSetName = 'ClickHouse')]
  [string]$ClickHouseUser,

  [Parameter(ParameterSetName = 'ClickHouse')]
  [string]$ClickHousePassword,

  [string]$CanaryScript = 'C:\otel\canary-check-min.ps1',
  [string]$TranscriptPath = 'C:\otel\logs\canary-check-min.last.log',
  [int]$TimeoutSec = 10
)

$ErrorActionPreference = 'Stop'

function Resolve-CanaryScript {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    return $Path
  }
  throw "Canary script not found at $Path"
}

function Invoke-CanaryCore {
  param(
    [string]$Script,
    [hashtable]$Arguments
  )

  Write-Host "Running core canary: $Script"
  & $Script @Arguments
  $exit = $LASTEXITCODE
  if ($exit -ne 0) {
    throw "Core canary script exited with code $exit"
  }
}

function Get-CanaryTokenFromTranscript {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Transcript file not found at $Path"
  }

  $lines = Get-Content -LiteralPath $Path
  for ($i = $lines.Length - 1; $i -ge 0; $i--) {
    $line = $lines[$i]
    if ($line -match 'token=([0-9a-fA-F-]+)') {
      return $Matches[1]
    }
  }
  throw "Could not locate canary token in transcript at $Path"
}

function Invoke-SigNozVerification {
  param(
    [string]$BaseUrl,
    [string]$Token,
    [string]$ApiKey,
    [int]$Timeout
  )

  $base = $BaseUrl.TrimEnd('/')
  $headers = @{}
  if ($ApiKey) {
    $headers['X-SigNoz-API-Key'] = $ApiKey
  }

  $endMs = [DateTimeOffset]::UtcNow.AddMinutes(1).ToUnixTimeMilliseconds()
  $startMs = [DateTimeOffset]::UtcNow.AddMinutes(-10).ToUnixTimeMilliseconds()
  $searchText = [Uri]::EscapeDataString("canary.token:$Token")
  $queryUri = "$base/api/v1/logs/search?searchText=$searchText&start=$startMs&end=$endMs&limit=1"

  try {
    $resp = Invoke-WebRequest -UseBasicParsing -TimeoutSec $Timeout -Uri $queryUri -Headers $headers -Method Get
    if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300 -and ($resp.Content -match $Token)) {
      Write-Host "SigNoz search verified token via GET" -ForegroundColor Green
      return
    }
    Write-Verbose "SigNoz GET search response did not contain token. Status=$($resp.StatusCode)"
  } catch {
    Write-Verbose "SigNoz GET search failed: $($_.Exception.Message)"
  }

  $endNs = $endMs * 1000000
  $startNs = $startMs * 1000000
  $body = @{
    compositeQuery = @{
      queryType = 'LOGS'
      panelType = 'list'
      builderQueries = @{
        A = @{
          queryName = 'A'
          dataSource = 'logs'
          aggregateOperator = 'noop'
          expression = 'A'
          filter = @{
            items = @(
              @{
                key = "resourceAttributes['canary.token']"
                operator = 'contains'
                value = $Token
              }
            )
            operator = 'AND'
          }
          orderBy = @(
            @{ columnName = 'timestamp'; order = 'desc' }
          )
          limit = 1
        }
      }
    }
    startTime = $startNs
    endTime = $endNs
  }

  $json = $body | ConvertTo-Json -Depth 6
  $resp2 = Invoke-WebRequest -UseBasicParsing -TimeoutSec $Timeout -Uri "$base/api/v1/logs/search" -Method Post -ContentType 'application/json' -Headers $headers -Body $json
  if ($resp2.StatusCode -ge 200 -and $resp2.StatusCode -lt 300 -and ($resp2.Content -match $Token)) {
    Write-Host "SigNoz search verified token via POST" -ForegroundColor Green
    return
  }
  throw "SigNoz API response did not include canary token."
}

function Invoke-ClickHouseVerification {
  param(
    [string]$HttpEndpoint,
    [string]$Token,
    [string]$User,
    [string]$Password,
    [int]$Timeout
  )

  $query = @"
SELECT 1
FROM signoz_logs.distributed_logs
WHERE timestamp >= now() - INTERVAL 10 MINUTE
  AND (
    JSONExtractString(resource_attributes, 'canary.token') = '$Token'
    OR positionCaseInsensitive(body, '$Token') > 0
  )
LIMIT 1
"@

  $headers = @{}
  if ($User) {
    $pwd = if ($null -ne $Password) { $Password } else { '' }
    $auth = '{0}:{1}' -f $User, $pwd
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
    $headers['Authorization'] = 'Basic ' + [Convert]::ToBase64String($bytes)
  }

  $resp = Invoke-WebRequest -UseBasicParsing -TimeoutSec $Timeout -Uri $HttpEndpoint -Method Post -Headers $headers -Body $query
  if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300 -and ($resp.Content -match '\b1\b')) {
    Write-Host "ClickHouse query verified token" -ForegroundColor Green
    return
  }
  throw "ClickHouse query did not return any rows containing the canary token."
}

$scriptPath = Resolve-CanaryScript -Path $CanaryScript
Invoke-CanaryCore -Script $scriptPath -Arguments @{}
$token = Get-CanaryTokenFromTranscript -Path $TranscriptPath
Write-Host "Located canary token: $token"

if ($UseClickHouse.IsPresent) {
  Invoke-ClickHouseVerification -HttpEndpoint $ClickHouseHttp -Token $token -User $ClickHouseUser -Password $ClickHousePassword -Timeout $TimeoutSec
} else {
  Invoke-SigNozVerification -BaseUrl $SigNozApi -Token $token -ApiKey $SigNozApiKey -Timeout $TimeoutSec
}

Write-Host 'Canary verification successful.' -ForegroundColor Green
exit 0


