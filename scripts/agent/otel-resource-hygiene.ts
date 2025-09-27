// OTel Resource Hygiene - Stable Resource Attributes
// ECRR Compliance: Examine → Clean → Report → Role

import { Resource } from '@opentelemetry/resources';
import { envDetector, hostDetector, processDetector } from '@opentelemetry/resources';
import { 
  SEMRESATTRS_SERVICE_NAME, 
  SEMRESATTRS_SERVICE_VERSION, 
  SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
  SEMRESATTRS_SERVICE_INSTANCE_ID,
  SEMRESATTRS_HOST_NAME,
  SEMRESATTRS_OS_TYPE,
  SEMRESATTRS_OS_VERSION,
  SEMRESATTRS_PROCESS_PID,
  SEMRESATTRS_PROCESS_COMMAND,
  SEMRESATTRS_PROCESS_COMMAND_LINE,
  SEMRESATTRS_PROCESS_RUNTIME_NAME,
  SEMRESATTRS_PROCESS_RUNTIME_VERSION
} from '@opentelemetry/semantic-conventions';

/**
 * Create a stable resource with proper attributes for observability
 */
export async function createStableResource(): Promise<Resource> {
  // Base resource with service information
  const baseResource = new Resource({
    [SEMRESATTRS_SERVICE_NAME]: 'resonai-agent',
    [SEMRESATTRS_SERVICE_VERSION]: process.env.GIT_COMMIT_SHA || 'dev',
    [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'dev',
    [SEMRESATTRS_SERVICE_INSTANCE_ID]: process.env.SERVICE_INSTANCE_ID || `agent-${process.pid}`,
  });

  // Merge with detected resources
  const envResource = await envDetector.detect();
  const hostResource = await hostDetector.detect();
  const processResource = await processDetector.detect();

  // Combine all resources
  const resource = baseResource
    .merge(envResource)
    .merge(hostResource)
    .merge(processResource);

  // Add custom attributes for better observability
  const customAttributes = {
    'agent.version': process.env.AGENT_VERSION || '1.0.0',
    'agent.build': process.env.BUILD_NUMBER || 'local',
    'agent.region': process.env.AWS_REGION || 'local',
    'agent.zone': process.env.AWS_AVAILABILITY_ZONE || 'local',
    'agent.cluster': process.env.KUBERNETES_CLUSTER || 'local',
    'agent.namespace': process.env.KUBERNETES_NAMESPACE || 'default',
    'agent.pod': process.env.KUBERNETES_POD_NAME || 'local',
    'agent.node': process.env.KUBERNETES_NODE_NAME || 'local',
  };

  // Filter out undefined values
  const filteredAttributes = Object.fromEntries(
    Object.entries(customAttributes).filter(([_, value]) => value !== undefined)
  );

  return resource.merge(new Resource(filteredAttributes));
}

/**
 * Get resource attributes as a plain object
 */
export function getResourceAttributes(resource: Resource): Record<string, string> {
  const attributes: Record<string, string> = {};
  
  for (const [key, value] of resource.attributes) {
    if (typeof value === 'string') {
      attributes[key] = value;
    } else if (typeof value === 'number' || typeof value === 'boolean') {
      attributes[key] = String(value);
    }
  }
  
  return attributes;
}

/**
 * Validate resource attributes for completeness
 */
export function validateResource(resource: Resource): {
  isValid: boolean;
  missing: string[];
  warnings: string[];
} {
  const required = [
    SEMRESATTRS_SERVICE_NAME,
    SEMRESATTRS_SERVICE_VERSION,
    SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
  ];

  const recommended = [
    SEMRESATTRS_HOST_NAME,
    SEMRESATTRS_OS_TYPE,
    SEMRESATTRS_PROCESS_PID,
    SEMRESATTRS_PROCESS_RUNTIME_NAME,
    SEMRESATTRS_PROCESS_RUNTIME_VERSION,
  ];

  const missing: string[] = [];
  const warnings: string[] = [];

  // Check required attributes
  for (const attr of required) {
    if (!resource.attributes[attr]) {
      missing.push(attr);
    }
  }

  // Check recommended attributes
  for (const attr of recommended) {
    if (!resource.attributes[attr]) {
      warnings.push(attr);
    }
  }

  // Check for common issues
  if (resource.attributes[SEMRESATTRS_SERVICE_VERSION] === 'dev') {
    warnings.push('Service version is "dev" - consider using git commit SHA');
  }

  if (resource.attributes[SEMRESATTRS_DEPLOYMENT_ENVIRONMENT] === 'dev') {
    warnings.push('Deployment environment is "dev" - consider using proper environment name');
  }

  return {
    isValid: missing.length === 0,
    missing,
    warnings,
  };
}

/**
 * Log resource information for debugging
 */
export function logResourceInfo(resource: Resource, logger: { info: (msg: string, meta?: any) => void }): void {
  const attributes = getResourceAttributes(resource);
  const validation = validateResource(resource);

  logger.info('OTel resource configured', {
    attributes,
    validation,
    resourceCount: Object.keys(attributes).length,
  });

  if (validation.warnings.length > 0) {
    logger.info('OTel resource warnings', {
      warnings: validation.warnings,
    });
  }

  if (!validation.isValid) {
    logger.info('OTel resource validation failed', {
      missing: validation.missing,
    });
  }
}

/**
 * Create resource for different environments
 */
export async function createEnvironmentResource(environment: string): Promise<Resource> {
  const baseResource = await createStableResource();
  
  // Add environment-specific attributes
  const envAttributes = {
    [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: environment,
    'environment.type': environment,
    'environment.tier': getEnvironmentTier(environment),
  };

  return baseResource.merge(new Resource(envAttributes));
}

/**
 * Get environment tier based on environment name
 */
function getEnvironmentTier(environment: string): string {
  switch (environment.toLowerCase()) {
    case 'production':
    case 'prod':
      return 'production';
    case 'staging':
    case 'stage':
      return 'staging';
    case 'development':
    case 'dev':
      return 'development';
    case 'testing':
    case 'test':
      return 'testing';
    default:
      return 'unknown';
  }
}

/**
 * Example usage
 */
export async function exampleUsage(): Promise<void> {
  try {
    // Create stable resource
    const resource = await createStableResource();
    
    // Log resource information
    console.log('Resource attributes:', getResourceAttributes(resource));
    
    // Validate resource
    const validation = validateResource(resource);
    console.log('Resource validation:', validation);
    
    // Use resource with OpenTelemetry
    // const meterProvider = new MeterProvider({ resource });
    // const tracerProvider = new TracerProvider({ resource });
    
  } catch (error) {
    console.error('Failed to create OTel resource:', error);
  }
}

// Export types for TypeScript
export interface ResourceValidation {
  isValid: boolean;
  missing: string[];
  warnings: string[];
}

export interface ResourceInfo {
  attributes: Record<string, string>;
  validation: ResourceValidation;
  resourceCount: number;
}
