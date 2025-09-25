#Requires -Version 7.0

<#
.SYNOPSIS
    Canary Pattern Library - Predefined log patterns and scenarios for testing

.DESCRIPTION
    This library contains predefined log patterns and scenarios that can be used
    for comprehensive testing of the observability pipeline. It includes realistic
    patterns from various application types and failure scenarios.

.NOTES
    This is a library module that provides pattern definitions and utilities
    for canary testing. It should be imported by other drill scripts.
#>

# Pattern Categories
$Script:PatternCategories = @{
    "ApplicationLogs" = @{
        "WebServer" = @{
            "AccessLog" = @{
                pattern = "{timestamp} {method} {path} {status} {response_time}ms {user_agent}"
                fields = @("timestamp", "method", "path", "status", "response_time", "user_agent")
                examples = @(
                    "2024-01-01 10:00:00 GET /api/users 200 45ms Mozilla/5.0",
                    "2024-01-01 10:00:01 POST /api/login 401 12ms curl/7.68.0",
                    "2024-01-01 10:00:02 GET /api/data 500 1200ms PostmanRuntime/7.26.8"
                )
            }
            "ErrorLog" = @{
                pattern = "{timestamp} [{level}] {message} - {error_code}: {details}"
                fields = @("timestamp", "level", "message", "error_code", "details")
                examples = @(
                    "2024-01-01 10:00:00 [ERROR] Database connection failed - DB_001: Connection timeout",
                    "2024-01-01 10:00:01 [CRITICAL] Memory allocation failed - MEM_001: Out of memory",
                    "2024-01-01 10:00:02 [WARNING] Slow query detected - PERF_001: Query took 5.2s"
                )
            }
        }
        "Database" = @{
            "QueryLog" = @{
                pattern = "{timestamp} [{level}] Query: {query} - Duration: {duration}ms - Rows: {rows}"
                fields = @("timestamp", "level", "query", "duration", "rows")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Query: SELECT * FROM users WHERE active=1 - Duration: 15ms - Rows: 1250",
                    "2024-01-01 10:00:01 [WARNING] Query: SELECT * FROM orders WHERE date > '2023-01-01' - Duration: 2500ms - Rows: 50000",
                    "2024-01-01 10:00:02 [ERROR] Query: UPDATE users SET last_login=NOW() - Duration: 0ms - Rows: 0"
                )
            }
            "ConnectionLog" = @{
                pattern = "{timestamp} [{level}] Connection {action}: {host}:{port} - {result} - {details}"
                fields = @("timestamp", "level", "action", "host", "port", "result", "details")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Connection opened: db-prod-01:5432 - SUCCESS - Pool size: 10/20",
                    "2024-01-01 10:00:01 [ERROR] Connection failed: db-prod-01:5432 - FAILED - Connection timeout",
                    "2024-01-01 10:00:02 [INFO] Connection closed: db-prod-01:5432 - SUCCESS - Duration: 300s"
                )
            }
        }
        "Microservices" = @{
            "ServiceCall" = @{
                pattern = "{timestamp} [{level}] Service call: {service} -> {endpoint} - {status} - {duration}ms"
                fields = @("timestamp", "level", "service", "endpoint", "status", "duration")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Service call: user-service -> /api/users/123 - SUCCESS - 45ms",
                    "2024-01-01 10:00:01 [ERROR] Service call: payment-service -> /api/charge - FAILED - 1200ms",
                    "2024-01-01 10:00:02 [WARNING] Service call: notification-service -> /api/send - TIMEOUT - 5000ms"
                )
            }
            "CircuitBreaker" = @{
                pattern = "{timestamp} [{level}] Circuit breaker {state}: {service} - {reason} - {metrics}"
                fields = @("timestamp", "level", "state", "service", "reason", "metrics")
                examples = @(
                    "2024-01-01 10:00:00 [WARNING] Circuit breaker OPEN: payment-service - High failure rate - Success: 20%, Failures: 80%",
                    "2024-01-01 10:00:01 [INFO] Circuit breaker HALF_OPEN: payment-service - Testing recovery - Success: 50%, Failures: 50%",
                    "2024-01-01 10:00:02 [INFO] Circuit breaker CLOSED: payment-service - Recovery successful - Success: 95%, Failures: 5%"
                )
            }
        }
    }
    
    "SecurityLogs" = @{
        "Authentication" = @{
            "LoginAttempt" = @{
                pattern = "{timestamp} [{level}] Login attempt: {username} from {ip} - {result} - {reason}"
                fields = @("timestamp", "level", "username", "ip", "result", "reason")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Login attempt: admin from 192.168.1.100 - SUCCESS - Valid credentials",
                    "2024-01-01 10:00:01 [WARNING] Login attempt: admin from 192.168.1.101 - FAILED - Invalid password",
                    "2024-01-01 10:00:02 [CRITICAL] Login attempt: admin from 10.0.0.1 - BLOCKED - Brute force detected"
                )
            }
            "Authorization" = @{
                pattern = "{timestamp} [{level}] Access attempt: {user} -> {resource} - {action} - {result}"
                fields = @("timestamp", "level", "user", "resource", "action", "result")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Access attempt: user123 -> /api/admin/users - GET - ALLOWED",
                    "2024-01-01 10:00:01 [WARNING] Access attempt: user456 -> /api/admin/config - POST - DENIED - Insufficient privileges",
                    "2024-01-01 10:00:02 [CRITICAL] Access attempt: anonymous -> /api/admin/system - DELETE - BLOCKED - No authentication"
                )
            }
        }
        "IntrusionDetection" = @{
            "SuspiciousActivity" = @{
                pattern = "{timestamp} [{level}] Suspicious activity detected: {activity_type} from {source} - {severity} - {details}"
                fields = @("timestamp", "level", "activity_type", "source", "severity", "details")
                examples = @(
                    "2024-01-01 10:00:00 [WARNING] Suspicious activity detected: Port scan from 192.168.1.200 - MEDIUM - Scanned 1000 ports in 5s",
                    "2024-01-01 10:00:01 [CRITICAL] Suspicious activity detected: SQL injection attempt from 10.0.0.50 - HIGH - Malicious payload detected",
                    "2024-01-01 10:00:02 [INFO] Suspicious activity detected: Unusual login pattern from 172.16.1.100 - LOW - Multiple failed attempts"
                )
            }
        }
    }
    
    "PerformanceLogs" = @{
        "Metrics" = @{
            "SystemMetrics" = @{
                pattern = "{timestamp} [{level}] System metrics: CPU={cpu}% Memory={memory}% Disk={disk}% Network={network}MB/s"
                fields = @("timestamp", "level", "cpu", "memory", "disk", "network")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] System metrics: CPU=45% Memory=67% Disk=23% Network=12MB/s",
                    "2024-01-01 10:00:01 [WARNING] System metrics: CPU=85% Memory=89% Disk=45% Network=8MB/s",
                    "2024-01-01 10:00:02 [CRITICAL] System metrics: CPU=95% Memory=95% Disk=78% Network=2MB/s"
                )
            }
            "ApplicationMetrics" = @{
                pattern = "{timestamp} [{level}] App metrics: Requests={requests}/s ResponseTime={response_time}ms Errors={errors}/s ActiveConnections={connections}"
                fields = @("timestamp", "level", "requests", "response_time", "errors", "connections")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] App metrics: Requests=150/s ResponseTime=45ms Errors=2/s ActiveConnections=25",
                    "2024-01-01 10:00:01 [WARNING] App metrics: Requests=500/s ResponseTime=200ms Errors=15/s ActiveConnections=80",
                    "2024-01-01 10:00:02 [CRITICAL] App metrics: Requests=1000/s ResponseTime=2000ms Errors=100/s ActiveConnections=200"
                )
            }
        }
        "Profiling" = @{
            "SlowOperation" = @{
                pattern = "{timestamp} [{level}] Slow operation: {operation} - Duration: {duration}ms - Threshold: {threshold}ms - {details}"
                fields = @("timestamp", "level", "operation", "duration", "threshold", "details")
                examples = @(
                    "2024-01-01 10:00:00 [WARNING] Slow operation: Database query - Duration: 2500ms - Threshold: 1000ms - SELECT * FROM large_table",
                    "2024-01-01 10:00:01 [ERROR] Slow operation: API call - Duration: 8000ms - Threshold: 5000ms - External service timeout",
                    "2024-01-01 10:00:02 [INFO] Slow operation: File processing - Duration: 1200ms - Threshold: 2000ms - Large file upload"
                )
            }
        }
    }
    
    "BusinessLogs" = @{
        "Transactions" = @{
            "Payment" = @{
                pattern = "{timestamp} [{level}] Payment transaction: {transaction_id} - Amount: ${amount} - Status: {status} - Method: {method}"
                fields = @("timestamp", "level", "transaction_id", "amount", "status", "method")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Payment transaction: txn_12345 - Amount: $99.99 - Status: SUCCESS - Method: credit_card",
                    "2024-01-01 10:00:01 [ERROR] Payment transaction: txn_12346 - Amount: $149.99 - Status: FAILED - Method: credit_card",
                    "2024-01-01 10:00:02 [WARNING] Payment transaction: txn_12347 - Amount: $299.99 - Status: PENDING - Method: bank_transfer"
                )
            }
            "Order" = @{
                pattern = "{timestamp} [{level}] Order {action}: {order_id} - Customer: {customer_id} - Items: {item_count} - Total: ${total}"
                fields = @("timestamp", "level", "action", "order_id", "customer_id", "item_count", "total")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] Order created: ord_78901 - Customer: cust_12345 - Items: 3 - Total: $199.97",
                    "2024-01-01 10:00:01 [INFO] Order updated: ord_78901 - Customer: cust_12345 - Items: 4 - Total: $249.96",
                    "2024-01-01 10:00:02 [INFO] Order completed: ord_78901 - Customer: cust_12345 - Items: 4 - Total: $249.96"
                )
            }
        }
        "UserActivity" = @{
            "UserAction" = @{
                pattern = "{timestamp} [{level}] User action: {user_id} - {action} - {resource} - {result}"
                fields = @("timestamp", "level", "user_id", "action", "resource", "result")
                examples = @(
                    "2024-01-01 10:00:00 [INFO] User action: user_12345 - VIEW - /products/laptop - SUCCESS",
                    "2024-01-01 10:00:01 [INFO] User action: user_12345 - ADD_TO_CART - /products/laptop - SUCCESS",
                    "2024-01-01 10:00:02 [INFO] User action: user_12345 - CHECKOUT - /cart - SUCCESS"
                )
            }
        }
    }
}

# Pattern Generation Functions
function Get-PatternCategory {
    param([string]$Category)
    return $Script:PatternCategories[$Category]
}

function Get-PatternSubcategory {
    param([string]$Category, [string]$Subcategory)
    return $Script:PatternCategories[$Category][$Subcategory]
}

function Get-PatternDefinition {
    param([string]$Category, [string]$Subcategory, [string]$PatternName)
    return $Script:PatternCategories[$Category][$Subcategory][$PatternName]
}

function Generate-LogEntry {
    param(
        [string]$Category,
        [string]$Subcategory,
        [string]$PatternName,
        [hashtable]$CustomValues = @{}
    )
    
    $patternDef = Get-PatternDefinition -Category $Category -Subcategory $Subcategory -PatternName $PatternName
    if (-not $patternDef) {
        throw "Pattern not found: $Category.$Subcategory.$PatternName"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = $patternDef.pattern -replace "{timestamp}", $timestamp
    
    # Replace other placeholders with realistic values
    $replacements = @{
        "{method}" = @("GET", "POST", "PUT", "DELETE", "PATCH") | Get-Random
        "{path}" = @("/api/users", "/api/orders", "/api/products", "/api/auth", "/api/admin") | Get-Random
        "{status}" = @("200", "201", "400", "401", "403", "404", "500") | Get-Random
        "{response_time}" = Get-Random -Minimum 10 -Maximum 2000
        "{user_agent}" = @("Mozilla/5.0", "curl/7.68.0", "PostmanRuntime/7.26.8", "Python-requests/2.25.1") | Get-Random
        "{level}" = @("INFO", "WARNING", "ERROR", "CRITICAL") | Get-Random
        "{message}" = "Generated log entry"
        "{error_code}" = @("ERR_001", "DB_001", "AUTH_001", "PERF_001") | Get-Random
        "{details}" = "Additional details for the log entry"
        "{username}" = @("admin", "user123", "service_account", "test_user") | Get-Random
        "{ip}" = @("192.168.1.100", "10.0.0.1", "172.16.1.50", "127.0.0.1") | Get-Random
        "{result}" = @("SUCCESS", "FAILED", "PENDING", "BLOCKED") | Get-Random
        "{reason}" = @("Valid credentials", "Invalid password", "Timeout", "Permission denied") | Get-Random
        "{service}" = @("user-service", "payment-service", "notification-service", "auth-service") | Get-Random
        "{endpoint}" = @("/api/users", "/api/payments", "/api/notifications", "/api/auth") | Get-Random
        "{duration}" = Get-Random -Minimum 10 -Maximum 5000
        "{host}" = @("db-prod-01", "cache-01", "api-gateway", "load-balancer") | Get-Random
        "{port}" = @("5432", "6379", "8080", "443") | Get-Random
        "{action}" = @("opened", "closed", "failed", "timeout") | Get-Random
        "{state}" = @("OPEN", "CLOSED", "HALF_OPEN") | Get-Random
        "{metrics}" = "Success: 95%, Failures: 5%"
        "{user}" = @("user123", "admin", "service_user") | Get-Random
        "{resource}" = @("/api/admin", "/api/users", "/api/config") | Get-Random
        "{activity_type}" = @("Port scan", "SQL injection", "Brute force", "Unusual pattern") | Get-Random
        "{source}" = @("192.168.1.200", "10.0.0.50", "172.16.1.100") | Get-Random
        "{severity}" = @("LOW", "MEDIUM", "HIGH", "CRITICAL") | Get-Random
        "{cpu}" = Get-Random -Minimum 10 -Maximum 95
        "{memory}" = Get-Random -Minimum 20 -Maximum 90
        "{disk}" = Get-Random -Minimum 5 -Maximum 85
        "{network}" = Get-Random -Minimum 1 -Maximum 100
        "{requests}" = Get-Random -Minimum 10 -Maximum 1000
        "{app_response_time}" = Get-Random -Minimum 10 -Maximum 2000
        "{errors}" = Get-Random -Minimum 0 -Maximum 50
        "{connections}" = Get-Random -Minimum 5 -Maximum 200
        "{operation}" = @("Database query", "API call", "File processing", "Cache operation") | Get-Random
        "{threshold}" = @("1000", "2000", "5000") | Get-Random
        "{transaction_id}" = "txn_" + (Get-Random -Minimum 10000 -Maximum 99999)
        "{amount}" = (Get-Random -Minimum 10 -Maximum 1000).ToString("F2")
        "{method}" = @("credit_card", "bank_transfer", "paypal", "crypto") | Get-Random
        "{order_id}" = "ord_" + (Get-Random -Minimum 10000 -Maximum 99999)
        "{customer_id}" = "cust_" + (Get-Random -Minimum 10000 -Maximum 99999)
        "{item_count}" = Get-Random -Minimum 1 -Maximum 10
        "{total}" = (Get-Random -Minimum 50 -Maximum 1000).ToString("F2")
        "{user_id}" = "user_" + (Get-Random -Minimum 10000 -Maximum 99999)
        "{action}" = @("VIEW", "ADD_TO_CART", "CHECKOUT", "LOGIN", "LOGOUT") | Get-Random
    }
    
    # Apply custom values first, then defaults
    foreach ($key in $CustomValues.Keys) {
        $replacements[$key] = $CustomValues[$key]
    }
    
    foreach ($placeholder in $replacements.Keys) {
        $logEntry = $logEntry -replace [regex]::Escape($placeholder), $replacements[$placeholder]
    }
    
    return $logEntry
}

function Get-RandomPattern {
    param([string]$Category = $null)
    
    if ($Category) {
        $categories = @($Category)
    } else {
        $categories = $Script:PatternCategories.Keys
    }
    
    $selectedCategory = $categories | Get-Random
    $subcategories = $Script:PatternCategories[$selectedCategory].Keys
    $selectedSubcategory = $subcategories | Get-Random
    $patterns = $Script:PatternCategories[$selectedCategory][$selectedSubcategory].Keys
    $selectedPattern = $patterns | Get-Random
    
    return @{
        Category = $selectedCategory
        Subcategory = $selectedSubcategory
        PatternName = $selectedPattern
        Definition = $Script:PatternCategories[$selectedCategory][$selectedSubcategory][$selectedPattern]
    }
}

function Export-PatternLibrary {
    param([string]$OutputPath = "canary-pattern-library.json")
    
    $exportData = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "1.0.0"
        categories = $Script:PatternCategories
        totalPatterns = ($Script:PatternCategories.Values | ForEach-Object { $_.Values | ForEach-Object { $_.Keys.Count } } | Measure-Object -Sum).Sum
    }
    
    $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

# Export the pattern library when script is run directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $exportPath = Export-PatternLibrary -OutputPath "artifacts/canary-pattern-library.json"
    Write-Host "Pattern library exported to: $exportPath" -ForegroundColor Green
    Write-Host "Total patterns available: $($exportData.totalPatterns)" -ForegroundColor Cyan
}
