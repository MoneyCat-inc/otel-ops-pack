param([Parameter(Mandatory)]$Json)
$path = ".\.agent\state\queue.jsonl"
$Json | Out-File -Append -Encoding utf8 $path
Write-Host "Queued → $($Json.Substring(0,[Math]::Min(120,$Json.Length)))..."

