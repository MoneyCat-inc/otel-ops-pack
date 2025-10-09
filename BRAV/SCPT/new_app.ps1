# Create a new application under ALFA/APPS/
param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$base = "ALFA\APPS\$Name"

Write-Host "Creating new app: $base/" -ForegroundColor Cyan

# Create directory structure
New-Item -ItemType Directory -Force -Path "$base\src", "$base\config", "$base\scripts" | Out-Null

# README
@"
# $Name

**Location:** ``ALFA/APPS/$Name``  
**Type:** Application

## Purpose
<Describe what this application does>

## Build
``````bash
# Add build commands
npm install
npm run build
``````

## Run
``````bash
# Add run commands
npm run dev
``````

## Configuration
See ``config/`` for environment-specific settings.

## Scripts
See ``scripts/`` for operational scripts.
"@ | Set-Content "$base\README.md" -Encoding UTF8

# package.json
@"
{
  "name": "$Name",
  "version": "0.1.0",
  "private": true,
  "description": "Application: $Name",
  "main": "src/index.js",
  "scripts": {
    "dev": "node src/index.js",
    "build": "echo 'Add build command'",
    "test": "echo 'Add test command'"
  }
}
"@ | Set-Content "$base\package.json" -Encoding UTF8

# index.js
@"
// $Name entry point
console.log('$Name starting...');
"@ | Set-Content "$base\src\index.js" -Encoding UTF8

Write-Host "✅ Created new app: $base/" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update $base/README.md with actual details"
Write-Host "  2. Add dependencies to $base/package.json"
Write-Host "  3. Implement functionality in $base/src/"
Write-Host "  4. Add to CODEOWNERS if needed"

