# Wrapper: canonical update-status-dashboard lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\update-status-dashboard.ps1" @args
exit $LASTEXITCODE
