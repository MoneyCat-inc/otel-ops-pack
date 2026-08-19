# Shared repo-root resolver for Pester tests under ALFA/TEST.
# This file lives at ALFA/TEST/helpers → three levels up is the repo root.
function Get-OtelRepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}
