# GPUS Command Launcher
# Simple launcher for the GPUS command system

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Change to the OTel directory
Set-Location $PSScriptRoot\..

# Execute the GPUS command with all arguments
& "scripts\gpus.ps1" @Arguments
