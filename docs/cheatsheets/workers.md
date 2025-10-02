# Background Worker Cheat Sheet

**Issue**: Background agents fail to start or exceed resource budgets  
**Solution**: Config budgets, kill switch, and bootstrap diagnostics

## 🚨 **Critical Budgets**

### **Resource Limits**
```typescript
interface WorkerConfig {
  maxJobsPerPass: number      // ≤ 2 jobs per pass
  maxFilesPerJob: number      // ≤ 10 files per job
  maxLinesPerJob: number      // ≤ 200 LOC per job
  maxMemoryMB: number         // ≤ 100 MB memory
  maxExecutionTimeMs: number  // ≤ 30 seconds per job
}

const DEFAULT_CONFIG: WorkerConfig = {
  maxJobsPerPass: 2,
  maxFilesPerJob: 10,
  maxLinesPerJob: 200,
  maxMemoryMB: 100,
  maxExecutionTimeMs: 30000
}
```

### **Budget Enforcement**
```typescript
class BudgetEnforcer {
  private config: WorkerConfig
  private currentPass: JobPass
  
  constructor(config: WorkerConfig = DEFAULT_CONFIG) {
    this.config = config
    this.currentPass = new JobPass()
  }
  
  canStartJob(job: Job): boolean {
    // Check pass-level limits
    if (this.currentPass.jobs.length >= this.config.maxJobsPerPass) {
      return false
    }
    
    // Check job-level limits
    if (job.files.length > this.config.maxFilesPerJob) {
      return false
    }
    
    if (job.estimatedLines > this.config.maxLinesPerJob) {
      return false
    }
    
    // Check memory usage
    const memoryUsage = this.getMemoryUsage()
    if (memoryUsage > this.config.maxMemoryMB) {
      return false
    }
    
    return true
  }
  
  startJob(job: Job): JobExecution {
    if (!this.canStartJob(job)) {
      throw new Error('Job exceeds budget limits')
    }
    
    const execution = new JobExecution(job, this.config)
    this.currentPass.jobs.push(execution)
    
    return execution
  }
  
  private getMemoryUsage(): number {
    if (typeof performance !== 'undefined' && performance.memory) {
      return performance.memory.usedJSHeapSize / (1024 * 1024) // MB
    }
    return 0
  }
}
```

## 🔒 **Kill Switch Implementation**

### **Lock File System**
```typescript
class KillSwitch {
  private lockFilePath = '.agent/LOCK'
  private statusFilePath = '.agent/status.json'
  
  isLocked(): boolean {
    try {
      // Check if lock file exists
      const lockExists = this.fileExists(this.lockFilePath)
      
      if (lockExists) {
        this.updateStatus('paused:lock', 'Agent paused due to lock file')
        return true
      }
      
      return false
    } catch (error) {
      console.warn('Could not check lock status:', error)
      return false
    }
  }
  
  activateLock(reason: string = 'Manual lock activation'): void {
    try {
      this.writeFile(this.lockFilePath, JSON.stringify({
        timestamp: Date.now(),
        reason,
        pid: process.pid
      }))
      
      this.updateStatus('locked', reason)
      console.log('🔒 Kill switch activated:', reason)
    } catch (error) {
      console.error('Failed to activate lock:', error)
    }
  }
  
  deactivateLock(): void {
    try {
      this.deleteFile(this.lockFilePath)
      this.updateStatus('active', 'Lock removed, agent active')
      console.log('🔓 Kill switch deactivated')
    } catch (error) {
      console.error('Failed to deactivate lock:', error)
    }
  }
  
  private updateStatus(status: string, message: string): void {
    const statusData = {
      status,
      message,
      timestamp: Date.now(),
      pid: process.pid
    }
    
    this.writeFile(this.statusFilePath, JSON.stringify(statusData, null, 2))
  }
  
  private fileExists(path: string): boolean {
    // Implementation depends on environment (Node.js, Deno, etc.)
    try {
      Deno.statSync(path)
      return true
    } catch {
      return false
    }
  }
  
  private writeFile(path: string, content: string): void {
    Deno.writeTextFileSync(path, content)
  }
  
  private deleteFile(path: string): void {
    Deno.removeSync(path)
  }
}
```

## 🔧 **Bootstrap Diagnostics**

### **Agent Doctor**
```typescript
class AgentDoctor {
  private diagnostics: DiagnosticResult[] = []
  
  async runFullDiagnostics(): Promise<DiagnosticReport> {
    this.diagnostics = []
    
    // Check environment
    await this.checkEnvironment()
    
    // Check dependencies
    await this.checkDependencies()
    
    // Check permissions
    await this.checkPermissions()
    
    // Check resources
    await this.checkResources()
    
    // Check configuration
    await this.checkConfiguration()
    
    return this.generateReport()
  }
  
  private async checkEnvironment(): Promise<void> {
    const checks = [
      {
        name: 'Node.js Version',
        test: () => typeof process !== 'undefined' && process.version,
        required: '>= 18.0.0'
      },
      {
        name: 'Deno Available',
        test: () => typeof Deno !== 'undefined',
        required: true
      },
      {
        name: 'PowerShell Available',
        test: async () => {
          try {
            const result = await this.runCommand('pwsh --version')
            return result.includes('PowerShell')
          } catch {
            return false
          }
        },
        required: true
      }
    ]
    
    for (const check of checks) {
      const result = await this.runCheck(check)
      this.diagnostics.push(result)
    }
  }
  
  private async checkDependencies(): Promise<void> {
    const dependencies = [
      'pnpm',
      'git',
      'docker',
      'signoz'
    ]
    
    for (const dep of dependencies) {
      const result = await this.runCheck({
        name: `${dep} Available`,
        test: async () => {
          try {
            await this.runCommand(`${dep} --version`)
            return true
          } catch {
            return false
          }
        },
        required: true
      })
      
      this.diagnostics.push(result)
    }
  }
  
  private async checkPermissions(): Promise<void> {
    const permissions = [
      {
        name: 'File System Access',
        test: async () => {
          try {
            await Deno.readDir('.')
            return true
          } catch {
            return false
          }
        }
      },
      {
        name: 'Network Access',
        test: async () => {
          try {
            const response = await fetch('http://localhost:8080/api/v1/health')
            return response.ok
          } catch {
            return false
          }
        }
      }
    ]
    
    for (const perm of permissions) {
      const result = await this.runCheck(perm)
      this.diagnostics.push(result)
    }
  }
  
  private async runCheck(check: DiagnosticCheck): Promise<DiagnosticResult> {
    try {
      const startTime = Date.now()
      const passed = await check.test()
      const duration = Date.now() - startTime
      
      return {
        name: check.name,
        passed,
        duration,
        message: passed ? 'OK' : `Failed: ${check.required || 'Required'}`,
        required: check.required
      }
    } catch (error) {
      return {
        name: check.name,
        passed: false,
        duration: 0,
        message: `Error: ${error.message}`,
        required: check.required
      }
    }
  }
  
  private async runCommand(command: string): Promise<string> {
    const process = Deno.run({
      cmd: command.split(' '),
      stdout: 'piped',
      stderr: 'piped'
    })
    
    const output = await process.output()
    const error = await process.stderrOutput()
    
    if (error.length > 0) {
      throw new Error(new TextDecoder().decode(error))
    }
    
    return new TextDecoder().decode(output)
  }
}
```

## 🚀 **Worker Implementation**

### **Complete Background Worker**
```typescript
class BackgroundWorker {
  private config: WorkerConfig
  private killSwitch: KillSwitch
  private budgetEnforcer: BudgetEnforcer
  private doctor: AgentDoctor
  private isRunning = false
  
  constructor(config: WorkerConfig = DEFAULT_CONFIG) {
    this.config = config
    this.killSwitch = new KillSwitch()
    this.budgetEnforcer = new BudgetEnforcer(config)
    this.doctor = new AgentDoctor()
  }
  
  async start(): Promise<void> {
    if (this.isRunning) {
      console.log('Worker already running')
      return
    }
    
    // Check kill switch first
    if (this.killSwitch.isLocked()) {
      console.log('🔒 Worker paused due to lock file')
      return
    }
    
    // Run diagnostics if needed
    const diagnostics = await this.doctor.runFullDiagnostics()
    if (!diagnostics.allPassed) {
      console.error('❌ Diagnostics failed:', diagnostics.failures)
      throw new Error('Prerequisites not met')
    }
    
    this.isRunning = true
    console.log('🚀 Background worker started')
    
    // Start main loop
    this.mainLoop()
  }
  
  private async mainLoop(): Promise<void> {
    while (this.isRunning) {
      try {
        // Check kill switch on each iteration
        if (this.killSwitch.isLocked()) {
          console.log('🔒 Worker paused due to lock file')
          this.isRunning = false
          break
        }
        
        // Process jobs
        await this.processJobs()
        
        // Wait before next iteration
        await this.sleep(5000) // 5 seconds
        
      } catch (error) {
        console.error('Worker error:', error)
        await this.sleep(10000) // Wait longer on error
      }
    }
  }
  
  private async processJobs(): Promise<void> {
    const jobs = await this.getPendingJobs()
    
    for (const job of jobs) {
      if (!this.budgetEnforcer.canStartJob(job)) {
        console.log('⏸️ Job exceeds budget, skipping:', job.id)
        continue
      }
      
      try {
        const execution = this.budgetEnforcer.startJob(job)
        await execution.run()
        console.log('✅ Job completed:', job.id)
      } catch (error) {
        console.error('❌ Job failed:', job.id, error)
      }
    }
  }
  
  private async getPendingJobs(): Promise<Job[]> {
    // Implementation depends on job queue system
    // This is a placeholder
    return []
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
  
  stop(): void {
    this.isRunning = false
    console.log('🛑 Background worker stopped')
  }
}
```

## 🎯 **Workarounds**

### **If pnpm agent:start Fails**
```bash
# Run diagnostics first
pnpm agent:doctor

# Check PATH configuration
echo $PATH

# Verify pnpm installation
pnpm --version

# Try alternative start methods
node scripts/agent-start.js
deno run --allow-all scripts/agent-start.ts
```

### **If Budget Exceeded**
1. Reduce `maxJobsPerPass` to 1
2. Decrease `maxFilesPerJob` to 5
3. Lower `maxLinesPerJob` to 100
4. Increase sleep interval between passes

### **If Lock File Issues**
```bash
# Remove lock file manually
rm .agent/LOCK

# Check status
cat .agent/status.json

# Restart agent
pnpm agent:start
```

## 📋 **Testing Checklist**

- [ ] Budget limits enforced correctly
- [ ] Kill switch activates/deactivates
- [ ] Diagnostics run successfully
- [ ] Worker respects lock file
- [ ] Memory usage stays within limits
- [ ] Jobs complete within time limits
- [ ] Error handling works properly

---

**Remember**: Always check the kill switch before starting any background work!
