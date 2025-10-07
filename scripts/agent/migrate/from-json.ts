/**
 * Migrator: JSON Queue → SQLite
 * 
 * Imports existing jobs from .agent/agent_queue.json into SQLite database.
 * This is a one-time migration that preserves existing job data.
 */

import { readFileSync, existsSync } from 'fs';
// import { join } from 'path';
import { SQLiteQueueDB, Job } from '../db';
import { QueueConfig } from '../../../lib/config/queue';

export interface JsonJob {
  id: string;
  kind: string;
  payload: any;
  priority?: number;
  attempts?: number;
  max_attempts?: number;
  not_before?: number;
  created_at?: number;
  ttl_ms?: number;
  status?: string;
}

export interface JsonQueueData {
  jobs?: JsonJob[];
  metadata?: {
    version?: string;
    last_updated?: string;
  };
}

export class JsonToSQLiteMigrator {
  private db: SQLiteQueueDB;
  private config: QueueConfig;

  constructor(db: SQLiteQueueDB, config: QueueConfig) {
    this.db = db;
    this.config = config;
  }

  /**
   * Migrate jobs from JSON file to SQLite database
   */
  async migrate(jsonFilePath: string = '.agent/agent_queue.json'): Promise<{
    success: boolean;
    migrated: number;
    errors: string[];
    warnings: string[];
  }> {
    const errors: string[] = [];
    const warnings: string[] = [];
    let migrated = 0;

    try {
      // Check if JSON file exists
      if (!existsSync(jsonFilePath)) {
        return {
          success: true,
          migrated: 0,
          errors: [`JSON file not found: ${jsonFilePath}`],
          warnings: [],
        };
      }

      // Read and parse JSON file
      const jsonContent = readFileSync(jsonFilePath, 'utf-8');
      const jsonData: JsonQueueData = JSON.parse(jsonContent);

      if (!jsonData.jobs || !Array.isArray(jsonData.jobs)) {
        return {
          success: true,
          migrated: 0,
          errors: [`Invalid JSON structure: expected 'jobs' array`],
          warnings: [],
        };
      }

      console.log(`Found ${jsonData.jobs.length} jobs in JSON file`);

      // Migrate each job
      for (const jsonJob of jsonData.jobs) {
        try {
          const migratedJob = this.convertJsonJob(jsonJob);
          if (migratedJob) {
            // Check if job already exists in SQLite
            const existingJob = this.db.getJob((migratedJob as any).id);
            if (existingJob) {
              warnings.push(`Job ${(migratedJob as any).id} already exists in SQLite, skipping`);
              continue;
            }

            // Add job to SQLite
            const jobId = this.db.addJob(migratedJob);
            if (jobId) {
              migrated++;
              console.log(`Migrated job ${jobId} (${migratedJob.kind})`);
            }
          }
        } catch (error) {
          const errorMsg = `Failed to migrate job ${jsonJob.id}: ${error instanceof Error ? error.message : 'Unknown error'}`;
          errors.push(errorMsg);
          console.error(errorMsg);
        }
      }

      console.log(`Migration completed: ${migrated} jobs migrated, ${errors.length} errors, ${warnings.length} warnings`);

      return {
        success: errors.length === 0,
        migrated,
        errors,
        warnings,
      };

    } catch (error) {
      const errorMsg = `Migration failed: ${error instanceof Error ? error.message : 'Unknown error'}`;
      errors.push(errorMsg);
      console.error(errorMsg);

      return {
        success: false,
        migrated,
        errors,
        warnings,
      };
    }
  }

  /**
   * Convert JSON job format to SQLite job format
   */
  private convertJsonJob(jsonJob: JsonJob): Omit<Job, 'id' | 'attempts' | 'status'> | null {
    try {
      // Validate required fields
      if (!jsonJob.kind) {
        throw new Error('Missing required field: kind');
      }

      // Convert payload to JSON string
      let payloadJson: string;
      if (typeof jsonJob.payload === 'string') {
        payloadJson = jsonJob.payload;
      } else {
        payloadJson = JSON.stringify(jsonJob.payload || {});
      }

      // Set defaults for optional fields
      const priority = jsonJob.priority ?? 0;
      const maxAttempts = jsonJob.max_attempts ?? this.config.maxAttempts;
      const notBefore = jsonJob.not_before ?? Date.now();
      const createdAt = jsonJob.created_at ?? Date.now();
      const ttlMs = jsonJob.ttl_ms ?? 86400000; // 24 hours default

      return {
        kind: jsonJob.kind,
        payload_json: payloadJson,
        priority,
        max_attempts: maxAttempts,
        not_before: notBefore,
        created_at: createdAt,
        ttl_ms: ttlMs,
      };

    } catch (error) {
      console.error(`Failed to convert job ${jsonJob.id}:`, error);
      return null;
    }
  }

  /**
   * Validate migration integrity
   */
  async validateMigration(jsonFilePath: string = '.agent/agent_queue.json'): Promise<{
    success: boolean;
    jsonCount: number;
    sqliteCount: number;
    errors: string[];
  }> {
    const errors: string[] = [];

    try {
      // Count jobs in JSON file
      let jsonCount = 0;
      if (existsSync(jsonFilePath)) {
        const jsonContent = readFileSync(jsonFilePath, 'utf-8');
        const jsonData: JsonQueueData = JSON.parse(jsonContent);
        jsonCount = jsonData.jobs?.length || 0;
      }

      // Count jobs in SQLite
      const stats = this.db.getQueueStats();
      const sqliteCount = stats.total;

      // Check for discrepancies
      if (jsonCount !== sqliteCount) {
        errors.push(`Count mismatch: JSON has ${jsonCount} jobs, SQLite has ${sqliteCount} jobs`);
      }

      return {
        success: errors.length === 0,
        jsonCount,
        sqliteCount,
        errors,
      };

    } catch (error) {
      errors.push(`Validation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return {
        success: false,
        jsonCount: 0,
        sqliteCount: 0,
        errors,
      };
    }
  }

  /**
   * Create a backup of the original JSON file
   */
  backupJsonFile(jsonFilePath: string = '.agent/agent_queue.json'): string | null {
    try {
      if (!existsSync(jsonFilePath)) {
        return null;
      }

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupPath = `${jsonFilePath}.backup.${timestamp}`;
      
      const content = readFileSync(jsonFilePath, 'utf-8');
      require('fs').writeFileSync(backupPath, content, 'utf-8');
      
      console.log(`Backed up JSON file to: ${backupPath}`);
      return backupPath;
    } catch (error) {
      console.error(`Failed to backup JSON file: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return null;
    }
  }
}

/**
 * CLI interface for migration
 */
export async function runMigration(): Promise<void> {
  const config = require('../../../lib/config/queue').getQueueConfig();
  const dbPath = '.agent/queue.db';
  
  console.log('Starting JSON to SQLite migration...');
  console.log('Configuration:', require('../../../lib/config/queue').describeQueueConfig(config));
  
  const db = new SQLiteQueueDB(dbPath, config);
  const migrator = new JsonToSQLiteMigrator(db, config);
  
  try {
    // Create backup
    const backupPath = migrator.backupJsonFile();
    if (backupPath) {
      console.log(`Backup created: ${backupPath}`);
    }
    
    // Run migration
    const result = await migrator.migrate();
    
    if (result.success) {
      console.log(`✅ Migration successful: ${result.migrated} jobs migrated`);
    } else {
      console.error(`❌ Migration failed with ${result.errors.length} errors`);
      result.errors.forEach(error => console.error(`  - ${error}`));
    }
    
    if (result.warnings.length > 0) {
      console.warn(`⚠️  ${result.warnings.length} warnings:`);
      result.warnings.forEach(warning => console.warn(`  - ${warning}`));
    }
    
    // Validate migration
    const validation = await migrator.validateMigration();
    if (validation.success) {
      console.log(`✅ Validation passed: ${validation.sqliteCount} jobs in SQLite`);
    } else {
      console.error(`❌ Validation failed:`);
      validation.errors.forEach(error => console.error(`  - ${error}`));
    }
    
  } finally {
    db.close();
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  runMigration().catch(error => {
    console.error('Migration failed:', error);
    process.exit(1);
  });
}