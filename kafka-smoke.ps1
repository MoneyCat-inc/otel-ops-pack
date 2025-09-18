# C:\otel\kafka-smoke.ps1
# Optional Kafka broker connectivity check
# ASCII only, PowerShell 5.1 compatible

param(
  [string]$Broker = 'localhost:9092'
)

$ErrorActionPreference = 'Stop'

try {
  $hostname = $Broker.Split(':')[0]
  $port = [int]$Broker.Split(':')[1]
  
  # Try TCP connection (works without external tools)
  $client = New-Object Net.Sockets.TcpClient
  $client.Connect($hostname, $port)
  $client.Close()
  
  Write-Host "Kafka reachable at $Broker" -ForegroundColor Green
  exit 0
} catch {
  Write-Host "Kafka UNREACHABLE at $Broker (optional)" -ForegroundColor Yellow
  exit 1
}
