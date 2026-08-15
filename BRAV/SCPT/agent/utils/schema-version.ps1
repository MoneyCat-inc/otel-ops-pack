# scripts/agent/utils/schema-version.ps1 - Schema versioning and compatibility

$global:SCHEMA_VERSION = "codex-local.status.v1"

function New-StatusDocument {
    param(
        [hashtable]$Data = @{}
    )
    
    $document = @{
        schema = $global:SCHEMA_VERSION
        timestamp = (Get-Date).ToString("o")
        version = "1.0.0"
    }
    
    # Merge with provided data
    foreach ($key in $Data.Keys) {
        $document[$key] = $Data[$key]
    }
    
    return $document
}

function Test-SchemaCompatibility {
    param(
        [object]$Document,
        [string]$ExpectedVersion = $global:SCHEMA_VERSION
    )
    
    if (-not $Document.PSObject.Properties.Name -contains "schema") {
        return @{
            compatible = $false
            reason = "Missing schema field"
            version = "unknown"
        }
    }
    
    $documentVersion = $Document.schema
    
    if ($documentVersion -eq $ExpectedVersion) {
        return @{
            compatible = $true
            reason = "Exact match"
            version = $documentVersion
        }
    }
    
    # Check for major version compatibility
    $expectedMajor = ($ExpectedVersion -split '\.')[0..1] -join '.'
    $documentMajor = ($documentVersion -split '\.')[0..1] -join '.'
    
    if ($documentMajor -eq $expectedMajor) {
        return @{
            compatible = $true
            reason = "Major version compatible"
            version = $documentVersion
            warning = "Minor version mismatch: expected $ExpectedVersion, got $documentVersion"
        }
    }
    
    return @{
        compatible = $false
        reason = "Major version incompatible"
        version = $documentVersion
        expected = $ExpectedVersion
    }
}

function Convert-LegacySchema {
    param(
        [object]$Document,
        [string]$TargetVersion = $global:SCHEMA_VERSION
    )
    
    $compatibility = Test-SchemaCompatibility -Document $Document -ExpectedVersion $TargetVersion
    
    if ($compatibility.compatible) {
        return $Document
    }
    
    # Handle legacy schemas
    if (-not $Document.PSObject.Properties.Name -contains "schema") {
        # Legacy document without schema - assume v0
        Write-Warning "Converting legacy document without schema to $TargetVersion"
        
        $converted = @{
            schema = $TargetVersion
            timestamp = $Document.timestamp ?? (Get-Date).ToString("o")
            version = "1.0.0"
            state = $Document.state ?? "unknown"
            sections = $Document.sections ?? @{}
            queue = $Document.queue ?? @{}
            ema = $Document.ema ?? @{}
        }
        
        return $converted
    }
    
    # Handle other version mismatches
    Write-Warning "Schema conversion from $($Document.schema) to $TargetVersion not implemented"
    return $Document
}

function Write-SchemaVersionedJson {
    param(
        [string]$Path,
        [hashtable]$Data,
        [string]$Encoding = "UTF8"
    )
    
    try {
        # Create versioned document
        $document = New-StatusDocument -Data $Data
        
        # Write atomically
        return Write-AtomicJson -Path $Path -Data $document -Encoding $Encoding
    } catch {
        Write-Error "Failed to write schema-versioned JSON: $($_.Exception.Message)"
        return $false
    }
}

function Read-SchemaVersionedJson {
    param(
        [string]$Path,
        [hashtable]$Default = @{}
    )
    
    try {
        $document = Read-AtomicJson -Path $Path -Default $Default
        
        if ($document -eq $Default) {
            return $document
        }
        
        # Check compatibility and convert if needed
        $compatibility = Test-SchemaCompatibility -Document $document
        if (-not $compatibility.compatible) {
            $document = Convert-LegacySchema -Document $document
        }
        
        return $document
    } catch {
        Write-Warning "Failed to read schema-versioned JSON from ${Path}: $($_.Exception.Message)"
        return $Default
    }
}
