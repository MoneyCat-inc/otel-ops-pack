# SigNoz Authenticated Request Helper Functions
# Add these to your PowerShell profile or scripts

function Invoke-SigNozQuery {
    param(
        [string]$Query,
        [string]$AuthToken = "YourSuperSecretJWTToken123!@#WithAtLeast32CharactersLong",
        [string]$BaseUrl = "http://localhost:8080"
    )
    
    $headers = @{
        'Authorization' = "Bearer $AuthToken"
        'Content-Type' = 'application/json'
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v5/query_range" -Method Post -Body $Query -Headers $headers -TimeoutSec 10
        return $response
    } catch {
        Write-Error "SigNoz query failed: $($_.Exception.Message)"
        return $null
    }
}

function Get-SigNozLogs {
    param(
        [string]$Filter = "*",
        [int]$Limit = 100,
        [int]$MinutesBack = 5
    )
    
    $start = [long]([DateTimeOffset]::UtcNow.AddMinutes(-$MinutesBack).ToUnixTimeMilliseconds())
    $end = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    
    $query = @{
        start = $start
        end = $end
        requestType = "raw"
        compositeQuery = @{
            queries = @(@{
                type = "builder_query"
                spec = @{
                    name = "logs"
                    signal = "logs"
                    filter = @{ expression = $Filter }
                    limit = $Limit
                }
            })
        }
    } | ConvertTo-Json -Depth 8
    
    return Invoke-SigNozQuery -Query $query
}

# Usage examples:
# Get-SigNozLogs -Filter "message contains 'canary test'" -Limit 10
# Get-SigNozLogs -Filter "severity_text = 'ERROR'" -MinutesBack 60
