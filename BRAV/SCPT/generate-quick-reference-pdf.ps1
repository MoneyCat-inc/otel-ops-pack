# Generate PDF from Quick Reference HTML
# Requires: Chrome/Edge browser for PDF generation

param(
    [string]$OutputPath = "docs/cheatsheets/QUICK_REFERENCE.pdf"
)

Write-Host "🚀 Generating Quick Reference PDF..." -ForegroundColor Cyan

# Check if HTML file exists
$htmlPath = "docs/cheatsheets/QUICK_REFERENCE.html"
if (-not (Test-Path $htmlPath)) {
    Write-Error "HTML file not found: $htmlPath"
    exit 1
}

# Try different browsers for PDF generation
$browsers = @(
    @{ name = "Chrome"; path = "chrome.exe"; args = "--headless --disable-gpu --print-to-pdf" },
    @{ name = "Edge"; path = "msedge.exe"; args = "--headless --disable-gpu --print-to-pdf" },
    @{ name = "Chrome (Program Files)"; path = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"; args = "--headless --disable-gpu --print-to-pdf" },
    @{ name = "Edge (Program Files)"; path = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"; args = "--headless --disable-gpu --print-to-pdf" }
)

$browserFound = $false
foreach ($browser in $browsers) {
    if (Get-Command $browser.path -ErrorAction SilentlyContinue) {
        Write-Host "✅ Found $($browser.name)" -ForegroundColor Green
        
        # Generate PDF
        $htmlUri = "file:///$((Get-Item $htmlPath).FullName.Replace('\', '/'))"
        $pdfPath = (Get-Item $htmlPath).FullName.Replace('.html', '.pdf')
        
        $args = @(
            $browser.args.Split(' ')
            "--print-to-pdf=$pdfPath"
            "--no-margins"
            "--paper-format=A4"
            $htmlUri
        )
        
        try {
            Write-Host "📄 Generating PDF..." -ForegroundColor Yellow
            & $browser.path $args
            
            if (Test-Path $pdfPath) {
                Write-Host "✅ PDF generated successfully: $pdfPath" -ForegroundColor Green
                
                # Copy to output path if different
                if ($pdfPath -ne (Resolve-Path $OutputPath)) {
                    Copy-Item $pdfPath $OutputPath -Force
                    Write-Host "📋 PDF copied to: $OutputPath" -ForegroundColor Green
                }
                
                $browserFound = $true
                break
            }
        } catch {
            Write-Warning "Failed to generate PDF with $($browser.name): $($_.Exception.Message)"
        }
    }
}

if (-not $browserFound) {
    Write-Warning "No suitable browser found for PDF generation"
    Write-Host "💡 Manual steps:" -ForegroundColor Yellow
    Write-Host "1. Open docs/cheatsheets/QUICK_REFERENCE.html in your browser" -ForegroundColor White
    Write-Host "2. Press Ctrl+P (Print)" -ForegroundColor White
    Write-Host "3. Select 'Save as PDF'" -ForegroundColor White
    Write-Host "4. Set margins to 'None' and paper size to 'A4'" -ForegroundColor White
    Write-Host "5. Save as QUICK_REFERENCE.pdf" -ForegroundColor White
}

Write-Host "🎯 Quick Reference ready for printing/laminating!" -ForegroundColor Cyan
