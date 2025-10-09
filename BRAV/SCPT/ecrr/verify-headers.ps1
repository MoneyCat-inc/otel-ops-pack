param(
    [string]$Url = "http://localhost:3003",
    [switch]$AsObject,
    [switch]$WriteLog
)

$ErrorActionPreference = "Stop"

function Get-HeaderValue {
    param(
        [System.Collections.IDictionary]$Headers,
        [string]$Name
    )
    if ($Headers.ContainsKey($Name)) { return [string]$Headers[$Name] }
    # Fallback for case-insensitive header dictionaries
    foreach ($k in $Headers.Keys) {
        if ($k -ieq $Name) { return [string]$Headers[$k] }
    }
    return ""
}

try {
    $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -TimeoutSec 10
    $coop = Get-HeaderValue -Headers $response.Headers -Name 'Cross-Origin-Opener-Policy'
    $coep = Get-HeaderValue -Headers $response.Headers -Name 'Cross-Origin-Embedder-Policy'
    $corp = Get-HeaderValue -Headers $response.Headers -Name 'Cross-Origin-Resource-Policy'

    $result = [pscustomobject]@{
        Url = $Url
        StatusCode = $response.StatusCode
        CrossOriginOpenerPolicy = $coop
        CrossOriginEmbedderPolicy = $coep
        CrossOriginResourcePolicy = $corp
        ObservedTime = (Get-Date).ToString('s')
    }

    if ($WriteLog) {
        $null = New-Item -ItemType Directory -Force -Path "artifacts" | Out-Null
        $logPath = "artifacts/ecrr-01-verification.log"
        $lines = @(
            "Cross-Origin-Opener-Policy: $coop",
            "Cross-Origin-Embedder-Policy: $coep",
            "Cross-Origin-Resource-Policy: $corp"
        )
        Set-Content -Path $logPath -Value $lines -Encoding utf8
    }

    if ($AsObject) { return $result }

    Write-Output "Cross-Origin-Opener-Policy: $coop"
    Write-Output "Cross-Origin-Embedder-Policy: $coep"
    Write-Output "Cross-Origin-Resource-Policy: $corp"
}
catch {
    if ($AsObject) {
        return [pscustomobject]@{
            Url = $Url
            StatusCode = 0
            CrossOriginOpenerPolicy = ""
            CrossOriginEmbedderPolicy = ""
            CrossOriginResourcePolicy = ""
            ObservedTime = (Get-Date).ToString('s')
            Error = $_.Exception.Message
        }
    }
    throw
}

param(
    [string]$Url = "http://localhost:3003",
    [switch]$AsObject
)

$ErrorActionPreference = "Stop"
try {
    $response = Invoke-WebRequest -Uri $Url -Method Head -MaximumRedirection 0 -ErrorAction Stop
} catch {
    $response = $_.Exception.Response
    if (-not $response) {
        throw
    }
}

if ($AsObject) {
    return [pscustomobject]@{
        StatusCode = $response.StatusCode
        Headers = $response.Headers
    }
}

Write-Output "Status: $($response.StatusCode)"
Write-Output "Cross-Origin-Opener-Policy: $($response.Headers['Cross-Origin-Opener-Policy'])"
Write-Output "Cross-Origin-Embedder-Policy: $($response.Headers['Cross-Origin-Embedder-Policy'])"
Write-Output "Cross-Origin-Resource-Policy: $($response.Headers['Cross-Origin-Resource-Policy'])"
