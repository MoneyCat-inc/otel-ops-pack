# Simple Alert Webhook Server
# Receives SigNoz alerts and logs them

param(
    [int]$Port = 3003,
    [string]$LogFile = "artifacts/alert-webhook.log"
)

Write-Host "=== SigNoz Alert Webhook Server ===" -ForegroundColor Green
Write-Host "Listening on port $Port" -ForegroundColor Yellow
Write-Host "Log file: $LogFile" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

# Simple HTTP server using .NET HttpListener
Add-Type -AssemblyName System.Net.Http

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Prefixes.Add("http://*:$Port/")

try {
    $listener.Start()
    Write-Host "✅ Webhook server started successfully" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Cyan
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        Write-Host "`n📨 Received request: $($request.HttpMethod) $($request.Url.PathAndQuery)" -ForegroundColor Cyan
        
        if ($request.HttpMethod -eq "POST" -and $request.Url.PathAndQuery -eq "/api/alerts/webhook") {
            # Read the request body
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            $reader.Close()
            
            # Parse JSON
            try {
                $alertData = $body | ConvertFrom-Json
                
                # Log the alert
                $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
                $logEntry = @{
                    timestamp = $timestamp
                    method = $request.HttpMethod
                    path = $request.Url.PathAndQuery
                    user_agent = $request.UserAgent
                    alert_data = $alertData
                } | ConvertTo-Json -Depth 10
                
                Add-Content -Path $LogFile -Value $logEntry
                
                # Display alert info
                Write-Host "🚨 ALERT RECEIVED:" -ForegroundColor Red
                if ($alertData.alerts) {
                    foreach ($alert in $alertData.alerts) {
                        Write-Host "  Alert: $($alert.labels.alertname)" -ForegroundColor Yellow
                        Write-Host "  Status: $($alert.status)" -ForegroundColor Yellow
                        Write-Host "  Severity: $($alert.labels.severity)" -ForegroundColor Yellow
                        Write-Host "  Description: $($alert.annotations.description)" -ForegroundColor White
                    }
                }
                
                # Send success response
                $response.StatusCode = 200
                $response.ContentType = "application/json"
                $responseBody = '{"status": "success", "message": "Alert received"}'
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                
            } catch {
                Write-Warning "Failed to parse alert JSON: $($_.Exception.Message)"
                $response.StatusCode = 400
                $responseBody = '{"status": "error", "message": "Invalid JSON"}'
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        } else {
            # Handle other requests
            $response.StatusCode = 404
            $responseBody = '{"status": "error", "message": "Not found"}'
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Error "Webhook server error: $($_.Exception.Message)"
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    Write-Host "`n🛑 Webhook server stopped" -ForegroundColor Yellow
}
