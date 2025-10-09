#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker is required to run mikefarah/yq.'
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
Push-Location -LiteralPath $root
try {
    $files = Get-ChildItem -Path $root -Recurse -Include *.yml, *.yaml -File |
        Where-Object { $_.FullName -notmatch 'node_modules|third_party|artifacts|\.next|dist' }

    if (-not $files) {
        Write-Host 'No YAML files detected.'
        return
    }

    $count = 0
    $total = $files.Count
    Write-Host "Found $total YAML files to format..."
    
    foreach ($file in $files) {
        $hostDir = $file.DirectoryName
        $fileName = $file.Name
        try {
            Write-Host "Formatting $($file.Name)..." -NoNewline
            $result = docker run --rm -v "${hostDir}:/workspace" -w /workspace mikefarah/yq -P -i "${fileName}" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓"
                $count++
            } else {
                Write-Host " ✗"
                Write-Warning "Failed to format $($file.FullName): $result"
            }
        }
        catch {
            Write-Host " ✗"
            Write-Warning "Failed to format $($file.FullName): $($_.Exception.Message)"
        }
    }

    Write-Host "Formatted $count YAML files."
}
finally {
    Pop-Location
}
