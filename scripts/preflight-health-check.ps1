# Wrapper: canonical preflight lives under BRAV/SCPT
& "$PSScriptRoot\..\BRAV\SCPT\preflight-health-check.ps1" @args
exit $LASTEXITCODE
