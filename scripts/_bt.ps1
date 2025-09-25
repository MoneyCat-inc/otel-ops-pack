function Build-TaskContent {
    param(
        [string]$Title,
        [string[]]$ActionableItems
    )

    $lines = @()
    $lines += "# Task: $Title"
    $lines += "- Complete all actions listed under Next Actions."
    $lines += "- Run the verification commands without errors."
    $lines += '- Store supporting logs under artifacts/ or jobs/ as required.'
    return ($lines -join "`n")
}
