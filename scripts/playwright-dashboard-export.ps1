# Playwright Dashboard Export Script
# Captures SigNoz UI screenshots and saves to docs/observability/snapshots/

param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$OutputDir = "docs/observability/snapshots",
  [switch]$Headless = $true
)

$ErrorActionPreference = 'Stop'

function New-DirIfMissing {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

# Ensure output directory exists
New-DirIfMissing $OutputDir

# Check if playwright is installed
$playwrightInstalled = $false
try {
  $npmList = npm list --depth=0 2>&1
  if ($npmList -match '@playwright/test') {
    $playwrightInstalled = $true
  }
} catch {}

if (-not $playwrightInstalled) {
  Write-Warning "Playwright not installed. Install with: pnpm install @playwright/test"
  Write-Warning "Skipping dashboard export."
  exit 0
}

# Create inline Playwright script
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$scriptPath = ".playwright-export-temp.mjs"

$playwrightScript = @"
import { chromium } from '@playwright/test';

async function captureScreenshots() {
  const browser = await chromium.launch({ headless: $($Headless.ToString().ToLower()) });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();

  try {
    const baseUrl = '$SigNozUrl';
    const outputDir = '$OutputDir';
    const timestamp = '$timestamp';

    // 1. Home dashboard
    console.log('Capturing home dashboard...');
    await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: `\${outputDir}/signoz-home-\${timestamp}.png`, fullPage: true });

    // 2. Logs view
    console.log('Capturing logs view...');
    await page.goto(`\${baseUrl}/logs`, { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: `\${outputDir}/signoz-logs-\${timestamp}.png`, fullPage: true });

    // 3. Traces view with iona.boot filter
    console.log('Capturing traces view (iona.boot filter)...');
    await page.goto(`\${baseUrl}/traces`, { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    
    // Try to apply filter (best-effort)
    try {
      const filterInput = await page.locator('input[placeholder*="Search"], input[type="search"]').first();
      if (await filterInput.isVisible({ timeout: 5000 })) {
        await filterInput.fill('iona.boot');
        await page.keyboard.press('Enter');
        await page.waitForTimeout(2000);
      }
    } catch (e) {
      console.log('Filter not applied (input not found), continuing...');
    }
    
    await page.screenshot({ path: `\${outputDir}/signoz-traces-iona-boot-\${timestamp}.png`, fullPage: true });

    // 4. Status page (if exists)
    console.log('Capturing status page...');
    try {
      await page.goto('file:///' + process.cwd().replace(/\\/g, '/') + '/docs/status.html', { waitUntil: 'load', timeout: 10000 });
      await page.waitForTimeout(1000);
      await page.screenshot({ path: `\${outputDir}/status-page-\${timestamp}.png`, fullPage: true });
    } catch (e) {
      console.log('Status page not captured (file not found or error):', e.message);
    }

    console.log(`✅ Screenshots saved to \${outputDir}/`);
  } catch (error) {
    console.error('Error during screenshot capture:', error.message);
    throw error;
  } finally {
    await browser.close();
  }
}

captureScreenshots().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
"@

try {
  # Write temporary script
  $playwrightScript | Set-Content -Path $scriptPath -Encoding UTF8
  
  # Execute with node
  Write-Host "Launching Playwright to capture SigNoz dashboards..." -ForegroundColor Cyan
  node $scriptPath
  
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dashboard export completed successfully" -ForegroundColor Green
  } else {
    Write-Warning "Playwright export failed with exit code: $LASTEXITCODE"
  }
} catch {
  Write-Warning "Error running Playwright: $_"
  Write-Warning "Continuing without screenshots (best-effort)"
} finally {
  # Cleanup temp script
  if (Test-Path $scriptPath) {
    Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
  }
}

