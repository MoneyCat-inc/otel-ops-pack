# Validate SigNoz/OTel Stack Configuration
# Comprehensive validation of all configuration files and dependencies

param(
    [switch]$FixIssues,
    [switch]$GenerateReport,
    [string]$OutputPath = "artifacts/validation-report.json"
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Color functions for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$msg) Write-ColorOutput "ℹ️  $msg" "Cyan" }
function Write-Success { param([string]$msg) Write-ColorOutput "✅ $msg" "Green" }
function Write-Warning { param([string]$msg) Write-ColorOutput "⚠️  $msg" "Yellow" }
function Write-Error { param([string]$msg) Write-ColorOutput "❌ $msg" "Red" }

# Validation results
$validationResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    OverallStatus = "unknown"
    Issues = @()
    Warnings = @()
    Recommendations = @()
    FileChecks = @{}
    ServiceChecks = @{}
}

# File validation functions
function Test-RequiredFile {
    param(
        [string]$FilePath,
        [string]$Description,
        [string]$TemplateContent = $null
    )
    
    $result = @{
        Path = $FilePath
        Description = $Description
        Exists = $false
        Valid = $false
        Issues = @()
    }
    
    if (Test-Path $FilePath) {
        $result.Exists = $true
        $result.Valid = $true
        
        # Additional validation based on file type
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        switch ($extension) {
            ".yaml" {
                try {
                    $content = Get-Content $FilePath -Raw
                    # Basic YAML validation
                    if ($content -match "^\s*---" -or $content -match "^\s*[a-zA-Z]") {
                        $result.Valid = $true
                    } else {
                        $result.Valid = $false
                        $result.Issues += "Invalid YAML format"
                    }
                } catch {
                    $result.Valid = $false
                    $result.Issues += "YAML parsing error: $($_.Exception.Message)"
                }
            }
            ".yml" {
                try {
                    $content = Get-Content $FilePath -Raw
                    # Basic YAML validation
                    if ($content -match "^\s*---" -or $content -match "^\s*[a-zA-Z]") {
                        $result.Valid = $true
                    } else {
                        $result.Valid = $false
                        $result.Issues += "Invalid YAML format"
                    }
                } catch {
                    $result.Valid = $false
                    $result.Issues += "YAML parsing error: $($_.Exception.Message)"
                }
            }
            ".xml" {
                try {
                    [xml]$xml = Get-Content $FilePath
                    $result.Valid = $true
                } catch {
                    $result.Valid = $false
                    $result.Issues += "XML parsing error: $($_.Exception.Message)"
                }
            }
            ".json" {
                try {
                    $content = Get-Content $FilePath -Raw
                    $json = $content | ConvertFrom-Json
                    $result.Valid = $true
                } catch {
                    $result.Valid = $false
                    $result.Issues += "JSON parsing error: $($_.Exception.Message)"
                }
            }
        }
        
        Write-Success "$Description found and valid"
    } else {
        $result.Issues += "File not found"
        Write-Error "$Description not found: $FilePath"
        
        if ($FixIssues -and $TemplateContent) {
            try {
                # Create directory if it doesn't exist
                $directory = Split-Path $FilePath -Parent
                if (-not (Test-Path $directory)) {
                    New-Item -ItemType Directory -Path $directory -Force | Out-Null
                }
                
                $TemplateContent | Out-File -FilePath $FilePath -Encoding UTF8
                Write-Success "Created $Description from template"
                $result.Exists = $true
                $result.Valid = $true
            } catch {
                $result.Issues += "Failed to create file: $($_.Exception.Message)"
                Write-Error "Failed to create ${Description}: $($_.Exception.Message)"
            }
        }
    }
    
    return $result
}

function Test-EnvironmentVariables {
    param([string]$FilePath)
    
    $result = @{
        Path = $FilePath
        RequiredVars = @()
        MissingVars = @()
        Valid = $false
    }
    
    $requiredVars = @(
        "NEXTAUTH_SECRET",
        "USER_HASH_SALT", 
        "SIGNOZ_JWT_SECRET",
        "OTEL_EXPORTER_OTLP_ENDPOINT"
    )
    
    if (Test-Path $FilePath) {
        $envContent = Get-Content $FilePath -Raw
        
        foreach ($var in $requiredVars) {
            $result.RequiredVars += $var
            if ($envContent -match "^$var\s*=") {
                # Variable is defined
            } else {
                $result.MissingVars += $var
            }
        }
        
        $result.Valid = $result.MissingVars.Count -eq 0
        
        if ($result.Valid) {
            Write-Success "Environment variables validation passed"
        } else {
            Write-Warning "Missing environment variables: $($result.MissingVars -join ', ')"
        }
    } else {
        Write-Error "Environment file not found: $FilePath"
        $result.MissingVars = $requiredVars
    }
    
    return $result
}

function Test-DockerComposeConfiguration {
    param([string]$FilePath)
    
    $result = @{
        Path = $FilePath
        Valid = $false
        Issues = @()
        Services = @()
        Networks = @()
        Volumes = @()
    }
    
    if (-not (Test-Path $FilePath)) {
        $result.Issues += "Docker Compose file not found"
        Write-Error "Docker Compose file not found: $FilePath"
        return $result
    }
    
    try {
        # Validate docker-compose syntax
        $output = docker compose -f $FilePath config 2>&1
        if ($LASTEXITCODE -eq 0) {
            $result.Valid = $true
            Write-Success "Docker Compose configuration is valid"
            
            # Parse services
            $config = docker compose -f $FilePath config --format json | ConvertFrom-Json
            $result.Services = $config.services.PSObject.Properties.Name
            $result.Networks = $config.networks.PSObject.Properties.Name
            $result.Volumes = $config.volumes.PSObject.Properties.Name
            
            Write-Info "Found services: $($result.Services -join ', ')"
            Write-Info "Found networks: $($result.Networks -join ', ')"
            Write-Info "Found volumes: $($result.Volumes -join ', ')"
        } else {
            $result.Issues += "Docker Compose validation failed: $output"
            Write-Error "Docker Compose validation failed: $output"
        }
    } catch {
        $result.Issues += "Docker Compose parsing error: $($_.Exception.Message)"
        Write-Error "Docker Compose parsing error: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-PortAvailability {
    param([int[]]$Ports)
    
    $result = @{
        Ports = $Ports
        Available = @()
        InUse = @()
    }
    
    foreach ($port in $Ports) {
        try {
            $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
            if (-not $connection) {
                $result.Available += $port
            } else {
                $result.InUse += $port
                Write-Warning "Port $port is already in use"
            }
        } catch {
            $result.Available += $port
        }
    }
    
    return $result
}

# Main validation process
Write-Info "Starting configuration validation..."

# Check required files
$requiredFiles = @(
    @{
        Path = "docker-compose.yml"
        Description = "Optimized Docker Compose file"
    },
    @{
        Path = ".env"
        Description = "Environment variables file"
    },
    @{
        Path = "signoz-collector-config.yaml"
        Description = "SigNoz OTel Collector configuration"
        Template = @"
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  clickhousetraces:
    dsn: tcp://signoz-clickhouse:9000
  clickhousemetrics:
    dsn: tcp://signoz-clickhouse:9000
  clickhouselogs:
    dsn: tcp://signoz-clickhouse:9000

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [clickhousetraces]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [clickhousemetrics]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [clickhouselogs]
"@
    },
    @{
        Path = "clickhouse-cluster-config.xml"
        Description = "ClickHouse cluster configuration"
        Template = @"
<?xml version="1.0"?>
<clickhouse>
    <remote_servers>
        <signoz_cluster>
            <shard>
                <replica>
                    <host>signoz-clickhouse</host>
                    <port>9000</port>
                </replica>
            </shard>
        </signoz_cluster>
    </remote_servers>
</clickhouse>
"@
    },
    @{
        Path = "clickhouse-zookeeper-config.xml"
        Description = "ClickHouse ZooKeeper configuration"
        Template = @"
<?xml version="1.0"?>
<clickhouse>
    <zookeeper>
        <node index="1">
            <host>signoz-zookeeper</host>
            <port>2181</port>
        </node>
    </zookeeper>
</clickhouse>
"@
    }
)

foreach ($file in $requiredFiles) {
    $result = Test-RequiredFile -FilePath $file.Path -Description $file.Description -TemplateContent $file.Template
    $validationResults.FileChecks[$file.Path] = $result
    
    if (-not $result.Valid) {
        $validationResults.Issues += "$($file.Description) validation failed"
    }
}

# Validate environment variables
$envResult = Test-EnvironmentVariables -FilePath ".env"
$validationResults.ServiceChecks["environment"] = $envResult

# Validate Docker Compose configuration
$composeResult = Test-DockerComposeConfiguration -FilePath "docker-compose.yml"
$validationResults.ServiceChecks["docker-compose"] = $composeResult

# Check port availability
$requiredPorts = @(8080, 4317, 4318, 3001, 8123, 9000)
$portResult = Test-PortAvailability -Ports $requiredPorts
$validationResults.ServiceChecks["ports"] = $portResult

if ($portResult.InUse.Count -gt 0) {
    $validationResults.Warnings += "Some required ports are in use: $($portResult.InUse -join ', ')"
}

# Check Docker availability
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker is available: $dockerVersion"
        $validationResults.ServiceChecks["docker"] = @{ Available = $true; Version = $dockerVersion }
    } else {
        throw "Docker not available"
    }
} catch {
    Write-Error "Docker is not available or not running"
    $validationResults.Issues += "Docker is not available"
    $validationResults.ServiceChecks["docker"] = @{ Available = $false; Error = $_.Exception.Message }
}

# Check Docker Compose availability
try {
    $composeVersion = docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker Compose is available: $composeVersion"
        $validationResults.ServiceChecks["docker-compose-cli"] = @{ Available = $true; Version = $composeVersion }
    } else {
        throw "Docker Compose not available"
    }
} catch {
    Write-Error "Docker Compose is not available"
    $validationResults.Issues += "Docker Compose is not available"
    $validationResults.ServiceChecks["docker-compose-cli"] = @{ Available = $false; Error = $_.Exception.Message }
}

# Generate recommendations
if ($validationResults.Issues.Count -eq 0 -and $validationResults.Warnings.Count -eq 0) {
    $validationResults.OverallStatus = "healthy"
    Write-Success "Configuration validation passed! Stack is ready for deployment."
} elseif ($validationResults.Issues.Count -eq 0) {
    $validationResults.OverallStatus = "warning"
    Write-Warning "Configuration validation passed with warnings."
} else {
    $validationResults.OverallStatus = "failed"
    Write-Error "Configuration validation failed with $($validationResults.Issues.Count) issues."
}

# Add recommendations
$validationResults.Recommendations = @(
    "Run 'docker compose -f docker-compose.yml up -d' to start the stack",
    "Monitor stack health with 'scripts/monitor-stack-health.ps1'",
    "Check logs with 'docker compose -f docker-compose.yml logs'",
    "Access SigNoz UI at http://localhost:8080"
)

# Generate report
if ($GenerateReport) {
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $validationResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Success "Validation report saved to: $OutputPath"
}

# Summary
Write-Info "=== Validation Summary ==="
Write-Info "Overall Status: $($validationResults.OverallStatus)"
Write-Info "Issues: $($validationResults.Issues.Count)"
Write-Info "Warnings: $($validationResults.Warnings.Count)"
Write-Info "Files Checked: $($validationResults.FileChecks.Count)"
Write-Info "Services Checked: $($validationResults.ServiceChecks.Count)"

if ($validationResults.OverallStatus -eq "healthy") {
    exit 0
} elseif ($validationResults.OverallStatus -eq "warning") {
    exit 1
} else {
    exit 2
}
