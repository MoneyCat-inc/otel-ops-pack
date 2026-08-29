# Wrapper: canonical integrate-boot-health lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\integrate-boot-health.ps1" @args
exit $LASTEXITCODE
