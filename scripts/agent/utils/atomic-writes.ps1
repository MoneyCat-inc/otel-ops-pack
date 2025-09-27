# scripts/agent/utils/atomic-writes.ps1 - Atomic file operations to prevent truncation

function Write-AtomicJson {
    param(
        [string]$Path,
        [object]$Data,
        [string]$Encoding = "UTF8"
    )
    
    try {
        # Create temporary file path
        $tempPath = "$Path.tmp"
        $tempPath = [System.IO.Path]::GetTempFileName()
        
        # Convert to JSON and write to temp file
        $json = $Data | ConvertTo-Json -Depth 10 -Compress
        Set-Content -Path $tempPath -Value $json -Encoding $Encoding -NoNewline
        
        # Atomic move
        Move-Item -Path $tempPath -Destination $Path -Force
        
        return $true
    } catch {
        # Cleanup temp file on error
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
        Write-Error "Failed to write atomic JSON to $Path: $($_.Exception.Message)"
        return $false
    }
}

function Write-AtomicContent {
    param(
        [string]$Path,
        [string]$Content,
        [string]$Encoding = "UTF8"
    )
    
    try {
        # Create temporary file path
        $tempPath = "$Path.tmp"
        $tempPath = [System.IO.Path]::GetTempFileName()
        
        # Write content to temp file
        Set-Content -Path $tempPath -Value $Content -Encoding $Encoding -NoNewline
        
        # Atomic move
        Move-Item -Path $tempPath -Destination $Path -Force
        
        return $true
    } catch {
        # Cleanup temp file on error
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
        Write-Error "Failed to write atomic content to $Path: $($_.Exception.Message)"
        return $false
    }
}

function Read-AtomicJson {
    param(
        [string]$Path,
        [object]$Default = @{}
    )
    
    try {
        if (-not (Test-Path $Path)) {
            return $Default
        }
        
        $content = Get-Content $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) {
            return $Default
        }
        
        return $content | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to read JSON from $Path: $($_.Exception.Message)"
        return $Default
    }
}

function Backup-Atomic {
    param(
        [string]$Path,
        [string]$Suffix = ""
    )
    
    try {
        if (-not (Test-Path $Path)) {
            return $false
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = if ($Suffix) { "$Path.$Suffix.$timestamp" } else { "$Path.backup.$timestamp" }
        
        Copy-Item $Path $backupPath -Force
        return $true
    } catch {
        Write-Warning "Failed to create backup of $Path: $($_.Exception.Message)"
        return $false
    }
}
