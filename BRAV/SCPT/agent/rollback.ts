#!/usr/bin/env node

/**
 * Agent System Rollback Script
 */

import { promises as fs } from 'fs';
import path from 'path';

async function rollback() {
  console.log('🔄 Rolling back agent system...');
  
  try {
    // Stop any running processes
    console.log('🛑 Stopping agent system...');
    
    // Restore from backup
    const backupDir = '.agent/backups';
    const files = await fs.readdir(backupDir);
    
    for (const file of files) {
      if (file.endsWith('.json')) {
        const backupPath = path.join(backupDir, file);
        const targetPath = path.join('.agent', file);
        
        await fs.copyFile(backupPath, targetPath);
        console.log(`📁 Restored ${file}`);
      }
    }
    
    // Clean up temporary files
    const tempFiles = ['.agent/LOCK', '.agent/OFFLINE'];
    for (const file of tempFiles) {
      try {
        await fs.unlink(file);
      } catch {
        // File might not exist
      }
    }
    
    console.log('✅ Rollback completed successfully');
    
  } catch (error) {
    console.error('❌ Rollback failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  rollback();
}
