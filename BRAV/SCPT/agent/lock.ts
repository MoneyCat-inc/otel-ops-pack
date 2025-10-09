#!/usr/bin/env tsx
/**
 * AUTO-BOTS Single-Writer Mutex
 * Atomic lock acquisition for Agent A (writer)
 * Agent B (monitor) never writes, so never calls this
 * 
 * Exit Codes:
 * - 0: Lock acquired successfully
 * - 52: Writer already present (conflict)
 */

import * as fs from 'fs';
import * as path from 'path';

const EXIT_WRITER_CONFLICT = 52;

interface LockData {
  pid: number;
  agent: string;
  startedAt: string;
  lane: string;
}

class WriterLock {
  private lockPath: string;
  private acquired: boolean = false;

  constructor() {
    this.lockPath = path.join(process.cwd(), '.agent', 'JOB.lock');
  }

  async acquire(agent: string, lane: string): Promise<void> {
    try {
      // Atomic exclusive create
      const fd = fs.openSync(this.lockPath, 'wx');
      
      const lockData: LockData = {
        pid: process.pid,
        agent,
        startedAt: new Date().toISOString(),
        lane
      };

      fs.writeSync(fd, JSON.stringify(lockData, null, 2));
      fs.closeSync(fd);

      this.acquired = true;
      console.log(`✅ Lock acquired: Agent ${agent}, Lane: ${lane}, PID: ${process.pid}`);

      // Setup cleanup handlers
      this.setupCleanup();
    } catch (error: any) {
      if (error.code === 'EEXIST') {
        // Lock already exists
        try {
          const existingLock: LockData = JSON.parse(
            fs.readFileSync(this.lockPath, 'utf8')
          );
          console.error('❌ CONFLICT: Writer already present');
          console.error(`conflict:writer-present`);
          console.error(`Existing lock: Agent ${existingLock.agent}, PID: ${existingLock.pid}`);
          console.error(`Started at: ${existingLock.startedAt}`);
          process.exit(EXIT_WRITER_CONFLICT);
        } catch {
          console.error('❌ CONFLICT: Lock file exists but unreadable');
          console.error(`conflict:writer-present`);
          process.exit(EXIT_WRITER_CONFLICT);
        }
      }
      throw error;
    }
  }

  private setupCleanup(): void {
    const cleanup = () => {
      if (this.acquired) {
        try {
          if (fs.existsSync(this.lockPath)) {
            fs.unlinkSync(this.lockPath);
            console.log('🔓 Lock released');
          }
        } catch (error) {
          console.error('⚠️  Failed to release lock:', error);
        }
      }
    };

    // Cleanup on normal exit
    process.on('exit', cleanup);

    // Cleanup on uncaught exceptions
    process.on('uncaughtException', (error) => {
      console.error('❌ Uncaught exception:', error);
      cleanup();
      process.exit(1);
    });

    // Cleanup on unhandled rejections
    process.on('unhandledRejection', (reason) => {
      console.error('❌ Unhandled rejection:', reason);
      cleanup();
      process.exit(1);
    });

    // Cleanup on termination signals
    process.on('SIGINT', () => {
      console.log('\n⚠️  Interrupted');
      cleanup();
      process.exit(130);
    });

    process.on('SIGTERM', () => {
      console.log('\n⚠️  Terminated');
      cleanup();
      process.exit(143);
    });
  }

  release(): void {
    if (this.acquired && fs.existsSync(this.lockPath)) {
      fs.unlinkSync(this.lockPath);
      this.acquired = false;
      console.log('🔓 Lock released manually');
    }
  }
}

async function main() {
  const agent = process.argv.find(arg => arg.startsWith('--agent='))?.split('=')[1] || 'A';
  const lane = process.argv.find(arg => arg.startsWith('--lane='))?.split('=')[1] || 'unknown';

  if (agent !== 'A') {
    console.error(`❌ ERROR: Only Agent A can acquire write lock`);
    console.error(`Attempted by: Agent ${agent}`);
    process.exit(1);
  }

  const lock = new WriterLock();
  await lock.acquire(agent, lane);

  // Lock is held until process exits
  console.log('🔒 Write lock active. Press Ctrl+C to release.');
}

// Only run if called directly
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Lock acquisition failed:', error);
    process.exit(1);
  });
}

export { WriterLock };

