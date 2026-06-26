param([switch]$DryRun = $true, [string]$EcrrDir = "CHAR/ECRR/ECRR_REPORTS")
pwsh -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot/enforce-four-section-structure.ps1" -DryRun:$DryRun -EcrrDir $EcrrDir

