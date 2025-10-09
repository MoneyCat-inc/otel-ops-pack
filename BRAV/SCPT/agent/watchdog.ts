import './otel'; // initialize SDK first
import { trace, metrics } from '@opentelemetry/api';

const tracer = trace.getTracer('codex-local.watchdog');
const meter  = metrics.getMeter('codex-local');

const jobsCounter = meter.createCounter('codex.jobs_processed', { description: 'Jobs processed' });
const violationsCounter = meter.createCounter('codex.guardrail_violations', { description: 'Guardrail violations found' });

export async function runCycle(queue: any[]) {
  await tracer.startActiveSpan('watchdog.cycle', async span => {
    try {
      span.setAttribute('queue.length', queue.length);
      
      // Simulate processing jobs
      const processedJobs = Math.min(queue.length, 2);
      jobsCounter.add(processedJobs);
      
      span.setAttribute('jobs.processed', processedJobs);
      span.setAttribute('jobs.remaining', queue.length - processedJobs);
      
      // Check for guardrail violations
      try {
        const fs = require('fs');
        const reportPath = '.agent/guardrails_report.json';
        if (fs.existsSync(reportPath)) {
          const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
          const violationCount = report.items?.length || 0;
          violationsCounter.add(violationCount, { category: 'total' });
          span.setAttribute('guardrails.violations', violationCount);
        }
      } catch (error) {
        console.warn('Failed to read guardrails report:', error);
      }
      
      console.log(`[watchdog] Processed ${processedJobs} jobs, ${queue.length - processedJobs} remaining`);
      
    } finally {
      span.end();
    }
  });
}

// Main watchdog loop
async function main() {
  console.log('[watchdog] Starting codex-local watchdog with OTel telemetry');
  
  while (true) {
    try {
      // Check for lock file
      const fs = require('fs');
      if (fs.existsSync('.agent/LOCK')) {
        console.log('[watchdog] Agent is locked, waiting...');
        await new Promise(resolve => setTimeout(resolve, 30000)); // 30 second wait
        continue;
      }
      
      // Simulate queue processing
      const queue = []; // In real implementation, read from .agent/agent_queue.json
      await runCycle(queue);
      
      // Wait 5 minutes before next cycle
      await new Promise(resolve => setTimeout(resolve, 300000));
      
    } catch (error) {
      console.error('[watchdog] Error in main loop:', error);
      await new Promise(resolve => setTimeout(resolve, 60000)); // Wait 1 minute on error
    }
  }
}

if (require.main === module) {
  main().catch(console.error);
}
