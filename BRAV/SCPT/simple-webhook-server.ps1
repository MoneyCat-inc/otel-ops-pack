# Simple Webhook Test Server
# Creates a basic HTTP server to receive webhook notifications

param(
    [int]$Port = 3003,
    [string]$LogFile = "artifacts/webhook-logs.json"
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Simple Webhook Test Server - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check if port is available
Write-Host "`nExamine: Checking port availability..." -ForegroundColor Green

$PortCheck = netstat -an | Select-String ":$Port "
if ($PortCheck) {
    Write-Host "ERROR Port $Port is already in use" -ForegroundColor Red
    Write-Host "Please stop the service using port $Port or use a different port" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK Port $Port is available" -ForegroundColor Green

# Clean: Prepare webhook server
Write-Host "`nClean: Starting webhook test server..." -ForegroundColor Green

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

# Initialize log file
$LogEntries = @()
$LogEntries | ConvertTo-Json -Depth 3 | Out-File $LogFile -Encoding UTF8

Write-Host "Webhook server starting on port $Port..." -ForegroundColor Yellow
Write-Host "Log file: $LogFile" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow

# Create a simple HTTP listener
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")
$Listener.Start()

Write-Host "`nWebhook server is running on http://localhost:$Port" -ForegroundColor Green
Write-Host "Test webhook endpoint: http://localhost:$Port/api/webhooks/alerts" -ForegroundColor Cyan

try {
    while ($Listener.IsListening) {
        # Wait for a request
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response
        
        # Log the request
        $LogEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            method = $Request.HttpMethod
            url = $Request.Url.AbsoluteUri
            path = $Request.Url.AbsolutePath
            user_agent = $Request.UserAgent
            content_type = $Request.ContentType
            content_length = $Request.ContentLength64
            headers = @{}
            body = ""
        }
        
        # Capture headers
        $Request.Headers.AllKeys | ForEach-Object {
            $LogEntry.headers[$_] = $Request.Headers[$_]
        }
        
        # Read request body
        if ($Request.HasEntityBody) {
            $Reader = New-Object System.IO.StreamReader($Request.InputStream)
            $LogEntry.body = $Reader.ReadToEnd()
            $Reader.Close()
        }
        
        # Add to log entries
        $LogEntries += $LogEntry
        
        # Save log entries
        $LogEntries | ConvertTo-Json -Depth 3 | Out-File $LogFile -Encoding UTF8
        
        # Prepare response
        $Response.StatusCode = 200
        $Response.ContentType = "application/json"
        
        $ResponseBody = @{
            status = "success"
            message = "Webhook received"
            timestamp = $LogEntry.timestamp
            received_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        
        $ResponseBytes = [System.Text.Encoding]::UTF8.GetBytes(($ResponseBody | ConvertTo-Json -Compress))
        $Response.ContentLength64 = $ResponseBytes.Length
        $Response.OutputStream.Write($ResponseBytes, 0, $ResponseBytes.Length)
        $Response.OutputStream.Close()
        
        # Display received webhook
        Write-Host "`nWebhook received:" -ForegroundColor Green
        Write-Host "  Method: $($LogEntry.method)" -ForegroundColor White
        Write-Host "  Path: $($LogEntry.path)" -ForegroundColor White
        Write-Host "  Content-Type: $($LogEntry.content_type)" -ForegroundColor White
        Write-Host "  Body: $($LogEntry.body)" -ForegroundColor White
        Write-Host "  Timestamp: $($LogEntry.timestamp)" -ForegroundColor White
    }
} catch {
    Write-Host "`nWebhook server stopped: $($_.Exception.Message)" -ForegroundColor Yellow
} finally {
    $Listener.Stop()
    $Listener.Close()
}

# Report: Generate webhook log summary
Write-Host "`nReport: Webhook log summary" -ForegroundColor Green

if (Test-Path $LogFile) {
    $LogContent = Get-Content $LogFile -Raw | ConvertFrom-Json
    Write-Host "Total webhooks received: $($LogContent.Count)" -ForegroundColor Cyan
    
    if ($LogContent.Count -gt 0) {
        Write-Host "`nRecent webhooks:" -ForegroundColor Yellow
        $LogContent | Select-Object -Last 5 | ForEach-Object {
            Write-Host "  $($_.timestamp): $($_.method) $($_.path)" -ForegroundColor White
        }
    }
}

Write-Host "`nLog file saved to: $LogFile" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host "Next: Test webhook notifications using the test script" -ForegroundColor Yellow
Write-Host "Then: Configure alert delivery and verify end-to-end flow" -ForegroundColor Yellow
