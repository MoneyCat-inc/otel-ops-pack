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

const ALLOWED_ALGOS = ['rolling', 'pfac', 'benchmark', 'validation'] as const;
const ALLOWED_PROVIDERS = ['cuda', 'cpu'] as const;
const SHA256_PATTERN = /^(?!0{64})[a-f0-9]{64}$/;
const SCHEMA_VERSION_PATTERN = /^v\d+\.\d+$/;

class EvidenceValidator {
  private schema: EvidenceSchema;

  constructor(schemaPath: string) {
    this.schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  }

  validate(evidence: any): ValidationResult {
    const errors: string[] = [];

    if (!this.isObject(evidence)) {
      return {
        valid: false,
        errors: ['Evidence payload must be a JSON object']
      };
    }

    // Check required fields
    for (const field of this.schema.required) {
      if (!(field in evidence)) {
        errors.push(`Missing required field: ${field}`);
      }
    }

    // Validate ok flag
    if (evidence.ok !== undefined && typeof evidence.ok !== 'boolean') {
      errors.push('Field "ok" must be boolean');
    }

    // Validate ISO timestamp
    if (evidence.ts !== undefined) {
      if (typeof evidence.ts !== 'string') {
        errors.push('Field "ts" must be string');
      } else if (Number.isNaN(Date.parse(evidence.ts))) {
        errors.push('Field "ts" must be a valid ISO 8601 timestamp');
      }
    }

    // Validate algorithm selection
    if (evidence.algo !== undefined) {
      if (!ALLOWED_ALGOS.includes(evidence.algo)) {
        errors.push(`Field "algo" must be one of: ${ALLOWED_ALGOS.join(', ')}`);
      }
    }

    // Validate params block
    if (evidence.params !== undefined) {
      if (!this.isObject(evidence.params)) {
        errors.push('Field "params" must be an object');
      } else {
        this.validateParams(evidence.params, errors);
      }
    }

    // Validate timings
    if (evidence.timings !== undefined) {
      if (!this.isObject(evidence.timings)) {
        errors.push('Field "timings" must be an object');
      } else {
        const timings = evidence.timings;
        for (const key of ['gpuMs', 'cpuMs']) {
          if (!EvidenceValidator.isNonNegativeNumber(timings[key])) {
            errors.push(`Field "timings.${key}" must be non-negative number`);
          }
        }
        for (const key of ['h2dMs', 'kernelMs', 'd2hMs', 'accMs']) {
          if (timings[key] !== undefined && !EvidenceValidator.isNonNegativeNumber(timings[key])) {
            errors.push(`Field "timings.${key}" must be non-negative number when present`);
          }
        }
      }
    }

    // Validate env
    if (evidence.env !== undefined) {
      if (!this.isObject(evidence.env)) {
        errors.push('Field "env" must be an object');
      } else {
        const providers = evidence.env.providers;
        if (!Array.isArray(providers)) {
          errors.push('Field "env.providers" must be an array');
        } else {
          if (providers.length === 0) {
            errors.push('Field "env.providers" must include at least one provider');
          }
          const uniqueProviders = new Set(providers);
          if (uniqueProviders.size !== providers.length) {
            errors.push('Field "env.providers" must not contain duplicates');
          }
          for (const provider of providers) {
            if (!ALLOWED_PROVIDERS.includes(provider)) {
              errors.push(`Field "env.providers" contains unsupported provider: ${provider}`);
            }
          }
          if (!providers.some((p: string) => ALLOWED_PROVIDERS.includes(p))) {
            errors.push('Field "env.providers" must contain "cuda" or "cpu"');
          }
        }
        if (evidence.env.cudaVersion !== undefined && typeof evidence.env.cudaVersion !== 'string') {
          errors.push('Field "env.cudaVersion" must be string when present');
        }
        if (evidence.env.wsl_detected !== undefined && typeof evidence.env.wsl_detected !== 'boolean') {
          errors.push('Field "env.wsl_detected" must be boolean when present');
        }
        if (evidence.env.gpu_model !== undefined && typeof evidence.env.gpu_model !== 'string') {
          errors.push('Field "env.gpu_model" must be string when present');
        }
      }
    }

    // Validate run
    if (evidence.run !== undefined) {
      if (!this.isObject(evidence.run)) {
        errors.push('Field "run" must be an object');
      } else {
        if (typeof evidence.run.providerFinal !== 'string' || !ALLOWED_PROVIDERS.includes(evidence.run.providerFinal)) {
          errors.push('Field "run.providerFinal" must be "cuda" or "cpu"');
        }
        if (typeof evidence.run.fellBackToCpu !== 'boolean') {
          errors.push('Field "run.fellBackToCpu" must be boolean');
        }
        if (evidence.run.gpu_fallback !== undefined && typeof evidence.run.gpu_fallback !== 'boolean') {
          errors.push('Field "run.gpu_fallback" must be boolean when present');
        }
        if (evidence.run.note !== undefined && evidence.run.note !== null && typeof evidence.run.note !== 'string') {
          errors.push('Field "run.note" must be string or null when present');
        }
      }
    }

    // Validate parity
    if (evidence.parity !== undefined) {
      if (!this.isObject(evidence.parity)) {
        errors.push('Field "parity" must be an object');
      } else {
        const parity = evidence.parity;
        if (parity.maxAbsDiff !== undefined && !EvidenceValidator.isNonNegativeNumber(parity.maxAbsDiff)) {
          errors.push('Field "parity.maxAbsDiff" must be non-negative number when present');
        }
        if (parity.matches !== undefined && !EvidenceValidator.isNonNegativeInteger(parity.matches)) {
          errors.push('Field "parity.matches" must be non-negative integer when present');
        }
        if (parity.accuracy !== undefined && (typeof parity.accuracy !== 'number' || parity.accuracy < 0 || parity.accuracy > 1)) {
          errors.push('Field "parity.accuracy" must be between 0 and 1 when present');
        }
        if (parity.meanDiff !== undefined && !EvidenceValidator.isNonNegativeNumber(parity.meanDiff)) {
          errors.push('Field "parity.meanDiff" must be non-negative number when present');
        }
        if (parity.stddevMaxDiff !== undefined && !EvidenceValidator.isNonNegativeNumber(parity.stddevMaxDiff)) {
          errors.push('Field "parity.stddevMaxDiff" must be non-negative number when present');
        }
        if (parity.stddevMeanDiff !== undefined && !EvidenceValidator.isNonNegativeNumber(parity.stddevMeanDiff)) {
          errors.push('Field "parity.stddevMeanDiff" must be non-negative number when present');
        }
      }
    }

    // Validate hash fields
    if (evidence.hashes !== undefined) {
      if (!this.isObject(evidence.hashes)) {
        errors.push('Field "hashes" must be an object');
      } else {
        if (evidence.hashes.inputSha256 !== undefined && evidence.hashes.inputSha256 !== null && typeof evidence.hashes.inputSha256 !== 'string') {
          errors.push('Field "hashes.inputSha256" must be string or null when present');
        }
        if (evidence.hashes.outputSha256 !== undefined && evidence.hashes.outputSha256 !== null && typeof evidence.hashes.outputSha256 !== 'string') {
          errors.push('Field "hashes.outputSha256" must be string or null when present');
        }
        if (evidence.hashes.patternsSha256 !== undefined && !EvidenceValidator.matchesPattern(evidence.hashes.patternsSha256, SHA256_PATTERN)) {
          errors.push('Field "hashes.patternsSha256" must be valid SHA256 when present');
        }
      }
    }

    // Validate deployment metadata
    if (evidence.deployment !== undefined) {
      if (!this.isObject(evidence.deployment)) {
        errors.push('Field "deployment" must be an object');
      } else {
        const deployment = evidence.deployment;
        if (deployment.environment !== undefined && !['production', 'staging', 'development'].includes(deployment.environment)) {
          errors.push('Field "deployment.environment" must be one of production, staging, development');
        }
        if (deployment.version !== undefined && typeof deployment.version !== 'string') {
          errors.push('Field "deployment.version" must be string when present');
        }
        if (deployment.deployed_at !== undefined && (typeof deployment.deployed_at !== 'string' || Number.isNaN(Date.parse(deployment.deployed_at)))) {
          errors.push('Field "deployment.deployed_at" must be a valid ISO timestamp when present');
        }
        if (deployment.gitSha !== undefined && !EvidenceValidator.matchesPattern(deployment.gitSha, /^[a-f0-9]{40}$/)) {
          errors.push('Field "deployment.gitSha" must be a 40 character lowercase SHA1 when present');
        }
        if (deployment.releaseTag !== undefined && typeof deployment.releaseTag !== 'string') {
          errors.push('Field "deployment.releaseTag" must be string when present');
        }
        if (deployment.buildId !== undefined && typeof deployment.buildId !== 'string' && !EvidenceValidator.isNonNegativeNumber(deployment.buildId)) {
          errors.push('Field "deployment.buildId" must be string or non-negative number when present');
        }
        if (deployment.pipelineUrl !== undefined && typeof deployment.pipelineUrl !== 'string') {
          errors.push('Field "deployment.pipelineUrl" must be string when present');
        }
        if (deployment.deployedBy !== undefined && typeof deployment.deployedBy !== 'string') {
          errors.push('Field "deployment.deployedBy" must be string when present');
        }
      }
    }

    // Algorithm specific checks with parity focus
    switch (evidence.algo) {
      case 'rolling':
        if (!this.isObject(evidence.parity) || !EvidenceValidator.isNonNegativeNumber(evidence.parity?.maxAbsDiff)) {
          errors.push('Field "parity.maxAbsDiff" must be provided as non-negative number for rolling algorithm');
        }
        if (!this.isObject(evidence.params) || !EvidenceValidator.isPositiveInteger(evidence.params?.window) || !EvidenceValidator.isPositiveInteger(evidence.params?.stride)) {
          errors.push('Fields "params.window" and "params.stride" must be positive integers for rolling algorithm');
        }
        break;
      case 'pfac':
        if (!this.isObject(evidence.parity) || !EvidenceValidator.isNonNegativeInteger(evidence.parity?.matches)) {
          errors.push('Field "parity.matches" must be provided as non-negative integer for PFAC algorithm');
        }
        if (!this.isObject(evidence.parity) || typeof evidence.parity?.accuracy !== 'number' || evidence.parity.accuracy < 0 || evidence.parity.accuracy > 1) {
          errors.push('Field "parity.accuracy" must be provided between 0 and 1 for PFAC algorithm');
        }
        if (!this.isObject(evidence.params) || !EvidenceValidator.isPositiveInteger(evidence.params?.patterns)) {
          errors.push('Field "params.patterns" must be positive integer for PFAC algorithm');
        }
        if (!this.isObject(evidence.hashes) || !EvidenceValidator.matchesPattern(evidence.hashes?.patternsSha256, SHA256_PATTERN)) {
          errors.push('Field "hashes.patternsSha256" must be present and valid SHA256 for PFAC algorithm');
        }
        break;
      case 'benchmark':
        if (!this.isObject(evidence.params) || !EvidenceValidator.isPositiveInteger(evidence.params?.iterations)) {
          errors.push('Field "params.iterations" must be positive integer for benchmark algorithm');
        }
        break;
      case 'validation':
        if (!this.isObject(evidence.params) || !EvidenceValidator.isPositiveInteger(evidence.params?.validation_tests)) {
          errors.push('Field "params.validation_tests" must be positive integer for validation algorithm');
        }
        break;
      default:
        break;
    }

    // Schema version hygiene
    if (this.isObject(evidence.params) && evidence.params.schema_version !== undefined) {
      if (!EvidenceValidator.matchesPattern(evidence.params.schema_version, SCHEMA_VERSION_PATTERN)) {
        errors.push('Field "params.schema_version" must follow format v<major>.<minor> (e.g., v1.1)');
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  private validateParams(params: Record<string, unknown>, errors: string[]) {
    const numericFields: Array<[string, (value: unknown) => boolean, string]> = [
      ['window', EvidenceValidator.isPositiveInteger, 'positive integer'],
      ['stride', EvidenceValidator.isPositiveInteger, 'positive integer'],
      ['patterns', EvidenceValidator.isPositiveInteger, 'positive integer'],
      ['iterations', EvidenceValidator.isPositiveInteger, 'positive integer'],
      ['pattern_batch_size', EvidenceValidator.isPositiveInteger, 'positive integer'],
      ['seed', EvidenceValidator.isNonNegativeInteger, 'non-negative integer'],
      ['validation_tests', EvidenceValidator.isNonNegativeInteger, 'non-negative integer'],
      ['text_length', EvidenceValidator.isPositiveInteger, 'positive integer']
    ];

    for (const [field, validator, description] of numericFields) {
      if (params[field] !== undefined && !validator(params[field])) {
        errors.push(`Field "params.${field}" must be ${description}`);
      }
    }
  }

  private static isNonNegativeNumber(value: unknown): value is number {
    return typeof value === 'number' && Number.isFinite(value) && value >= 0;
  }

  private static isNonNegativeInteger(value: unknown): value is number {
    return Number.isInteger(value as number) && (value as number) >= 0;
  }

  private static isPositiveInteger(value: unknown): value is number {
    return Number.isInteger(value as number) && (value as number) > 0;
  }

  private static matchesPattern(value: unknown, pattern: RegExp): value is string {
    return typeof value === 'string' && pattern.test(value);
  }

  private isObject(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
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
    const schema = JSON.parse(fs.readFileSync(path.resolve('docs/ecrr/schema.json'), 'utf8'));
    console.log('🔎 Required fields:', schema.required.join(', '));
    return;
  }

  const evidenceFile = args[0];
  const schemaPath = path.resolve('docs/ecrr/schema.json');

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
      console.log(`🔎 Algorithm: ${evidence.algo}`);
      if (evidence.timings) {
        console.log(`⚙️  GPU: ${evidence.timings?.gpuMs}ms, CPU: ${evidence.timings?.cpuMs}ms`);
      }
      if (evidence.run) {
        console.log(`🛰️  Provider: ${evidence.run?.providerFinal}`);
        if (evidence.run?.fellBackToCpu) {
          console.log('⚠️  Fell back to CPU');
        }
      }
    } else {
      console.error('❌ Evidence validation failed:');
      result.errors.forEach(error => console.error(`   • ${error}`));
      process.exit(1);
    }
  } catch (error: any) {
    console.error(`❌ Error validating evidence: ${error.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { EvidenceValidator };
