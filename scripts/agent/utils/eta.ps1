# utils/eta.ps1 - Exponentially Weighted Moving Average for stable ETAs
param(
    [double]$ObservedSecs,
    [double]$PrevEmaSecs = 0,
    [double]$Alpha = 0.2
)

if ($PrevEmaSecs -le 0) { 
    return [math]::Max(1, $ObservedSecs) 
}

return ($Alpha * $ObservedSecs) + ((1 - $Alpha) * $PrevEmaSecs)
