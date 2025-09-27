# Enhanced codex-local Local Workflow Custodian

This document describes the enhanced version of the codex-local Local Workflow Custodian with progress indicators, estimated completion times, and improved user experience.

## 🚀 Enhanced Features

### Progress Indicators & Estimated Times
All wait operations now include:
- **Visual progress bars** with percentage completion
- **Estimated time remaining (ETA)** in seconds
- **Real-time status updates** during long-running operations
- **Graceful cancellation** support

### Enhanced Scripts

#### 1. **Enhanced Demo Script** (`demo-enhanced.ps1`)
**Usage**: `pnpm agent:demo-enhanced [-Fix] [-Detached]`

**Features**:
- Progress bars for all major operations (setup, doctor, guardrails)
- Estimated completion times for each phase
- Visual feedback during job execution
- Enhanced kill-switch testing with progress
- Comprehensive status reporting

**Progress Indicators**:
- Environment setup: ~30 seconds estimated
- Health diagnostics: ~45 seconds estimated  
- Guardrail scanning: ~20 seconds estimated
- Status monitoring: ~25 seconds estimated

#### 2. **Enhanced Watchdog** (`watchdog-enhanced.ps1`)
**Usage**: `pnpm agent:start-enhanced [-Detached] [-MaxCycles <n>] [-CycleIntervalSeconds <n>]`

**Features**:
- Cycle progress tracking with task-level indicators
- Real-time progress for health diagnostics
- Task processing progress with ETA
- Sleep countdown with visual progress
- Multi-level progress bars (cycle, task, operation)

**Progress Levels**:
- **Level 1**: Overall cycle progress
- **Level 2**: Sleep/wait countdown
- **Level 3**: Health diagnostics progress
- **Level 4**: Individual task execution progress

#### 3. **Status Checker with Progress** (`status-check.ps1`)
**Usage**: `pnpm agent:status [-Detailed]` or `pnpm agent:status-continuous`

**Features**:
- Progress bar during status file reading
- Continuous monitoring mode with 30-second intervals
- Visual status indicators (🟢✅❌🔒)
- Detailed section breakdown
- Real-time queue statistics

#### 4. **Hardened Guardrail Enforcement** (`enforce-guardrails-hardened.ps1`)
**Usage**: `pnpm agent:guardrails [-Fix]`

**Features**:
- Improved regex patterns for better detection
- Safe autofix capabilities (alt text, aria labels)
- JSON report generation (`.agent/guardrails_report.json`)
- Task logging integration
- Comprehensive violation categorization

## 📊 Progress Bar Types

### 1. **Setup Progress**
```
Environment Setup: Setting up local environment (ETA: 15.2s) ████████████████████ 85%
```

### 2. **Health Diagnostics Progress**
```
Health Diagnostics: Running health check (ETA: 8.7s) ████████████████████ 78%
```

### 3. **Guardrail Scan Progress**
```
Guardrail Enforcement: Scanning for violations (ETA: 5.3s) ████████████████████ 92%
```

### 4. **Watchdog Cycle Progress**
```
codex-local Watchdog: Cycle 3 (continuous) - Processing micro-tasks (1/2 tasks) ████████████████████ 50%
```

### 5. **Sleep Countdown**
```
codex-local Watchdog: Next cycle in 245.7s ████████████████████ 18%
```

## 🎯 Available Commands

### Core Commands
```powershell
# Enhanced demo with progress indicators
pnpm agent:demo-enhanced
pnpm agent:demo-enhanced -Fix -Detached

# Enhanced watchdog with progress
pnpm agent:start-enhanced
pnpm agent:start-enhanced -Detached

# Status checking with progress
pnpm agent:status
pnpm agent:status -Detailed
pnpm agent:status-continuous

# Hardened guardrail enforcement
pnpm agent:guardrails
pnpm agent:guardrails -Fix
```

### Traditional Commands (still available)
```powershell
# Original scripts (no progress bars)
pnpm setup-local
pnpm agent:doctor
pnpm agent:start
pnpm agent:demo
```

## 🔧 Technical Implementation

### Progress Bar Functions
```powershell
function Show-ProgressBar {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$Seconds,
        [int]$Id = 1
    )
    # Updates every 500ms with ETA calculation
}

function Show-SleepProgress {
    param(
        [int]$Seconds,
        [string]$Reason = "Waiting"
    )
    # Visual countdown with percentage
}
```

### Job Execution with Progress
```powershell
$job = Start-Job -ScriptBlock { /* long-running task */ }
while ($job.State -eq "Running") {
    # Calculate ETA and update progress
    $elapsed = (Get-Date) - $startTime
    $remaining = [Math]::Max(0, $estimated.TotalSeconds - $elapsed.TotalSeconds)
    Write-Progress -Activity $Activity -Status "Status (ETA: $remaining s)" -PercentComplete $percent
}
```

## 📈 Performance Characteristics

### Estimated Times
- **Setup**: 25-35 seconds (depending on dependencies)
- **Doctor**: 30-60 seconds (depending on file count)
- **Guardrails**: 15-30 seconds (depending on codebase size)
- **Status Check**: 2-5 seconds
- **Watchdog Cycle**: 10-120 seconds (depending on tasks)

### Progress Update Frequency
- **Fast operations**: 500ms intervals
- **Slow operations**: 1-2 second intervals
- **Sleep countdown**: 500ms intervals for smooth animation

## 🎨 Visual Indicators

### Status Icons
- 🟢 **Active**: Agent running normally
- 🔒 **Locked**: Agent paused by lock file
- ✅ **Success**: Operation completed successfully
- ❌ **Failed**: Operation failed or error detected
- ⚠️ **Warning**: Non-critical issue detected
- 📊 **Info**: Status information
- 📋 **Queue**: Task queue information

### Color Coding
- **Green**: Success, active, completed
- **Red**: Error, failed, critical
- **Yellow**: Warning, waiting, in-progress
- **Blue**: Information, running
- **Cyan**: Headers, separators
- **White**: General text, details
- **Gray**: Timestamps, metadata

## 🔄 Continuous Monitoring

### Real-time Status
```powershell
# Continuous monitoring with progress
pnpm agent:status-continuous
```

**Features**:
- 30-second update intervals
- Progress bars for each check
- Visual indicators for all status changes
- Graceful Ctrl+C handling

### Watchdog Monitoring
```powershell
# Enhanced watchdog with full progress tracking
pnpm agent:start-enhanced
```

**Features**:
- Cycle-level progress tracking
- Task-level progress indicators
- Sleep countdown with visual progress
- Multi-level progress bar system

## 🛡️ Error Handling

### Graceful Progress Cleanup
All scripts include proper cleanup of progress bars on:
- Normal completion
- Error conditions
- User interruption (Ctrl+C)
- Script termination

### Progress Bar IDs
- **ID 1**: Main operation progress
- **ID 2**: Sleep/wait countdown
- **ID 3**: Health diagnostics
- **ID 4**: Task processing
- **ID 5+**: Additional operations

## 🎯 Best Practices

### For Users
1. **Use enhanced scripts** for better experience
2. **Monitor progress** during long operations
3. **Check ETA** for time management
4. **Use continuous monitoring** for active development
5. **Leverage detailed status** for troubleshooting

### For Developers
1. **Always clean up progress bars** on exit
2. **Provide realistic time estimates**
3. **Use appropriate progress bar IDs**
4. **Include ETA calculations**
5. **Handle user interruption gracefully**

## 🚀 Quick Start

### 1. Enhanced Demo
```powershell
# Full demo with progress indicators
pnpm agent:demo-enhanced

# Demo with autofixes and detached watchdog
pnpm agent:demo-enhanced -Fix -Detached
```

### 2. Enhanced Watchdog
```powershell
# Start enhanced watchdog with progress
pnpm agent:start-enhanced

# Start in detached mode
pnpm agent:start-enhanced -Detached
```

### 3. Status Monitoring
```powershell
# Quick status check
pnpm agent:status

# Continuous monitoring
pnpm agent:status-continuous
```

### 4. Guardrail Enforcement
```powershell
# Scan and report violations
pnpm agent:guardrails

# Scan and apply safe fixes
pnpm agent:guardrails -Fix
```

The enhanced codex-local Local Workflow Custodian now provides a much better user experience with clear progress indicators, estimated completion times, and visual feedback for all operations.
