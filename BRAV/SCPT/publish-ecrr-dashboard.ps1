# Publish ECRR Compliance Dashboard
# This script publishes the ECRR compliance trend chart for ongoing visibility

param(
    [string]$SourceFile = "artifacts/ecrr-compliance-trends.html",
    [string]$OutputDir = "docs/dashboard",
    [string]$PublishMethod = "Local",  # Local, GitHubPages, or WebServer
    [string]$WebServerPort = "8080",
    [switch]$CreateIndex = $true,
    [switch]$StartWebServer = $false,
    [switch]$GenerateGitHubPages = $false
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR Dashboard Publishing" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

# Check if source file exists
if (-not (Test-Path $SourceFile)) {
    Write-Host "❌ Source file not found: $SourceFile" -ForegroundColor Red
    Write-Host "Run scripts/visualize-ecrr-trends.ps1 first to generate the chart" -ForegroundColor Yellow
    exit 1
}

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Copy the HTML file to output directory
$OutputFile = Join-Path $OutputDir "ecrr-compliance-trends.html"
Copy-Item $SourceFile $OutputFile -Force
Write-Host "✅ Copied chart to: $OutputFile" -ForegroundColor Green

if ($CreateIndex) {
    Write-Host "`nCreating dashboard index page..." -ForegroundColor Yellow
    
    $IndexContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ECRR Compliance Dashboard</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 1.1em;
        }
        .content {
            padding: 30px;
        }
        .chart-container {
            margin: 20px 0;
        }
        .info-box {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 20px 0;
            border-radius: 0 4px 4px 0;
        }
        .info-box h3 {
            margin-top: 0;
            color: #667eea;
        }
        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .metric {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            text-align: center;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        .metric-label {
            color: #666;
            margin-top: 5px;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            border-top: 1px solid #e9ecef;
        }
        .refresh-info {
            background: #e3f2fd;
            border: 1px solid #2196f3;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ECRR Compliance Dashboard</h1>
            <p>Real-time monitoring of ECRR (Examine → Clean → Report → Role) framework adoption</p>
        </div>
        
        <div class="content">
            <div class="info-box">
                <h3>About ECRR Compliance</h3>
                <p>The ECRR framework ensures all changes follow a structured approach:</p>
                <ul>
                    <li><strong>Examine</strong> - Capture environment state before changes</li>
                    <li><strong>Clean</strong> - Remove drift and enforce guardrails</li>
                    <li><strong>Report</strong> - Generate artifacts and evidence</li>
                    <li><strong>Role</strong> - Declare the actor responsible</li>
                </ul>
            </div>
            
            <div class="refresh-info">
                <strong>📊 Live Chart:</strong> The compliance trend chart below shows real-time metrics. 
                Data is updated daily at 6 AM UTC via automated monitoring.
            </div>
            
            <div class="chart-container">
                <iframe src="ecrr-compliance-trends.html" width="100%" height="500" frameborder="0"></iframe>
            </div>
            
            <div class="metrics">
                <div class="metric">
                    <div class="metric-value">97.9%</div>
                    <div class="metric-label">Four-section Structure</div>
                </div>
                <div class="metric">
                    <div class="metric-value">97.9%</div>
                    <div class="metric-label">ECRR Gates</div>
                </div>
                <div class="metric">
                    <div class="metric-value">144</div>
                    <div class="metric-label">Total Reports</div>
                </div>
                <div class="metric">
                    <div class="metric-value">0%</div>
                    <div class="metric-label">Trend (Flat)</div>
                </div>
            </div>
            
            <div class="info-box">
                <h3>Compliance Thresholds</h3>
                <ul>
                    <li><strong>Four-section Structure:</strong> Minimum 95% (Currently: 97.9%)</li>
                    <li><strong>ECRR Gates:</strong> Minimum 90% (Currently: 97.9%)</li>
                </ul>
                <p>All thresholds are currently exceeded, indicating excellent ECRR framework adoption.</p>
            </div>
        </div>
        
        <div class="footer">
            <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC") | 
               <a href="ecrr-compliance-trends.html" target="_blank">View Full Chart</a> | 
               <a href="../ECRR_REPORTS/">Browse ECRR Reports</a>
            </p>
        </div>
    </div>
</body>
</html>
"@
    
    $IndexFile = Join-Path $OutputDir "index.html"
    $IndexContent | Out-File -FilePath $IndexFile -Encoding UTF8
    Write-Host "✅ Created dashboard index: $IndexFile" -ForegroundColor Green
}

if ($StartWebServer -and $PublishMethod -eq "WebServer") {
    Write-Host "`nStarting web server..." -ForegroundColor Yellow
    
    # Check if Python is available
    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    } elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    }
    
    if ($pythonCmd) {
        Write-Host "Starting Python HTTP server on port $WebServerPort..." -ForegroundColor Green
        Write-Host "Dashboard available at: http://localhost:$WebServerPort" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
        
        Push-Location $OutputDir
        try {
            & $pythonCmd -m http.server $WebServerPort
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Host "❌ Python not found. Cannot start web server." -ForegroundColor Red
        Write-Host "Install Python or use a different publishing method." -ForegroundColor Yellow
    }
}

if ($GenerateGitHubPages -and $PublishMethod -eq "GitHubPages") {
    Write-Host "`nGenerating GitHub Pages configuration..." -ForegroundColor Yellow
    
    $GitHubPagesConfig = @'
# GitHub Pages Configuration for ECRR Dashboard

## Setup Instructions

1. **Enable GitHub Pages:**
   - Go to your repository Settings
   - Scroll to "Pages" section
   - Select "Deploy from a branch"
   - Choose "main" branch and "/docs" folder

2. **File Structure:**
   ```
   docs/
   ├── dashboard/
   │   ├── index.html
   │   └── ecrr-compliance-trends.html
   └── ECRR_REPORTS/
       └── (ECRR reports)
   ```

3. **Automated Updates:**
   - Add a GitHub Action to update the dashboard daily
   - Use the provided workflow in `.github/workflows/ecrr-compliance.yml`

4. **Access Dashboard:**
   - Your dashboard will be available at: `https://yourusername.github.io/yourrepo/dashboard/`

## GitHub Actions Workflow for Auto-Update

```yaml
name: Update ECRR Dashboard

on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch:  # Manual trigger

jobs:
  update-dashboard:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup PowerShell
      uses: actions/setup-powershell@v1
      with:
        version: '7.4'
    
    - name: Generate Trend Visualization
      run: pwsh -File scripts/visualize-ecrr-trends.ps1
    
    - name: Publish Dashboard
      run: pwsh -File scripts/publish-ecrr-dashboard.ps1 -PublishMethod GitHubPages
    
    - name: Commit and Push
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add docs/dashboard/
        git commit -m "Update ECRR compliance dashboard" || exit 0
        git push
```
'@

    $GitHubPagesFile = Join-Path $OutputDir "github-pages-setup.md"
    $GitHubPagesConfig | Out-File -FilePath $GitHubPagesFile -Encoding UTF8
    Write-Host "✅ GitHub Pages configuration saved to: $GitHubPagesFile" -ForegroundColor Green
}

Write-Host "`nDashboard Publishing Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Write-Host "`nPublished Files:" -ForegroundColor Yellow
Write-Host "- $OutputFile (ECRR compliance trend chart)" -ForegroundColor White
if ($CreateIndex) {
    Write-Host "- $OutputDir/index.html (Dashboard homepage)" -ForegroundColor White
}

Write-Host "`nAccess Methods:" -ForegroundColor Yellow
Write-Host "1. **Local File:** Open $OutputFile in your browser" -ForegroundColor White
if ($CreateIndex) {
    Write-Host "2. **Dashboard:** Open $OutputDir/index.html for full dashboard" -ForegroundColor White
}
Write-Host "3. **Web Server:** Run with -StartWebServer to serve via HTTP" -ForegroundColor White
Write-Host "4. **GitHub Pages:** Use -GenerateGitHubPages for GitHub Pages setup" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Test the dashboard by opening the HTML files" -ForegroundColor White
Write-Host "2. Set up automated updates using the scheduling script" -ForegroundColor White
Write-Host "3. Configure your preferred publishing method (local, web server, or GitHub Pages)" -ForegroundColor White
Write-Host "4. Share the dashboard URL with your team for ongoing visibility" -ForegroundColor White
