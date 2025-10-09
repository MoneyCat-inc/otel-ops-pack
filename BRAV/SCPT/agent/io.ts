/**
 * Idempotent IO Helpers for Agent Queue
 * 
 * Provides atomic file operations and JSON merge utilities
 * to prevent race conditions and ensure data consistency.
 */

import { promises as fs } from 'fs';
import { dirname, join } from 'path';
import { createHash } from 'crypto';

export interface JsonUpsertOptions {
  /** Key selector function to determine uniqueness */
  keySelector: (item: any) => string | number;
  /** Whether to preserve existing items (true) or replace them (false) */
  preserveExisting?: boolean;
  /** Maximum number of items to keep (for rotation) */
  maxItems?: number;
}

/**
 * Write file atomically only if content has changed
 * Uses a temporary file + rename for atomicity
 */
export async function writeFileAtomicIfChanged(
  filePath: string,
  content: Buffer | string,
  options: { encoding?: BufferEncoding; mode?: number } = {}
): Promise<{ written: boolean; hash: string }> {
  const { encoding = 'utf8', mode } = options;
  const contentBuffer = Buffer.isBuffer(content) ? content : Buffer.from(content, encoding);
  const newHash = createHash('sha256').update(contentBuffer).digest('hex');

  try {
    // Read existing file and compare hash
    const existingBuffer = await fs.readFile(filePath);
    const existingHash = createHash('sha256').update(existingBuffer).digest('hex');

    if (existingHash === newHash) {
      return { written: false, hash: newHash };
    }
  } catch (error) {
    // File doesn't exist, which is fine - we'll create it
  }

  // Ensure directory exists
  await fs.mkdir(dirname(filePath), { recursive: true });

  // Write to temporary file first
  const tempPath = `${filePath}.tmp.${Date.now()}.${Math.random().toString(36).substr(2, 9)}`;
  
  try {
    await fs.writeFile(tempPath, contentBuffer, { mode });
    
    // For Windows, use copy + unlink instead of rename for better compatibility
    try {
      // Try atomic rename first
      await fs.rename(tempPath, filePath);
    } catch (renameError) {
      // If rename fails (common on Windows), use copy + unlink
      try {
        await fs.copyFile(tempPath, filePath);
        await fs.unlink(tempPath);
      } catch (copyError) {
        // Clean up temp file
        await fs.unlink(tempPath);
        throw copyError;
      }
    }
    
    return { written: true, hash: newHash };
  } catch (error) {
    // Clean up temp file on error
    try {
      await fs.unlink(tempPath);
    } catch {
      // Ignore cleanup errors
    }
    throw error;
  }
}

/**
 * JSON upsert - merge new items into existing JSON array without duplicates
 */
export async function jsonUpsert<T>(
  filePath: string,
  newItems: T[],
  options: JsonUpsertOptions
): Promise<{ added: number; total: number }> {
  const { keySelector, preserveExisting = true, maxItems } = options;

  let existingItems: T[] = [];

  try {
    const content = await fs.readFile(filePath, 'utf8');
    existingItems = JSON.parse(content);
    
    if (!Array.isArray(existingItems)) {
      throw new Error(`Expected array in ${filePath}, got ${typeof existingItems}`);
    }
  } catch (error) {
    // File doesn't exist or is invalid - start with empty array
    existingItems = [];
  }

  // Create a map of existing items by key
  const existingMap = new Map<string | number, T>();
  existingItems.forEach(item => {
    const key = keySelector(item);
    existingMap.set(key, item);
  });

  // Merge new items
  let addedCount = 0;
  newItems.forEach(newItem => {
    const key = keySelector(newItem);
    
    if (!existingMap.has(key)) {
      existingMap.set(key, newItem);
      addedCount++;
    } else if (!preserveExisting) {
      existingMap.set(key, newItem);
    }
  });

  // Convert back to array
  const mergedItems = Array.from(existingMap.values());

  // Apply max items limit if specified
  const finalItems = maxItems && mergedItems.length > maxItems 
    ? mergedItems.slice(-maxItems) 
    : mergedItems;

  // Write back to file atomically
  const content = JSON.stringify(finalItems, null, 2);
  await writeFileAtomicIfChanged(filePath, content);

  return {
    added: addedCount,
    total: finalItems.length
  };
}

/**
 * Read JSON file with fallback to default value
 */
export async function readJsonFile<T>(
  filePath: string,
  defaultValue: T
): Promise<T> {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    return defaultValue;
  }
}

/**
 * Ensure directory exists
 */
export async function ensureDir(dirPath: string): Promise<void> {
  try {
    await fs.mkdir(dirPath, { recursive: true });
  } catch (error) {
    if ((error as any).code !== 'EEXIST') {
      throw error;
    }
  }
}

/**
 * Get file size in bytes
 */
export async function getFileSize(filePath: string): Promise<number> {
  try {
    const stats = await fs.stat(filePath);
    return stats.size;
  } catch (error) {
    return 0;
  }
}

/**
 * Check if file exists
 */
export async function fileExists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath);
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * List files in directory with optional pattern
 */
export async function listFiles(
  dirPath: string,
  pattern?: RegExp
): Promise<string[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const files = entries
      .filter(entry => entry.isFile())
      .map(entry => entry.name);

    if (pattern) {
      return files.filter(file => pattern.test(file));
    }

    return files;
  } catch (error) {
    return [];
  }
}

/**
 * Clean up old files based on age or count
 */
export async function cleanupOldFiles(
  dirPath: string,
  options: {
    maxAge?: number; // milliseconds
    maxCount?: number;
    pattern?: RegExp;
  }
): Promise<number> {
  const { maxAge, maxCount, pattern } = options;
  
  try {
    const files = await listFiles(dirPath, pattern);
    const fileInfos = await Promise.all(
      files.map(async (file) => {
        const filePath = join(dirPath, file);
        const stats = await fs.stat(filePath);
        return {
          name: file,
          path: filePath,
          mtime: stats.mtime.getTime(),
          size: stats.size
        };
      })
    );

    // Sort by modification time (oldest first)
    fileInfos.sort((a, b) => a.mtime - b.mtime);

    let toDelete: string[] = [];
    const now = Date.now();

    // Filter by age
    if (maxAge) {
      toDelete = fileInfos
        .filter(info => now - info.mtime > maxAge)
        .map(info => info.path);
    }

    // Filter by count
    if (maxCount && fileInfos.length > maxCount) {
      const excessCount = fileInfos.length - maxCount;
      const excessFiles = fileInfos
        .slice(0, excessCount)
        .map(info => info.path);
      
      toDelete = [...new Set([...toDelete, ...excessFiles])];
    }

    // Delete files
    let deletedCount = 0;
    for (const filePath of toDelete) {
      try {
        await fs.unlink(filePath);
        deletedCount++;
      } catch (error) {
        console.warn(`Failed to delete ${filePath}:`, error);
      }
    }

    return deletedCount;
  } catch (error) {
    console.warn(`Failed to cleanup files in ${dirPath}:`, error);
    return 0;
  }
}