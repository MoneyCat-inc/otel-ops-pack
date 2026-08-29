# Wrapper: canonical boot-health-check lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\boot-health-check.ps1" @args
exit $LASTEXITCODE
