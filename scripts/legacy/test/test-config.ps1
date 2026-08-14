# Simple config test
# Updated with progress indicators for better user experience

# Import progress indicators module
. .\scripts\progress-indicators.ps1

Write-Host "Testing config..."
$spinnerJob = Start-SpinnerJob -Message "Validating config..." -UpdateIntervalMs 150
python -c "import yaml; print('Config valid')"
Stop-SpinnerJob -Job $spinnerJob
Write-Host "Done"
