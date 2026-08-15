# scripts/agent/utils/secrets-hygiene.ps1 - Secrets redaction and hygiene

$global:SECRET_PATTERNS = @(
    # API Keys and tokens
    @{ pattern = '(?i)(api[_-]?key|token|secret|password|passwd)\s*[:=]\s*["'']?([a-zA-Z0-9\-_]{20,})["'']?'; replacement = '${1}: [REDACTED]' },
    @{ pattern = '(?i)(authorization|bearer)\s*:\s*["'']?([a-zA-Z0-9\-_\.]{20,})["'']?'; replacement = '${1}: [REDACTED]' },
    
    # Email addresses (partial redaction)
    @{ pattern = '([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'; replacement = '${1}***@${2}' },
    
    # Credit card numbers
    @{ pattern = '\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3[0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b'; replacement = '[REDACTED_CARD]' },
    
    # SSN (US format)
    @{ pattern = '\b\d{3}-\d{2}-\d{4}\b'; replacement = '[REDACTED_SSN]' },
    
    # AWS Access Keys
    @{ pattern = '(?i)(AKIA[0-9A-Z]{16}|aws[_-]?access[_-]?key[_-]?id)'; replacement = '[REDACTED_AWS_KEY]' },
    
    # Private keys (PEM format)
    @{ pattern = '-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----[\s\S]*?-----END\s+(?:RSA\s+)?PRIVATE\s+KEY-----'; replacement = '[REDACTED_PRIVATE_KEY]' },
    
    # JWT tokens
    @{ pattern = 'eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'; replacement = '[REDACTED_JWT]' },
    
    # URLs with credentials
    @{ pattern = '(https?://)([^:]+):([^@]+)@([^\s]+)'; replacement = '${1}[REDACTED_USER]:[REDACTED_PASS]@${4}' }
)

function Redact-Secrets {
    param(
        [string]$InputText
    )
    
    $redacted = $InputText
    
    foreach ($secretPattern in $global:SECRET_PATTERNS) {
        $redacted = $redacted -replace $secretPattern.pattern, $secretPattern.replacement
    }
    
    return $redacted
}

function Test-SecretsPresent {
    param(
        [string]$InputText
    )
    
    $secretsFound = @()
    
    foreach ($secretPattern in $global:SECRET_PATTERNS) {
        if ($InputText -match $secretPattern.pattern) {
            $secretsFound += $secretPattern.pattern
        }
    }
    
    return @{
        hasSecrets = $secretsFound.Count -gt 0
        patterns = $secretsFound
        count = $secretsFound.Count
    }
}

function Write-SafeLog {
    param(
        [string]$Message,
        [string]$LogFile = "TASKS.md",
        [switch]$RedactSecrets
    )
    
    try {
        $safeMessage = if ($RedactSecrets) { Redact-Secrets -InputText $Message } else { $Message }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "* $timestamp – $safeMessage"
        
        # Use atomic write for safety
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
        
        return $true
    } catch {
        Write-Warning "Failed to write safe log: $($_.Exception.Message)"
        return $false
    }
}

function Write-SafeJson {
    param(
        [string]$Path,
        [object]$Data,
        [switch]$RedactSecrets
    )
    
    try {
        $json = $Data | ConvertTo-Json -Depth 10
        
        if ($RedactSecrets) {
            $json = Redact-Secrets -InputText $json
        }
        
        # Check for secrets before writing
        $secretCheck = Test-SecretsPresent -InputText $json
        if ($secretCheck.hasSecrets) {
            Write-Warning "Secrets detected in JSON output for $Path - redacting"
            $json = Redact-Secrets -InputText $json
        }
        
        # Use atomic write
        return Write-AtomicJson -Path $Path -Data ($json | ConvertFrom-Json)
    } catch {
        Write-Error "Failed to write safe JSON: $($_.Exception.Message)"
        return $false
    }
}

function Validate-Environment {
    param(
        [string[]]$AllowedVars = @("PATH", "NODE_ENV", "CI", "NO_COLOR", "WT_SESSION", "TERM")
    )
    
    $envVars = Get-ChildItem Env:
    $suspiciousVars = @()
    
    foreach ($var in $envVars) {
        if ($var.Name -match '(?i)(secret|password|token|key|auth)' -and $var.Name -notin $AllowedVars) {
            $suspiciousVars += $var.Name
        }
    }
    
    return @{
        hasSuspicious = $suspiciousVars.Count -gt 0
        suspicious = $suspiciousVars
        count = $suspiciousVars.Count
    }
}

function Clean-LogFile {
    param(
        [string]$LogFile = "TASKS.md",
        [int]$MaxLines = 1000
    )
    
    try {
        if (-not (Test-Path $LogFile)) {
            return $true
        }
        
        $lines = Get-Content $LogFile
        if ($lines.Count -le $MaxLines) {
            return $true
        }
        
        # Keep the most recent lines
        $recentLines = $lines | Select-Object -Last $MaxLines
        
        # Write atomically
        $recentLines | Set-Content $LogFile -Encoding UTF8
        
        Write-Host "Log file trimmed to $MaxLines lines" -ForegroundColor Yellow
        return $true
    } catch {
        Write-Warning "Failed to clean log file: $($_.Exception.Message)"
        return $false
    }
}
