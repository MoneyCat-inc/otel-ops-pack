# Wrapper: canonical deploy-production lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\deploy-production.ps1" @args
exit $LASTEXITCODE
