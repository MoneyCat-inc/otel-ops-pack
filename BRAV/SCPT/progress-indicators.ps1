function Start-SpinnerJob {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [int]$UpdateIntervalMs = 150
    )
    $script:block = {
        param($Msg, $Interval)
        $chars = '|/-\\'
        $i = 0
        while ($true) {
            Write-Host ("`r$Msg " + $chars[$i % $chars.Length]) -NoNewline -ForegroundColor Gray
            Start-Sleep -Milliseconds $Interval
            $i++
        }
    }
    $job = Start-Job -ScriptBlock $script:block -ArgumentList $Message, $UpdateIntervalMs
    return $job
}

function Stop-SpinnerJob {
    param(
        [Parameter(Mandatory=$true)]$Job
    )
    try {
        if ($Job -and ($Job | Get-Job -ErrorAction SilentlyContinue)) {
            Stop-Job $Job -ErrorAction SilentlyContinue | Out-Null
            Receive-Job $Job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job $Job -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Host "`r$($null)" -NoNewline
    } catch {
        # no-op
    }
}

