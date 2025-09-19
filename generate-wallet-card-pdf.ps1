# Generate Printable PDF Wallet Card
# Creates a beautiful, printable PDF wallet card for on-call engineers

Write-Host "Generating printable PDF wallet card..." -ForegroundColor Green

# Check if we have the required tools
$requiredTools = @('wkhtmltopdf', 'qrencode')
$missingTools = @()

foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "Missing required tools: $($missingTools -join ', ')" -ForegroundColor Yellow
    Write-Host "Installing via winget..." -ForegroundColor Yellow
    
    foreach ($tool in $missingTools) {
        if ($tool -eq 'wkhtmltopdf') {
            winget install --id wkhtmltopdf.wkhtmltopdf -e
        } elseif ($tool -eq 'qrencode') {
            winget install --id qrencode.qrencode -e
        }
    }
}

# Create HTML version of wallet card
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>OTEL OPS WALLET CARD</title>
    <style>
        @page { 
            size: A4; 
            margin: 0.5in;
            @top-center { content: "OTEL OPS WALLET CARD v1.1.0"; }
        }
        body { 
            font-family: 'Courier New', monospace; 
            font-size: 10px; 
            line-height: 1.2;
            margin: 0;
            padding: 0;
        }
        .header { 
            background: #2c3e50; 
            color: white; 
            padding: 10px; 
            text-align: center; 
            font-weight: bold;
            font-size: 14px;
        }
        .section { 
            margin: 15px 0; 
            border: 1px solid #ddd; 
            padding: 10px;
        }
        .section h3 { 
            background: #3498db; 
            color: white; 
            margin: -10px -10px 10px -10px; 
            padding: 5px 10px; 
            font-size: 12px;
        }
        .code { 
            background: #f8f9fa; 
            border: 1px solid #e9ecef; 
            padding: 8px; 
            font-family: 'Courier New', monospace; 
            font-size: 9px;
            white-space: pre-wrap;
            overflow-x: auto;
        }
        .emergency { 
            background: #e74c3c; 
            color: white; 
            padding: 10px; 
            border-radius: 5px;
            font-weight: bold;
        }
        .good { 
            background: #27ae60; 
            color: white; 
            padding: 8px; 
            border-radius: 3px;
        }
        .checklist { 
            background: #f39c12; 
            color: white; 
            padding: 8px; 
            border-radius: 3px;
        }
        .footer { 
            text-align: center; 
            font-size: 8px; 
            color: #7f8c8d; 
            margin-top: 20px;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }
        .qr-placeholder {
            width: 100px;
            height: 100px;
            border: 2px dashed #ccc;
            display: inline-block;
            text-align: center;
            line-height: 100px;
            margin: 5px;
        }
    </style>
</head>
<body>
    <div class="header">
        🚨 OTEL OPS WALLET CARD - PRINTABLE<br>
        Version: v1.1.0 | Emergency: See ON_CALL_RUNBOOK.md
    </div>

    <div class="section">
        <h3>⚡ DAILY OPS (60 seconds)</h3>
        <div class="code"># Service status, path, health, metrics
Get-Service otelcol-contrib | Select-Object Status, Name
Get-WmiObject -Class Win32_Service -Filter "Name='otelcol-contrib'" | Select-Object PathName
.\green-sheet.ps1

# Canary check (expect delta +1)
.\canary-check-min.ps1</div>
    </div>

    <div class="section">
        <h3>🔧 SAFE CHANGES</h3>
        <div class="code"># Create candidate, edit, apply safely
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# Edit candidate config
.\safe-apply-config.ps1
.\make-audit-pack.ps1</div>
    </div>

    <div class="section">
        <h3>🚨 EMERGENCY PROCEDURES</h3>
        <div class="emergency">
            <strong>Service looks up but ingest flat:</strong><br>
            Restart-Service otelcol-contrib<br>
            .\canary-check-min.ps1
        </div>
        <div class="emergency">
            <strong>Bad config deploy (fast rollback):</strong><br>
            Copy-Item C:\otel\config.bak.*.yaml C:\otel\config.yaml -Force<br>
            Restart-Service otelcol-contrib<br>
            .\canary-check-min.ps1
        </div>
        <div class="code"># Prove SCM recovery (Admin)
.\auto-restart-verify.ps1

# Deep evidence for incident
.\make-audit-pack.ps1</div>
    </div>

    <div class="section">
        <h3>🧪 RESILIENCE TESTING</h3>
        <div class="code"># Quarterly drill (during window)
.\chaos-drill.ps1 -OutageSeconds 90
Get-Content C:\otel\logs\chaos-drill.last.txt -Tail 200</div>
    </div>

    <div class="section">
        <h3>📊 WHAT "GOOD" LOOKS LIKE</h3>
        <div class="good">
            • Green-sheet: Running, config path includes --config C:\otel\config.yaml, health 200, metrics present<br>
            • Canary: Near-instant, always delta +1<br>
            • Auto-restart: Fires on real failures, logged by SCM<br>
            • Changes: Only via safe-apply-config.ps1; each CAB has audit-pack_*.zip + SHA256
        </div>
    </div>

    <div class="section">
        <h3>🔒 SERVICE RECOVERY POLICY</h3>
        <div class="code">sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1</div>
    </div>

    <div class="section">
        <h3>📋 CAB RECORD CHECKLIST</h3>
        <div class="checklist">
            ☐ audit-pack_YYYYMMDD_HHMMSS.zip + matching .sha256.txt<br>
            ☐ Release tag or commit ID (e.g., git rev-parse HEAD)<br>
            ☐ Screenshot of sc qfailure output<br>
            ☐ Service PathName verification<br>
            ☐ Canary delta output confirmation (canary-check-min.ps1)
        </div>
    </div>

    <div class="section">
        <h3>🔄 MAINTENANCE SCHEDULE</h3>
        <div class="code">• Weekly: setup-weekly-audit.ps1 → automated evidence trail (hands-off)<br>
• Monthly: repo-clean-inventory.ps1 (dry-run) → confirm no drift<br>
• Quarterly: chaos-drill.ps1 (maintenance window) → verify resilience<br>
• CI/CD: post-deploy-smoke.ps1 → pipeline gate validation</div>
    </div>

    <div class="section">
        <h3>🆘 ESCALATION PATHS</h3>
        <div class="code">• L1: Check service status, run canary, restart if needed<br>
• L2: Verify config, check logs, run chaos drill<br>
• L3: Deep dive with audit pack, check SCM recovery<br>
• L4: Escalate to platform team with full evidence</div>
    </div>

    <div class="section">
        <h3>📞 QUICK REFERENCE</h3>
        <div class="code">• Service: otelcol-contrib<br>
• Config: C:\otel\config.yaml<br>
• Logs: C:\otel\logs\<br>
• Audit: C:\otel\audit\<br>
• Health: http://127.0.0.1:13134/healthz<br>
• Metrics: http://127.0.0.1:8889/metrics</div>
    </div>

    <div class="section">
        <h3>🔗 QR CODES & LINKS</h3>
        <div class="qr-placeholder">QR: Full Docs</div>
        <div class="qr-placeholder">QR: Rollout</div>
        <div class="qr-placeholder">QR: Runbook</div>
        <div class="qr-placeholder">QR: Handoff</div>
    </div>

    <div class="footer">
        🏁 This is the way. | v1.1.0 | PS 5.1+ | Windows 10/11+<br>
        Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    </div>
</body>
</html>
"@

# Save HTML file
$htmlFile = "C:\otel\wallet-card.html"
$htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8

# Generate PDF using wkhtmltopdf
$pdfFile = "C:\otel\OTEL_OPS_WALLET_CARD_v1.1.0.pdf"
try {
    & wkhtmltopdf --page-size A4 --margin-top 0.5in --margin-bottom 0.5in --margin-left 0.5in --margin-right 0.5in $htmlFile $pdfFile
    
    if (Test-Path $pdfFile) {
        Write-Host "✅ PDF wallet card generated successfully: $pdfFile" -ForegroundColor Green
        Write-Host "   File size: $((Get-Item $pdfFile).Length / 1KB) KB" -ForegroundColor Cyan
        Write-Host "   Ready for printing and laminating!" -ForegroundColor Yellow
    } else {
        Write-Host "❌ PDF generation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error generating PDF: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   HTML file saved at: $htmlFile" -ForegroundColor Yellow
    Write-Host "   You can open this in a browser and print to PDF manually" -ForegroundColor Yellow
}

# Clean up HTML file
Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue

Write-Host "`nWallet card generation complete!" -ForegroundColor Green
