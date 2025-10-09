#!/usr/bin/env node
/**
 * BossCat ECRR Evidence Validator
 * Cat Nap Control Room - Resonai [OTel] - GPU Pattern-Sifter
 * 
 * Validates JSON evidence files against the BossCat schema using AJV
 */

import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import * as fs from 'fs';
import * as path from 'path';

interface ValidationResult {
  valid: boolean;
  errors: string[];
  file: string;
}

class EvidenceValidator {
  private ajv: Ajv.Ajv;
  private schema: any;

  constructor() {
    this.ajv = new Ajv({ allErrors: true, verbose: true });
    addFormats(this.ajv);
    this.loadSchema();
  }

  private loadSchema(): void {
    const schemaPath = path.join(__dirname, '../../docs/ecrr/schema.json');
    try {
      const schemaContent = fs.readFileSync(schemaPath, 'utf-8');
      this.schema = JSON.parse(schemaContent);
    } catch (error) {
      console.error(`Failed to load schema from ${schemaPath}:`, error);
      process.exit(1);
    }
  }

  private validateFile(filePath: string): ValidationResult {
    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      const data = JSON.parse(content);
      
      const validate = this.ajv.compile(this.schema);
      const valid = validate(data);
      
      const errors = valid ? [] : (validate.errors || []).map(err => 
        `${err.instancePath || 'root'}: ${err.message}`
      );

      return {
        valid: !!valid,
        errors,
        file: path.basename(filePath)
      };
    } catch (error) {
      return {
        valid: false,
        errors: [`Parse error: ${error}`],
        file: path.basename(filePath)
      };
    }
  }

  public validateDirectory(dirPath: string, maxFiles: number = 10): ValidationResult[] {
    const results: ValidationResult[] = [];
    
    try {
      const files = fs.readdirSync(dirPath)
        .filter(file => file.endsWith('.json'))
        .sort((a, b) => {
          const statA = fs.statSync(path.join(dirPath, a));
          const statB = fs.statSync(path.join(dirPath, b));
          return statB.mtime.getTime() - statA.mtime.getTime(); // Most recent first
        })
        .slice(0, maxFiles);

      for (const file of files) {
        const filePath = path.join(dirPath, file);
        const result = this.validateFile(filePath);
        results.push(result);
      }
    } catch (error) {
      console.error(`Failed to read directory ${dirPath}:`, error);
      process.exit(1);
    }

    return results;
  }

  public printResults(results: ValidationResult[]): void {
    const validCount = results.filter(r => r.valid).length;
    const totalCount = results.length;

    console.log(`\n🔍 BossCat Evidence Validation Results`);
    console.log(`📊 ${validCount}/${totalCount} files valid\n`);

    for (const result of results) {
      const status = result.valid ? '✅' : '❌';
      console.log(`${status} ${result.file}`);
      
      if (!result.valid) {
        for (const error of result.errors) {
          console.log(`   └─ ${error}`);
        }
      }
    }

    if (validCount < totalCount) {
      console.log(`\n❌ Validation failed: ${totalCount - validCount} files invalid`);
      process.exit(1);
    } else {
      console.log(`\n✅ All evidence files valid`);
    }
  }
}

function main(): void {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('Usage: tsx scripts/ecrr/validate_evidence.ts <directory> [maxFiles]');
    console.log('Example: tsx scripts/ecrr/validate_evidence.ts docs/ecrr/ECRR_REPORTS/ 10');
    process.exit(1);
  }

  const dirPath = args[0];
  const maxFiles = args[1] ? parseInt(args[1], 10) : 10;

  if (!fs.existsSync(dirPath)) {
    console.error(`Directory not found: ${dirPath}`);
    process.exit(1);
  }

  const validator = new EvidenceValidator();
  const results = validator.validateDirectory(dirPath, maxFiles);
  validator.printResults(results);
}

main();
