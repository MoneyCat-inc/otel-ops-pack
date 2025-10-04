#!/usr/bin/env tsx
/**
 * 🐾 BossCat Evidence Validator
 * Validates JSON evidence against the GPU Pattern-Sifter EPIC schema
 */

import * as fs from 'fs';
import * as path from 'path';

// Simple JSON schema validator (no external dependencies)
interface ValidationResult {
  valid: boolean;
  errors: string[];
}

interface EvidenceSchema {
  $schema: string;
  title: string;
  description: string;
  type: string;
  required: string[];
  properties: any;
  additionalProperties: boolean;
}

class EvidenceValidator {
  private schema: EvidenceSchema;

  constructor(schemaPath: string) {
    this.schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  }

  validate(evidence: any): ValidationResult {
    const errors: string[] = [];

    // Check required fields
    for (const field of this.schema.required) {
      if (!(field in evidence)) {
        errors.push(`Missing required field: ${field}`);
      }
    }

    // Validate basic types
    if (evidence.ok !== undefined && typeof evidence.ok !== 'boolean') {
      errors.push('Field "ok" must be boolean');
    }

    if (evidence.ts !== undefined && typeof evidence.ts !== 'string') {
      errors.push('Field "ts" must be string');
    }

    if (evidence.algo !== undefined && !this.schema.properties.algo.enum.includes(evidence.algo)) {
      errors.push(`Field "algo" must be one of: ${this.schema.properties.algo.enum.join(', ')}`);
    }

    // Validate timings
    if (evidence.timings) {
      if (typeof evidence.timings.gpuMs !== 'number' || evidence.timings.gpuMs < 0) {
        errors.push('Field "timings.gpuMs" must be non-negative number');
      }
      if (typeof evidence.timings.cpuMs !== 'number' || evidence.timings.cpuMs < 0) {
        errors.push('Field "timings.cpuMs" must be non-negative number');
      }
    }

    // Validate env
    if (evidence.env) {
      if (!Array.isArray(evidence.env.providers)) {
        errors.push('Field "env.providers" must be array');
      } else if (!evidence.env.providers.includes('cuda') && !evidence.env.providers.includes('cpu')) {
        errors.push('Field "env.providers" must contain "cuda" or "cpu"');
      }
    }

    // Validate run
    if (evidence.run) {
      if (typeof evidence.run.providerFinal !== 'string' || 
          !['cuda', 'cpu'].includes(evidence.run.providerFinal)) {
        errors.push('Field "run.providerFinal" must be "cuda" or "cpu"');
      }
      if (typeof evidence.run.fellBackToCpu !== 'boolean') {
        errors.push('Field "run.fellBackToCpu" must be boolean');
      }
    }

    // Validate parity for rolling algorithm
    if (evidence.algo === 'rolling' && evidence.parity) {
      if (typeof evidence.parity.maxAbsDiff !== 'number' || evidence.parity.maxAbsDiff < 0) {
        errors.push('Field "parity.maxAbsDiff" must be non-negative number for rolling algorithm');
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('🐾 Usage: validate_evidence.ts <evidence-file.json>');
    console.error('   or: validate_evidence.ts --schema-only');
    process.exit(1);
  }

  if (args[0] === '--schema-only') {
    console.log('✅ BossCat Evidence Schema loaded successfully');
    console.log('📋 Required fields:', JSON.parse(fs.readFileSync('docs/ecrr/schema.json', 'utf8')).required.join(', '));
    return;
  }

  const evidenceFile = args[0];
  const schemaPath = 'docs/ecrr/schema.json';

  if (!fs.existsSync(evidenceFile)) {
    console.error(`❌ Evidence file not found: ${evidenceFile}`);
    process.exit(1);
  }

  if (!fs.existsSync(schemaPath)) {
    console.error(`❌ Schema file not found: ${schemaPath}`);
    process.exit(1);
  }

  try {
    const validator = new EvidenceValidator(schemaPath);
    const evidence = JSON.parse(fs.readFileSync(evidenceFile, 'utf8'));
    const result = validator.validate(evidence);

    if (result.valid) {
      console.log('✅ Evidence validation passed');
      console.log(`🐾 Algorithm: ${evidence.algo}`);
      console.log(`⚡ GPU: ${evidence.timings?.gpuMs}ms, CPU: ${evidence.timings?.cpuMs}ms`);
      console.log(`🎯 Provider: ${evidence.run?.providerFinal}`);
      if (evidence.run?.fellBackToCpu) {
        console.log('⚠️  Fell back to CPU');
      }
    } else {
      console.error('❌ Evidence validation failed:');
      result.errors.forEach(error => console.error(`   ${error}`));
      process.exit(1);
    }
  } catch (error) {
    console.error(`❌ Error validating evidence: ${error.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { EvidenceValidator };
