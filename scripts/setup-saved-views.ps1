# SigNoz Saved Views Configuration
# ECRR Framework Implementation - View Management

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = "local-signoz-jwt-secret-rotate",
    [switch]$DryRun = $false
)

Write-Host "👁️ SigNoz Saved Views Configuration" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Configuration
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

# Saved Views Configuration
$SavedViews = @(
    # =============================================================================
    # LOG VIEWS
    # =============================================================================
    @{
        name = "Critical Errors Only"
        description = "Filter for critical and error level logs"
        type = "logs"
        query = "severity=\"error\" OR severity=\"critical\""
        filters = @{
            severity = @("error", "critical")
        }
        tags = @("errors", "critical", "monitoring")
    },
    @{
        name = "Authentication Issues"
        description = "Logs related to authentication failures and security issues"
        type = "logs"
        query = "message=~\"auth.*fail|login.*fail|unauthorized|forbidden\""
        filters = @{
            message = "auth.*fail|login.*fail|unauthorized|forbidden"
        }
        tags = @("auth", "security", "failures")
    },
    @{
        name = "Resonai Backend Logs"
        description = "All logs from Resonai backend service"
        type = "logs"
        query = "service_name=\"resonai-backend\""
        filters = @{
            service_name = "resonai-backend"
        }
        tags = @("backend", "resonai", "service")
    },
    @{
        name = "High Status Code Responses"
        description = "HTTP responses with status codes >= 400"
        type = "logs"
        query = "status_code>=400"
        filters = @{
            status_code = ">=400"
        }
        tags = @("http", "errors", "responses")
    },
    @{
        name = "Database Operations"
        description = "Logs related to database operations and queries"
        type = "logs"
        query = "message=~\"database|db|sql|query|connection\""
        filters = @{
            message = "database|db|sql|query|connection"
        }
        tags = @("database", "queries", "performance")
    },
    @{
        name = "Windows Event Logs"
        description = "Windows Event Log entries from the system"
        type = "logs"
        query = "log.source=\"windows_event_log\""
        filters = @{
            log_source = "windows_event_log"
        }
        tags = @("windows", "system", "events")
    },
    @{
        name = "Canary Test Results"
        description = "Results from canary tests and health checks"
        type = "logs"
        query = "message=~\"canary|health.*check|test.*result\""
        filters = @{
            message = "canary|health.*check|test.*result"
        }
        tags = @("canary", "health", "testing")
    },

    # =============================================================================
    # TRACE VIEWS
    # =============================================================================
    @{
        name = "Slow API Requests"
        description = "API requests taking longer than 1 second"
        type = "traces"
        query = "service_name=\"resonai-backend\" AND duration>1000000000"
        filters = @{
            service_name = "resonai-backend"
            duration = ">1000000000"
        }
        tags = @("api", "performance", "slow")
    },
    @{
        name = "Failed Requests"
        description = "Traces for failed HTTP requests"
        type = "traces"
        query = "service_name=\"resonai-backend\" AND http.status_code>=400"
        filters = @{
            service_name = "resonai-backend"
            http_status_code = ">=400"
        }
        tags = @("api", "errors", "failures")
    },
    @{
        name = "Database Query Traces"
        description = "Traces containing database operations"
        type = "traces"
        query = "service_name=\"resonai-backend\" AND span_name=~\"db.*|query.*|prisma.*\""
        filters = @{
            service_name = "resonai-backend"
            span_name = "db.*|query.*|prisma.*"
        }
        tags = @("database", "queries", "prisma")
    },
    @{
        name = "Frontend User Interactions"
        description = "User interaction traces from the frontend"
        type = "traces"
        query = "service_name=\"resonai-frontend\" AND span_name=~\"user.*interaction|click|submit\""
        filters = @{
            service_name = "resonai-frontend"
            span_name = "user.*interaction|click|submit"
        }
        tags = @("frontend", "ui", "interactions")
    },
    @{
        name = "Authentication Flow"
        description = "Traces related to authentication processes"
        type = "traces"
        query = "service_name=\"resonai-backend\" AND span_name=~\"auth.*|login.*|session.*\""
        filters = @{
            service_name = "resonai-backend"
            span_name = "auth.*|login.*|session.*"
        }
        tags = @("auth", "security", "sessions")
    },

    # =============================================================================
    # METRIC VIEWS
    # =============================================================================
    @{
        name = "High Error Rate Services"
        description = "Services with error rates above 1%"
        type = "metrics"
        query = "rate(http_requests_total{status_code=~\"5..\"}[5m]) / rate(http_requests_total[5m]) * 100"
        filters = @{
            metric_name = "http_requests_total"
            status_code = "5.."
        }
        tags = @("metrics", "errors", "rates")
    },
    @{
        name = "Memory Usage Trends"
        description = "Memory usage trends across services"
        type = "metrics"
        query = "process_resident_memory_bytes / (1024*1024*1024)"
        filters = @{
            metric_name = "process_resident_memory_bytes"
        }
        tags = @("metrics", "memory", "performance")
    },
    @{
        name = "Request Rate by Service"
        description = "Request rates grouped by service"
        type = "metrics"
        query = "rate(http_requests_total[5m])"
        filters = @{
            metric_name = "http_requests_total"
        }
        tags = @("metrics", "requests", "throughput")
    }
)

# Create saved views
Write-Host "📋 Creating saved views..." -ForegroundColor Yellow
$CreatedViews = @()
$FailedViews = @()

foreach ($View in $SavedViews) {
    Write-Host "  Creating view: $($View.name)" -ForegroundColor Cyan
    
    if (-not $DryRun) {
        try {
            $ViewConfig = @{
                name = $View.name
                description = $View.description
                type = $View.type
                query = $View.query
                filters = $View.filters
                tags = $View.tags
                isPublic = $true
                createdBy = "system"
            }
            
            $ViewResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/savedViews" -Method POST -Headers $Headers -Body ($ViewConfig | ConvertTo-Json -Depth 3) -TimeoutSec 10
            
            Write-Host "    ✅ View created: $($View.name)" -ForegroundColor Green
            $CreatedViews += $View.name
            
        } catch {
            Write-Host "    ❌ Failed to create view: $($_.Exception.Message)" -ForegroundColor Red
            $FailedViews += $View.name
        }
    } else {
        Write-Host "    🔍 Dry run: View would be created" -ForegroundColor Gray
        $CreatedViews += $View.name
    }
}

# Generate summary report
Write-Host "`n📊 Saved Views Summary" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host "✅ Created views: $($CreatedViews.Count)" -ForegroundColor Green
Write-Host "❌ Failed views: $($FailedViews.Count)" -ForegroundColor Red

if ($CreatedViews.Count -gt 0) {
    Write-Host "`n📋 Successfully Created Views:" -ForegroundColor Green
    foreach ($View in $CreatedViews) {
        Write-Host "  • $View" -ForegroundColor White
    }
}

if ($FailedViews.Count -gt 0) {
    Write-Host "`n❌ Failed View Creation:" -ForegroundColor Red
    foreach ($View in $FailedViews) {
        Write-Host "  • $View" -ForegroundColor White
    }
}

# Save configuration to artifacts
$ConfigPath = "artifacts/signoz-saved-views.json"
$ViewConfiguration = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    signoz_url = $SigNozUrl
    views = $SavedViews
    summary = @{
        total_views = $SavedViews.Count
        created_views = $CreatedViews.Count
        failed_views = $FailedViews.Count
        success_rate = [math]::Round(($CreatedViews.Count / $SavedViews.Count) * 100, 2)
    }
}

$ViewConfiguration | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath
Write-Host "`n📝 Saved views configuration saved to: $ConfigPath" -ForegroundColor Green

# Next steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Verify views in SigNoz UI: $SigNozUrl/logs and $SigNozUrl/traces" -ForegroundColor White
Write-Host "2. Test saved views by applying filters" -ForegroundColor White
Write-Host "3. Share views with team members" -ForegroundColor White
Write-Host "4. Create additional custom views as needed" -ForegroundColor White

Write-Host "`n✅ Saved views setup completed!" -ForegroundColor Green
