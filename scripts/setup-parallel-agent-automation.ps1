# Wrapper: canonical setup-parallel-agent-automation lives under BRAV/SCPT (fork resolution, ECRR 20260829 P1-7)
& "$PSScriptRoot\..\BRAV\SCPT\setup-parallel-agent-automation.ps1" @args
exit $LASTEXITCODE
