# Wrapper: canonical enterprise-readiness-check lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\enterprise-readiness-check.ps1" @args
exit $LASTEXITCODE
