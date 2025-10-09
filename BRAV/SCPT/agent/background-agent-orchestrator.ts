#!/usr/bin/env node

/**
 * Background Agent Orchestrator
 * Spins off each task type to dedicated background agents and monitors their behavior
 * 
 * Following ECRR methodology:
 * - Examine: Capture agent behavior and task execution patterns
 * - Clean: Remove failed agents and restart healthy ones
 * - Report: Generate comprehensive ECRR reports
 * - Role: Assign responsibility for each agent's performance
 */

import { spawn, ChildProcess } from 'child_process';
import { writeFile, mkdir, readFile, access } from 'fs/promises';
import { join } from 'path';
import { trace } from '@opentelemetry/api';

// Agent configuration
interface AgentConfig {
  id: string;
  name: string;
  taskType: string;
  script: string;
  maxConcurrency: number;
  healthCheckInterval: number;
  restartOnFailure: boolean;
  resourceLimits: {
    memoryMB: number;
    cpuPercent: number;
  };
}

// Task execution result
interface TaskResult {
  agentId: string;
  taskId: string;
  status: 'success' | 'failed' | 'timeout' | 'cancelled';
  startTime: Date;
  endTime: Date;
  duration: number;
  output: string;
  error?: string;
  metrics: {
    memoryUsage: number;
    cpuUsage: number;
    networkIO: number;
  };
}

// Agent behavior analysis
interface AgentBehavior {
  agentId: string;
  totalTasks: number;
  successRate: number;
  avgDuration: number;
  failurePatterns: string[];
  resourceUsage: {
    avgMemory: number;
    avgCPU: number;
    peakMemory: number;
    peakCPU: number;
  };
  anomalies: string[];
  recommendations: string[];
}

// ECRR Report structure
interface ECRRReport {
  reportId: string;
  timestamp: Date;
  scope: string;
  findings: {
    critical: string[];
    major: string[];
    minor: string[];
  };
  recommendations: string[];
  compliance: {
    security: boolean;
    performance: boolean;
    reliability: boolean;
  };
  evidence: {
    logs: string[];
    metrics: any[];
    screenshots: string[];
  };
  responsibleAgent: string;
  bossCatApproval: boolean;
}

class BackgroundAgentOrchestrator {
  private agents: Map<string, ChildProcess> = new Map();
  private agentConfigs: AgentConfig[] = [];
  private taskQueue: Map<string, any[]> = new Map();
  private behaviorData: Map<string, AgentBehavior> = new Map();
  private reports: ECRRReport[] = [];
  private isRunning = false;

  constructor() {
    this.initializeAgentConfigs();
  }

  private initializeAgentConfigs(): void {
    this.agentConfigs = [
      {
        id: 'monitoring-agent',
        name: 'Monitoring Agent',
        taskType: 'monitoring',
        script: 'scripts/agent/monitoring-agent.ts',
        maxConcurrency: 5,
        healthCheckInterval: 30000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 512, cpuPercent: 50 }
      },
      {
        id: 'cleanup-agent',
        name: 'Cleanup Agent',
        taskType: 'cleanup',
        script: 'scripts/agent/cleanup-agent.ts',
        maxConcurrency: 3,
        healthCheckInterval: 60000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 256, cpuPercent: 30 }
      },
      {
        id: 'remediation-agent',
        name: 'Remediation Agent',
        taskType: 'remediation',
        script: 'scripts/agent/remediation-agent.ts',
        maxConcurrency: 2,
        healthCheckInterval: 45000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 1024, cpuPercent: 70 }
      },
      {
        id: 'maintenance-agent',
        name: 'Maintenance Agent',
        taskType: 'maintenance',
        script: 'scripts/agent/maintenance-agent.ts',
        maxConcurrency: 4,
        healthCheckInterval: 90000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 768, cpuPercent: 60 }
      },
      {
        id: 'alert-agent',
        name: 'Alert Agent',
        taskType: 'alert',
        script: 'scripts/agent/alert-agent.ts',
        maxConcurrency: 10,
        healthCheckInterval: 15000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 128, cpuPercent: 20 }
      },
      {
        id: 'optimization-agent',
        name: 'Optimization Agent',
        taskType: 'optimization',
        script: 'scripts/agent/optimization-agent.ts',
        maxConcurrency: 1,
        healthCheckInterval: 120000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 2048, cpuPercent: 80 }
      },
      {
        id: 'compliance-agent',
        name: 'Compliance Agent',
        taskType: 'compliance',
        script: 'scripts/agent/compliance-agent.ts',
        maxConcurrency: 2,
        healthCheckInterval: 180000,
        restartOnFailure: true,
        resourceLimits: { memoryMB: 512, cpuPercent: 40 }
      }
    ];
  }

  async start(): Promise<void> {
    const span = trace.getActiveSpan();
    console.log('🚀 Starting Background Agent Orchestrator...');
    
    try {
      // Create agent directories
      await this.createAgentDirectories();
      
      // Initialize behavior tracking
      await this.initializeBehaviorTracking();
      
      // Start all agents
      for (const config of this.agentConfigs) {
        await this.startAgent(config);
      }
      
      // Start monitoring loop
      this.isRunning = true;
      this.startMonitoringLoop();
      
      // Start health checks
      this.startHealthChecks();
      
      span?.setAttributes({
        'orchestrator.started': true,
        'orchestrator.agent_count': this.agentConfigs.length,
        'orchestrator.status': 'running'
      });
      
      console.log(`✅ Background Agent Orchestrator started with ${this.agentConfigs.length} agents`);
      
    } catch (error) {
      span?.setAttributes({
        'orchestrator.start_error': true,
        'orchestrator.error': error instanceof Error ? error.message : 'Unknown error'
      });
      console.error('❌ Failed to start Background Agent Orchestrator:', error);
      throw error;
    }
  }

  private async createAgentDirectories(): Promise<void> {
    const directories = [
      'artifacts/agents',
      'artifacts/agents/logs',
      'artifacts/agents/reports',
      'artifacts/agents/metrics',
      'artifacts/agents/ecrr'
    ];

    for (const dir of directories) {
      try {
        await mkdir(dir, { recursive: true });
      } catch (error) {
        // Directory might already exist
      }
    }
  }

  private async startAgent(config: AgentConfig): Promise<void> {
    const span = trace.getActiveSpan();
    
    try {
      console.log(`🤖 Starting ${config.name} (${config.id})...`);
      
      // Check if agent script exists
      try {
        await access(config.script);
      } catch {
        console.warn(`⚠️ Agent script not found: ${config.script}, creating stub...`);
        await this.createAgentStub(config);
      }
      
      // Spawn agent process
      const agentProcess = spawn('npx', ['tsx', config.script], {
        stdio: ['pipe', 'pipe', 'pipe'],
        env: {
          ...process.env,
          AGENT_ID: config.id,
          AGENT_NAME: config.name,
          AGENT_TYPE: config.taskType,
          MAX_CONCURRENCY: config.maxConcurrency.toString(),
          RESOURCE_LIMIT_MEMORY: config.resourceLimits.memoryMB.toString(),
          RESOURCE_LIMIT_CPU: config.resourceLimits.cpuPercent.toString()
        }
      });
      
      // Set up process monitoring
      this.setupAgentMonitoring(agentProcess, config);
      
      // Store agent reference
      this.agents.set(config.id, agentProcess);
      
      // Initialize behavior tracking for this agent
      this.behaviorData.set(config.id, {
        agentId: config.id,
        totalTasks: 0,
        successRate: 0,
        avgDuration: 0,
        failurePatterns: [],
        resourceUsage: {
          avgMemory: 0,
          avgCPU: 0,
          peakMemory: 0,
          peakCPU: 0
        },
        anomalies: [],
        recommendations: []
      });
      
      span?.setAttributes({
        [`agent.${config.id}.started`]: true,
        [`agent.${config.id}.pid`]: agentProcess.pid || 0
      });
      
      console.log(`✅ ${config.name} started (PID: ${agentProcess.pid})`);
      
    } catch (error) {
      span?.setAttributes({
        [`agent.${config.id}.start_error`]: true,
        [`agent.${config.id}.error`]: error instanceof Error ? error.message : 'Unknown error'
      });
      console.error(`❌ Failed to start ${config.name}:`, error);
    }
  }

  private async createAgentStub(config: AgentConfig): Promise<void> {
    const stubContent = `#!/usr/bin/env node

/**
 * ${config.name} - Background Agent Stub
 * Generated by Background Agent Orchestrator
 */

import { trace } from '@opentelemetry/api';

class ${config.name.replace(/\s+/g, '')} {
  private agentId: string;
  private taskType: string;
  private isRunning = false;

  constructor() {
    this.agentId = process.env.AGENT_ID || '${config.id}';
    this.taskType = process.env.AGENT_TYPE || '${config.taskType}';
  }

  async start(): Promise<void> {
    console.log(\`🤖 Starting \${this.agentId}...\`);
    this.isRunning = true;
    
    // Main agent loop
    while (this.isRunning) {
      try {
        await this.processTasks();
        await this.sleep(5000); // 5 second intervals
      } catch (error) {
        console.error(\`Error in \${this.agentId}:\`, error);
        await this.sleep(10000); // Wait 10 seconds on error
      }
    }
  }

  private async processTasks(): Promise<void> {
    const span = trace.getActiveSpan();
    
    // Simulate task processing
    const taskCount = Math.floor(Math.random() * 3) + 1;
    
    for (let i = 0; i < taskCount; i++) {
      const taskId = \`task-\${Date.now()}-\${i}\`;
      console.log(\`📋 Processing \${this.taskType} task: \${taskId}\`);
      
      // Simulate work
      await this.sleep(Math.random() * 2000 + 1000);
      
      // Simulate success/failure
      const success = Math.random() > 0.1; // 90% success rate
      
      if (success) {
        console.log(\`✅ Task \${taskId} completed successfully\`);
        span?.setAttributes({
          'task.completed': true,
          'task.type': this.taskType,
          'task.id': taskId
        });
      } else {
        console.warn(\`⚠️ Task \${taskId} failed\`);
        span?.setAttributes({
          'task.failed': true,
          'task.type': this.taskType,
          'task.id': taskId
        });
      }
    }
  }

  private async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async stop(): Promise<void> {
    console.log(\`🛑 Stopping \${this.agentId}...\`);
    this.isRunning = false;
  }
}

// Start the agent
const agent = new ${config.name.replace(/\s+/g, '')}();
agent.start().catch(console.error);

// Graceful shutdown
process.on('SIGINT', () => {
  agent.stop().then(() => process.exit(0));
});

process.on('SIGTERM', () => {
  agent.stop().then(() => process.exit(0));
});
`;

    await writeFile(config.script, stubContent, 'utf8');
    console.log(`📝 Created agent stub: ${config.script}`);
  }

  private setupAgentMonitoring(process: ChildProcess, config: AgentConfig): void {
    const span = trace.getActiveSpan();
    
    // Monitor stdout
    process.stdout?.on('data', (data) => {
      const output = data.toString();
      console.log(`[${config.name}] ${output.trim()}`);
      
      // Log to file
      this.logAgentOutput(config.id, 'stdout', output);
    });
    
    // Monitor stderr
    process.stderr?.on('data', (data) => {
      const output = data.toString();
      console.error(`[${config.name}] ERROR: ${output.trim()}`);
      
      // Log to file
      this.logAgentOutput(config.id, 'stderr', output);
      
      // Track failure patterns
      this.trackFailurePattern(config.id, output);
    });
    
    // Monitor process exit
    process.on('exit', (code, signal) => {
      console.log(`[${config.name}] Process exited with code ${code}, signal ${signal}`);
      
      span?.setAttributes({
        [`agent.${config.id}.exited`]: true,
        [`agent.${config.id}.exit_code`]: code || 0,
        [`agent.${config.id}.exit_signal`]: signal || 'none'
      });
      
      // Restart if configured to do so
      if (config.restartOnFailure && code !== 0) {
        console.log(`🔄 Restarting ${config.name}...`);
        setTimeout(() => this.startAgent(config), 5000);
      }
    });
    
    // Monitor process errors
    process.on('error', (error) => {
      console.error(`[${config.name}] Process error:`, error);
      
      span?.setAttributes({
        [`agent.${config.id}.process_error`]: true,
        [`agent.${config.id}.error`]: error.message
      });
    });
  }

  private async logAgentOutput(agentId: string, type: 'stdout' | 'stderr', output: string): Promise<void> {
    try {
      const timestamp = new Date().toISOString();
      const logEntry = `[${timestamp}] [${type.toUpperCase()}] ${output}`;
      
      await writeFile(
        join('artifacts/agents/logs', `${agentId}.log`),
        logEntry,
        { flag: 'a' }
      );
    } catch (error) {
      console.error(`Failed to log agent output:`, error);
    }
  }

  private trackFailurePattern(agentId: string, errorOutput: string): void {
    const behavior = this.behaviorData.get(agentId);
    if (!behavior) return;
    
    // Simple pattern detection
    const patterns = [
      'memory',
      'timeout',
      'connection',
      'permission',
      'resource',
      'network'
    ];
    
    const matchedPattern = patterns.find(pattern => 
      errorOutput.toLowerCase().includes(pattern)
    );
    
    if (matchedPattern && !behavior.failurePatterns.includes(matchedPattern)) {
      behavior.failurePatterns.push(matchedPattern);
    }
  }

  private startMonitoringLoop(): void {
    setInterval(async () => {
      if (!this.isRunning) return;
      
      try {
        await this.collectAgentMetrics();
        await this.analyzeAgentBehavior();
        await this.generateECRRReports();
      } catch (error) {
        console.error('Error in monitoring loop:', error);
      }
    }, 60000); // Every minute
  }

  private startHealthChecks(): void {
    for (const config of this.agentConfigs) {
      setInterval(() => {
        this.performHealthCheck(config);
      }, config.healthCheckInterval);
    }
  }

  private async performHealthCheck(config: AgentConfig): Promise<void> {
    const agent = this.agents.get(config.id);
    if (!agent) {
      console.warn(`⚠️ Agent ${config.name} not found during health check`);
      if (config.restartOnFailure) {
        await this.startAgent(config);
      }
      return;
    }
    
    // Check if process is still running
    if (agent.killed || agent.exitCode !== null) {
      console.warn(`⚠️ Agent ${config.name} is not running (exit code: ${agent.exitCode})`);
      if (config.restartOnFailure) {
        await this.startAgent(config);
      }
    }
  }

  private async collectAgentMetrics(): Promise<void> {
    for (const [agentId, process] of this.agents) {
      if (!process.pid) continue;
      
      try {
        // Collect basic process metrics
        const metrics = {
          pid: process.pid,
          memoryUsage: process.memoryUsage?.heapUsed || 0,
          cpuUsage: 0, // Would need external tool for accurate CPU usage
          timestamp: new Date().toISOString()
        };
        
        // Save metrics
        await writeFile(
          join('artifacts/agents/metrics', `${agentId}-metrics.json`),
          JSON.stringify(metrics, null, 2),
          { flag: 'a' }
        );
        
        // Update behavior data
        const behavior = this.behaviorData.get(agentId);
        if (behavior) {
          behavior.resourceUsage.avgMemory = 
            (behavior.resourceUsage.avgMemory + metrics.memoryUsage) / 2;
          behavior.resourceUsage.peakMemory = 
            Math.max(behavior.resourceUsage.peakMemory, metrics.memoryUsage);
        }
        
      } catch (error) {
        console.error(`Failed to collect metrics for ${agentId}:`, error);
      }
    }
  }

  private async analyzeAgentBehavior(): Promise<void> {
    for (const [agentId, behavior] of this.behaviorData) {
      // Analyze success rate
      if (behavior.totalTasks > 0) {
        behavior.successRate = (behavior.totalTasks - behavior.failurePatterns.length) / behavior.totalTasks;
      }
      
      // Detect anomalies
      if (behavior.successRate < 0.8) {
        behavior.anomalies.push('Low success rate detected');
      }
      
      if (behavior.resourceUsage.peakMemory > 1024 * 1024 * 1024) { // 1GB
        behavior.anomalies.push('High memory usage detected');
      }
      
      // Generate recommendations
      behavior.recommendations = [];
      
      if (behavior.failurePatterns.includes('memory')) {
        behavior.recommendations.push('Consider increasing memory limits');
      }
      
      if (behavior.failurePatterns.includes('timeout')) {
        behavior.recommendations.push('Consider increasing timeout values');
      }
      
      if (behavior.successRate < 0.9) {
        behavior.recommendations.push('Investigate failure patterns');
      }
    }
  }

  private async generateECRRReports(): Promise<void> {
    const timestamp = new Date();
    
    for (const [agentId, behavior] of this.behaviorData) {
      const report: ECRRReport = {
        reportId: `ecrr-${agentId}-${timestamp.getTime()}`,
        timestamp,
        scope: `Agent Behavior Analysis: ${agentId}`,
        findings: {
          critical: behavior.anomalies.filter(a => a.includes('High') || a.includes('Low')).slice(0, 3),
          major: behavior.failurePatterns.slice(0, 5),
          minor: behavior.recommendations.slice(0, 3)
        },
        recommendations: behavior.recommendations,
        compliance: {
          security: behavior.failurePatterns.length === 0,
          performance: behavior.successRate > 0.8,
          reliability: behavior.anomalies.length === 0
        },
        evidence: {
          logs: [`artifacts/agents/logs/${agentId}.log`],
          metrics: [`artifacts/agents/metrics/${agentId}-metrics.json`],
          screenshots: []
        },
        responsibleAgent: agentId,
        bossCatApproval: behavior.successRate > 0.9 && behavior.anomalies.length === 0
      };
      
      this.reports.push(report);
      
      // Save report
      await writeFile(
        join('artifacts/agents/ecrr', `${report.reportId}.json`),
        JSON.stringify(report, null, 2)
      );
    }
  }

  async stop(): Promise<void> {
    console.log('🛑 Stopping Background Agent Orchestrator...');
    this.isRunning = false;
    
    // Stop all agents
    for (const [agentId, process] of this.agents) {
      console.log(`🛑 Stopping agent ${agentId}...`);
      process.kill('SIGTERM');
    }
    
    // Wait for graceful shutdown
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Force kill any remaining processes
    for (const [agentId, process] of this.agents) {
      if (!process.killed) {
        process.kill('SIGKILL');
      }
    }
    
    console.log('✅ Background Agent Orchestrator stopped');
  }

  getStatus(): any {
    return {
      orchestrator: {
        running: this.isRunning,
        agentCount: this.agents.size,
        totalReports: this.reports.length
      },
      agents: Array.from(this.agents.entries()).map(([id, process]) => ({
        id,
        pid: process.pid,
        killed: process.killed,
        exitCode: process.exitCode,
        behavior: this.behaviorData.get(id)
      })),
      reports: this.reports.slice(-10) // Last 10 reports
    };
  }
}

// Export for use as module
export { BackgroundAgentOrchestrator, AgentConfig, TaskResult, AgentBehavior, ECRRReport };

// Run if called directly
if (require.main === module) {
  const orchestrator = new BackgroundAgentOrchestrator();
  
  orchestrator.start().catch(console.error);
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    orchestrator.stop().then(() => process.exit(0));
  });
  
  process.on('SIGTERM', () => {
    orchestrator.stop().then(() => process.exit(0));
  });
}
