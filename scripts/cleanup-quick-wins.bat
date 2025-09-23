@echo off
echo Starting C: drive quick-win cleanup...

echo.
echo Checking initial drive state...
powershell -Command "Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}"

echo.
echo Removing duplicate Stable Diffusion models...
powershell -Command "if (Test-Path 'C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors') { $files = Get-ChildItem 'C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors'; $size = ($files | Measure-Object Length -Sum).Sum; Write-Host 'Removing' $files.Count 'files (' ([math]::Round($size/1GB,2)) 'GB)...'; $files | Remove-Item -Force; Write-Host 'Removed duplicate Stable Diffusion models' } else { Write-Host 'No duplicate Stable Diffusion models found' }"

echo.
echo Removing duplicate PyTorch library...
powershell -Command "if (Test-Path 'C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\venv\Lib\site-packages\torch\lib\torch_cuda.dll') { $size = (Get-Item 'C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\venv\Lib\site-packages\torch\lib\torch_cuda.dll').Length; Write-Host 'Removing duplicate PyTorch library (' ([math]::Round($size/1GB,2)) 'GB)...'; Remove-Item 'C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\venv\Lib\site-packages\torch\lib\torch_cuda.dll' -Force; Write-Host 'Removed duplicate PyTorch library' } else { Write-Host 'No duplicate PyTorch library found' }"

echo.
echo Checking final drive state...
powershell -Command "Start-Sleep -Seconds 2; Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}"

echo.
echo Quick-win cleanup complete!
pause
