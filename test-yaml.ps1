# Test YAML validation
Write-Host "Testing YAML validation..."

try {
    $result = python -c "import yaml; yaml.safe_load(open('config.yaml', 'r')); print('SUCCESS')" 2>&1
    if ($result -eq "SUCCESS") {
        Write-Host "YAML syntax validation: PASSED" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "YAML syntax validation: FAILED" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} catch {
    Write-Host "YAML syntax validation: FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
