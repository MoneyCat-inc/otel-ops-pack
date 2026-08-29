# Wrapper: canonical playwright-dashboard-export lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\playwright-dashboard-export.ps1" @args
exit $LASTEXITCODE
