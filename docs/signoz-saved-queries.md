# SigNoz Saved Queries for OTel Observability Stack
# This file contains pre-configured queries for quick spot-checks

# Query 1: Local Deployment Environment Logs
# Purpose: View all logs from local deployment environment
# SigNoz UI: Logs → Add Filter → resource.attributes["deployment.env"] = "local"
{
  "name": "Local Deployment Logs",
  "description": "All logs from local deployment environment",
  "query": "resource.attributes[\"deployment.env\"] = \"local\"",
  "timeRange": "Last 1 hour",
  "category": "Environment"
}

# Query 2: Queue Health Logs
# Purpose: Monitor queue health and performance
# SigNoz UI: Logs → Add Filter → log.file.path contains "C:/logs/queue/health.log"
{
  "name": "Queue Health Logs",
  "description": "Queue steward health and performance logs",
  "query": "log.file.path contains \"C:/logs/queue/health.log\"",
  "timeRange": "Last 30 minutes",
  "category": "Performance"
}

# Query 3: Windows Event Logs
# Purpose: Monitor Windows Event Log entries
# SigNoz UI: Logs → Add Filter → attributes["winlog.channel"] exists
{
  "name": "Windows Event Logs",
  "description": "Windows Event Log entries from Application and System channels",
  "query": "attributes[\"winlog.channel\"] exists",
  "timeRange": "Last 1 hour",
  "category": "System"
}

# Query 4: Canary Test Logs
# Purpose: Verify canary test execution
# SigNoz UI: Logs → Add Filter → message contains "canary test"
{
  "name": "Canary Test Logs",
  "description": "Canary test execution logs for pipeline verification",
  "query": "message contains \"canary test\"",
  "timeRange": "Last 2 hours",
  "category": "Testing"
}

# Query 5: Error Logs
# Purpose: Monitor error conditions
# SigNoz UI: Logs → Add Filter → severity = "ERROR"
{
  "name": "Error Logs",
  "description": "All error-level log entries",
  "query": "severity = \"ERROR\"",
  "timeRange": "Last 24 hours",
  "category": "Errors"
}

# Query 6: Service Health Logs
# Purpose: Monitor service health indicators
# SigNoz UI: Logs → Add Filter → message contains "health"
{
  "name": "Service Health Logs",
  "description": "Service health check and status logs",
  "query": "message contains \"health\"",
  "timeRange": "Last 1 hour",
  "category": "Health"
}

# Usage Instructions:
# 1. Copy the query string from the "query" field
# 2. Open SigNoz UI at http://localhost:8080
# 3. Navigate to Logs
# 4. Click "Add Filter"
# 5. Paste the query string
# 6. Adjust time range as needed
# 7. Save as favorite for quick access

# Quick Commands for Manual Verification:
# Get-Process -Name otelcol-contrib
# Get-NetTCPConnection -State Listen -LocalPort 5317,5318
# Invoke-WebRequest -Uri http://127.0.0.1:13134/healthz -UseBasicParsing
# pwsh -File scripts\automated-service-monitoring.ps1
