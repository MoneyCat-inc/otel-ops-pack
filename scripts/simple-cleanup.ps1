# Simple C: Drive Cleanup Script
Write-Host "Starting C: drive cleanup..."

# Check initial state
$initial = Get-PSDrive C
Write-Host "Initial: $([math]::Round($initial.Used/1GB,2)) GB used, $([math]::Round($initial.Free/1GB,2)) GB free"

# Remove duplicate Stable Diffusion models
$stableDiffPath = "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors"
$stableDiffFiles = Get-ChildItem $stableDiffPath -ErrorAction SilentlyContinue
if ($stableDiffFiles) {
    $size = ($stableDiffFiles | Measure-Object Length -Sum).Sum
    Write-Host "Removing $($stableDiffFiles.Count) duplicate Stable Diffusion models ($([math]::Round($size/1GB,2)) GB)..."
    $stableDiffFiles | Remove-Item -Force
    Write-Host "Removed duplicate Stable Diffusion models"
} else {
    Write-Host "No duplicate Stable Diffusion models found"
}

# Remove duplicate PyTorch library
$pytorchPath = "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\venv\Lib\site-packages\torch\lib\torch_cuda.dll"
if (Test-Path $pytorchPath) {
    $size = (Get-Item $pytorchPath).Length
    Write-Host "Removing duplicate PyTorch library ($([math]::Round($size/1GB,2)) GB)..."
    Remove-Item $pytorchPath -Force
    Write-Host "Removed duplicate PyTorch library"
} else {
    Write-Host "No duplicate PyTorch library found"
}

# Check final state
Start-Sleep -Seconds 2
$final = Get-PSDrive C
Write-Host "Final: $([math]::Round($final.Used/1GB,2)) GB used, $([math]::Round($final.Free/1GB,2)) GB free"
$recovered = [math]::Round($final.Free/1GB,2) - [math]::Round($initial.Free/1GB,2)
Write-Host "Space recovered: $recovered GB"

Write-Host "Cleanup complete!"
