# Wrapper: canonical verify-integration lives under BRAV/SCPT (fork resolution, ECRR 20260829 P2)
& "$PSScriptRoot\..\BRAV\SCPT\verify-integration.ps1" @args
exit $LASTEXITCODE
