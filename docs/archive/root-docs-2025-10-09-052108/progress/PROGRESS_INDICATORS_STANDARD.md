# Progress Indicators Standard - Project Wide Implementation

## Overview
This document establishes the standard for implementing progress indicators across all project scripts and operations that involve wait steps or long-running processes.

## Standard Requirements

### 1. **Progress Bars**
- **Format**: `[=============---------] 45% - Activity - Status (ETA: 2s) |`
- **Components**:
  - Visual bar with `=` (filled) and `-` (empty)
  - Percentage completion
  - Activity name
  - Current status
  - Estimated time remaining (ETA)
  - Optional spinner character

### 2. **Spinners**
- **Characters**: `|`, `/`, `-`, `\` (rotating sequence)
- **Usage**: For operations without clear progress metrics
- **Format**: `| Operation in progress...`
- **Update Interval**: 100-150ms

### 3. **Time Estimates**
- **Calculation**: Based on current progress and elapsed time
- **Display**: `(ETA: Xs)` or `(ETA: Xm Xs)` for longer operations
- **Accuracy**: Update estimates based on actual performance

### 4. **ASCII-Safe Symbols**
- **Progress bars**: `=`, `-`
- **Status indicators**: `[START]`, `[DONE]`, `[OK]`, `[FAIL]`, `[WARN]`
- **No Unicode**: Use only standard ASCII characters for terminal compatibility

## Implementation Guidelines

### 1. **When to Use Progress Indicators**
- **File operations**: Scanning, copying, moving, deleting
- **Network operations**: Downloads, uploads, API calls
- **Database operations**: Queries, migrations, backups
- **Build processes**: Compilation, testing, packaging
- **Any operation > 2 seconds**: Always show progress

### 2. **Progress Bar Implementation**
```powershell
function Write-ProgressBar {
    param(
        [int]$Percent,
        [string]$Activity,
        [string]$Status,
        [int]$SecondsRemaining = 0,
        [switch]$ShowSpinner = $false
    )
    
    $barLength = 30
    $filledLength = [math]::Floor($barLength * $Percent / 100)
    $bar = "=" * $filledLength + "-" * ($barLength - $filledLength)
    
    $timeStr = if ($SecondsRemaining -gt 0) { " (ETA: ${SecondsRemaining}s)" } else { "" }
    $spinner = if ($ShowSpinner) { " $($global:spinnerChars[$global:spinnerIndex])" } else { "" }
    
    Write-Host "`r[$bar] $Percent% - $Activity - $Status$timeStr$spinner" -NoNewline -ForegroundColor Cyan
}
```

### 3. **Spinner Implementation**
```powershell
$global:spinnerChars = @('|', '/', '-', '\')
$global:spinnerIndex = 0

function Start-SpinnerJob {
    param(
        [string]$Message,
        [int]$UpdateIntervalMs = 100
    )
    
    $job = Start-Job -ScriptBlock {
        param($Message, $UpdateIntervalMs)
        $spinnerChars = @('|', '/', '-', '\')
        $index = 0
        while ($true) {
            $index = ($index + 1) % $spinnerChars.Length
            $spinner = $spinnerChars[$index]
            Write-Host "`r$spinner $Message" -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds $UpdateIntervalMs
        }
    } -ArgumentList $Message, $UpdateIntervalMs
    
    return $job
}
```

### 4. **Timed Operations Wrapper**
```powershell
function Start-TimedOperation {
    param(
        [string]$Operation,
        [scriptblock]$ScriptBlock,
        [int]$EstimatedSeconds = 5,
        [switch]$ShowSpinner = $false
    )
    
    $startTime = Get-Date
    Write-Host "`n[START] $Operation" -ForegroundColor Yellow
    Write-Host "Estimated time: $EstimatedSeconds seconds" -ForegroundColor Gray
    
    # Start spinner if requested
    $spinnerJob = $null
    if ($ShowSpinner) {
        $spinnerJob = Start-SpinnerJob -Message "$Operation in progress..." -UpdateIntervalMs 150
    }
    
    try {
        $result = & $ScriptBlock
        $endTime = Get-Date
        $actualSeconds = ($endTime - $startTime).TotalSeconds
        
        # Stop spinner
        Stop-SpinnerJob -Job $spinnerJob
        
        Write-Host "`n[DONE] $Operation" -ForegroundColor Green
        Write-Host "Actual time: $([math]::Round($actualSeconds, 1)) seconds" -ForegroundColor Gray
        
        return $result
    }
    catch {
        # Stop spinner on error
        Stop-SpinnerJob -Job $spinnerJob
        Write-Host "`n[FAIL] $Operation" -ForegroundColor Red
        throw
    }
}
```

## Project-Wide Implementation Plan

### 1. **Scripts to Update**
- [ ] `cleanup-simple.ps1` ✅ (Already implemented)
- [ ] `monitor-optimized-pipeline.ps1`
- [ ] `quick-monitor.ps1`
- [ ] `canary-test.ps1`
- [ ] `verify-pipeline.ps1`
- [ ] `health-check.ps1`
- [ ] `restart-collector.ps1`
- [ ] `test-config.ps1`
- [ ] `validate-pipeline.ps1`
- [ ] All other scripts with wait steps

### 2. **Implementation Priority**
1. **High Priority**: Monitoring and health check scripts
2. **Medium Priority**: Test and validation scripts
3. **Low Priority**: Utility and maintenance scripts

### 3. **Common Patterns to Implement**

#### File Operations
```powershell
# Before
Get-ChildItem -Path . -Recurse | ForEach-Object { ... }

# After
$files = Get-ChildItem -Path . -Recurse
for ($i = 0; $i -lt $files.Count; $i++) {
    $percent = [math]::Floor(($i / $files.Count) * 100)
    $remaining = [math]::Max(0, $estimatedTime - (($i / $files.Count) * $estimatedTime))
    Write-ProgressBar -Percent $percent -Activity "Processing" -Status "File $i/$($files.Count)" -SecondsRemaining $remaining -ShowSpinner
    # Process file
}
```

#### Network Operations
```powershell
# Before
Invoke-RestMethod -Uri $url

# After
$spinnerJob = Start-SpinnerJob -Message "Downloading from $url..." -UpdateIntervalMs 150
try {
    $result = Invoke-RestMethod -Uri $url
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "`n[OK] Download completed" -ForegroundColor Green
} catch {
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "`n[FAIL] Download failed" -ForegroundColor Red
    throw
}
```

#### Database Operations
```powershell
# Before
$query = "SELECT * FROM large_table"
$results = Invoke-Sqlcmd -Query $query

# After
$spinnerJob = Start-SpinnerJob -Message "Executing database query..." -UpdateIntervalMs 150
try {
    $results = Invoke-Sqlcmd -Query $query
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "`n[OK] Query completed: $($results.Count) rows" -ForegroundColor Green
} catch {
    Stop-SpinnerJob -Job $spinnerJob
    Write-Host "`n[FAIL] Query failed" -ForegroundColor Red
    throw
}
```

## Quality Assurance

### 1. **Testing Requirements**
- Test on different terminal types (PowerShell, CMD, VS Code terminal)
- Verify ASCII compatibility
- Test spinner cleanup on errors
- Validate ETA calculations

### 2. **Performance Considerations**
- Spinner update interval: 100-150ms (not too fast, not too slow)
- Progress bar updates: Every 1-5% or every N items
- Avoid excessive console output

### 3. **Error Handling**
- Always clean up spinners on errors
- Provide clear error messages
- Maintain progress state on failures

## Benefits

### 1. **User Experience**
- Clear feedback on long operations
- Prevents user confusion and early exits
- Professional appearance
- Better understanding of operation progress

### 2. **Operational Benefits**
- Reduced support tickets ("Is it working?")
- Better monitoring of script performance
- Easier debugging of slow operations
- Improved user confidence

### 3. **Technical Benefits**
- Consistent user interface across all scripts
- Terminal compatibility
- Easy to implement and maintain
- Reusable components

## Implementation Checklist

### For Each Script:
- [ ] Identify operations > 2 seconds
- [ ] Add progress bars for countable operations
- [ ] Add spinners for non-countable operations
- [ ] Implement time estimates
- [ ] Add error handling with spinner cleanup
- [ ] Test on different terminals
- [ ] Update documentation

### For Project:
- [ ] Create shared progress indicator functions
- [ ] Update all existing scripts
- [ ] Add to new script templates
- [ ] Train team on implementation
- [ ] Monitor user feedback

## Conclusion

Implementing progress indicators project-wide will significantly improve user experience, reduce support overhead, and provide a more professional appearance to all operations. This standard ensures consistency and quality across all project scripts.

**Next Steps**:
1. Implement shared progress indicator functions
2. Update high-priority scripts first
3. Gradually roll out to all scripts
4. Monitor and gather feedback
5. Refine and improve based on usage
