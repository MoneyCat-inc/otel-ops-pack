/**
 * Idempotent IO utilities for agent operations
 * Provides atomic file operations and JSON upsert helpers
 */

import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { createHash } from 'crypto';

export interface AtomicWriteOptions {
  backup?: boolean;
  createDir?: boolean;
}

export function writeFileAtomicIfChanged(
  filePath: string, 
  content: string, 
  options: AtomicWriteOptions = {}
): boolean {
  const { backup = false, createDir = true } = options;
  
  try {
    // Ensure directory exists
    if (createDir) {
      const dir = dirname(filePath);
      if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
      }
    }
    
    // Check if file exists and content is the same
    if (existsSync(filePath)) {
      const existingContent = readFileSync(filePath, 'utf8');
      if (existingContent === content) {
        return false; // No change needed
      }
      
      // Create backup if requested
      if (backup) {
        const backupPath = `${filePath}.backup.${Date.now()}`;
        writeFileSync(backupPath, existingContent, 'utf8');
      }
    }
    
    // Write new content
    writeFileSync(filePath, content, 'utf8');
    return true; // File was written
    
  } catch (error) {
    console.error(`Failed to write file ${filePath}:`, error);
    throw error;
  }
}

export function jsonUpsert<T extends Record<string, any>>(
  filePath: string,
  key: string,
  value: any,
  options: AtomicWriteOptions = {}
): boolean {
  try {
    let data: Record<string, any> = {};
    
    // Read existing data
    if (existsSync(filePath)) {
      const content = readFileSync(filePath, 'utf8');
      try {
        data = JSON.parse(content);
      } catch {
        // If JSON is invalid, start fresh
        data = {};
      }
    }
    
    // Update the key
    data[key] = value;
    
    // Write back
    const newContent = JSON.stringify(data, null, 2);
    return writeFileAtomicIfChanged(filePath, newContent, options);
    
  } catch (error) {
    console.error(`Failed to upsert JSON ${filePath}:`, error);
    throw error;
  }
}

export function jsonArrayAppend<T>(
  filePath: string,
  item: T,
  options: AtomicWriteOptions = {}
): boolean {
  try {
    let array: T[] = [];
    
    // Read existing array
    if (existsSync(filePath)) {
      const content = readFileSync(filePath, 'utf8');
      try {
        array = JSON.parse(content);
        if (!Array.isArray(array)) {
          array = [];
        }
      } catch {
        array = [];
      }
    }
    
    // Append item
    array.push(item);
    
    // Write back
    const newContent = JSON.stringify(array, null, 2);
    return writeFileAtomicIfChanged(filePath, newContent, options);
    
  } catch (error) {
    console.error(`Failed to append to JSON array ${filePath}:`, error);
    throw error;
  }
}

export function getContentHash(content: string): string {
  return createHash('sha256').update(content).digest('hex').substring(0, 16);
}

export function ensureShadowPath(canonicalPath: string): string {
  // Convert canonical path to shadow path
  // .agent/status.json -> .agent/shadow/status.json
  if (canonicalPath.startsWith('.agent/')) {
    return canonicalPath.replace('.agent/', '.agent/shadow/');
  }
  
  // For other paths, create shadow directory structure
  const parts = canonicalPath.split('/');
  parts.splice(-1, 0, 'shadow');
  return parts.join('/');
}

export function writeShadowArtifact(
  canonicalPath: string,
  content: string,
  options: AtomicWriteOptions = {}
): boolean {
  const shadowPath = ensureShadowPath(canonicalPath);
  return writeFileAtomicIfChanged(shadowPath, content, options);
}

export function readShadowArtifact(canonicalPath: string): string | null {
  const shadowPath = ensureShadowPath(canonicalPath);
  
  if (!existsSync(shadowPath)) {
    return null;
  }
  
  try {
    return readFileSync(shadowPath, 'utf8');
  } catch (error) {
    console.error(`Failed to read shadow artifact ${shadowPath}:`, error);
    return null;
  }
}

export function compareShadowVsCanonical(canonicalPath: string): {
  identical: boolean;
  canonicalExists: boolean;
  shadowExists: boolean;
  differences?: string[];
} {
  const shadowPath = ensureShadowPath(canonicalPath);
  
  const canonicalExists = existsSync(canonicalPath);
  const shadowExists = existsSync(shadowPath);
  
  if (!canonicalExists && !shadowExists) {
    return { identical: true, canonicalExists: false, shadowExists: false };
  }
  
  if (!canonicalExists || !shadowExists) {
    return { 
      identical: false, 
      canonicalExists, 
      shadowExists,
      differences: ['One file missing']
    };
  }
  
  try {
    const canonicalContent = readFileSync(canonicalPath, 'utf8');
    const shadowContent = readFileSync(shadowPath, 'utf8');
    
    const identical = canonicalContent === shadowContent;
    
    if (identical) {
      return { identical: true, canonicalExists: true, shadowExists: true };
    }
    
    // Find differences
    const differences: string[] = [];
    const canonicalLines = canonicalContent.split('\n');
    const shadowLines = shadowContent.split('\n');
    
    const maxLines = Math.max(canonicalLines.length, shadowLines.length);
    
    for (let i = 0; i < maxLines; i++) {
      const canonicalLine = canonicalLines[i] || '';
      const shadowLine = shadowLines[i] || '';
      
      if (canonicalLine !== shadowLine) {
        differences.push(`Line ${i + 1}: canonical="${canonicalLine}" shadow="${shadowLine}"`);
      }
    }
    
    return {
      identical: false,
      canonicalExists: true,
      shadowExists: true,
      differences: differences.slice(0, 10) // Limit to first 10 differences
    };
    
  } catch (error) {
    return {
      identical: false,
      canonicalExists: true,
      shadowExists: true,
      differences: [`Error comparing files: ${error}`]
    };
  }
}



