# Create a new shared library under ALFA/LIBS/
param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$base = "ALFA\LIBS\$Name"

Write-Host "Creating new library: $base/" -ForegroundColor Cyan

# Create directory structure
New-Item -ItemType Directory -Force -Path "$base\src" | Out-Null

# README
@"
# $Name

**Location:** ``ALFA/LIBS/$Name``  
**Type:** Shared Library

## Exports
<Describe what this library provides>

## Consumers
<List apps/libs that use this>

## Usage
``````typescript
import { something } from '@alfa/LIBS/$Name';
``````

## Development
``````bash
npm install
npm test
``````
"@ | Set-Content "$base\README.md" -Encoding UTF8

# package.json
@"
{
  "name": "@resonai/$Name",
  "version": "0.1.0",
  "description": "Shared library: $Name",
  "main": "src/index.js",
  "types": "src/index.d.ts",
  "scripts": {
    "test": "echo 'Add test command'"
  }
}
"@ | Set-Content "$base\package.json" -Encoding UTF8

# index.js
@"
// $Name library exports
export const example = () => {
  console.log('$Name library loaded');
};
"@ | Set-Content "$base\src\index.js" -Encoding UTF8

Write-Host "✅ Created new library: $base/" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update $base/README.md with actual exports"
Write-Host "  2. Implement library functionality in $base/src/"
Write-Host "  3. Add tests"
Write-Host "  4. Update TypeScript aliases if needed"

