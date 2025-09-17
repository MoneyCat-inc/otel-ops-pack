param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Find,[Parameter(Mandatory)][string]$Replace)
(Get-Content $Path -Raw).Replace($Find,$Replace) | Set-Content -Encoding utf8 $Path
Write-Host "Codemod applied to $Path"

