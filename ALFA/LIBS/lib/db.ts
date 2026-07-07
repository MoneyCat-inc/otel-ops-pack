// Resonai Backend - Database Connection and Prisma Client Setup
// Configures database connection with connection pooling and error handling

import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { trace } from '@opentelemetry/api';

// Global Prisma client instance
declare global {
  var __prisma: PrismaClient | undefined;
}

const prismaLog =
  process.env.NODE_ENV === 'development'
    ? (['query', 'info', 'warn', 'error'] as const)
    : (['error'] as const);

// Database configuration — lazy init so `next build` can typecheck without a live DB
const createPrismaClient = (): PrismaClient => {
  const connectionString = process.env['DATABASE_URL'];
  if (!connectionString) {
    throw new Error('DATABASE_URL environment variable is required');
  }

  const adapter = new PrismaPg({ connectionString });

  return new PrismaClient({
    adapter,
    log: [...prismaLog],
    errorFormat: 'pretty',
  });
};

function getPrismaClient(): PrismaClient {
  if (!globalThis.__prisma) {
    globalThis.__prisma = createPrismaClient();
  }
  return globalThis.__prisma;
}

export const db = new Proxy({} as PrismaClient, {
  get(_target, prop) {
    const client = getPrismaClient();
    const value = Reflect.get(client, prop, client);
    return typeof value === 'function' ? value.bind(client) : value;
  },
}) as PrismaClient;

// Database health check
export async function checkDatabaseHealth(): Promise<{
  status: 'healthy' | 'unhealthy';
  latency: number;
  error?: string;
}> {
  trace.getActiveSpan();
  const startTime = Date.now();
  
  try {
    // Simple query to test connection
    await db.$queryRaw`SELECT 1`;
    
    const latency = Date.now() - startTime;
    
    trace.getActiveSpan()?.setAttributes({
      'db.health_check': 'success',
      'db.latency_ms': latency,
    });

    return {
      status: 'healthy',
      latency,
    };

  } catch (error) {
    const latency = Date.now() - startTime;
    const errorMessage = error instanceof Error ? error.message : 'Unknown database error';
    
    trace.getActiveSpan()?.setAttributes({
      'db.health_check': 'failed',
      'db.latency_ms': latency,
      'db.error': errorMessage,
    });

    console.error('Database health check failed:', error);

    return {
      status: 'unhealthy',
      latency,
      error: errorMessage,
    };
  }
}

// Database connection pool monitoring
export async function getDatabaseStats(): Promise<{
  activeConnections: number;
  idleConnections: number;
  totalConnections: number;
}> {
  try {
    // This is a simplified version - actual implementation depends on your database
    // For PostgreSQL, you might query pg_stat_activity
    const result = await db.$queryRaw`
      SELECT 
        count(*) as total_connections,
        count(*) FILTER (WHERE state = 'active') as active_connections,
        count(*) FILTER (WHERE state = 'idle') as idle_connections
      FROM pg_stat_activity 
      WHERE datname = current_database()
    ` as any[];

    const stats = result[0] || { total_connections: 0, active_connections: 0, idle_connections: 0 };

    return {
      activeConnections: Number(stats.active_connections),
      idleConnections: Number(stats.idle_connections),
      totalConnections: Number(stats.total_connections),
    };

  } catch (error) {
    console.error('Failed to get database stats:', error);
    return {
      activeConnections: 0,
      idleConnections: 0,
      totalConnections: 0,
    };
  }
}

// Graceful shutdown
export async function closeDatabaseConnection(): Promise<void> {
  trace.getActiveSpan();
  
  try {
    await db.$disconnect();
    
    trace.getActiveSpan()?.setAttributes({
      'db.disconnect': 'success',
    });

    console.log('Database connection closed gracefully');

  } catch (error) {
    trace.getActiveSpan()?.setAttributes({
      'db.disconnect': 'error',
      'db.error': error instanceof Error ? error.message : 'Unknown error',
    });

    console.error('Error closing database connection:', error);
  }
}

// Transaction wrapper with OTel tracing
export async function withTransaction<T>(
  operation: (tx: PrismaClient) => Promise<T>,
  options?: { timeout?: number; isolationLevel?: 'ReadUncommitted' | 'ReadCommitted' | 'RepeatableRead' | 'Serializable' }
): Promise<T> {
  trace.getActiveSpan();
  
  return db.$transaction(async (tx: any) => {
    const childSpan = trace.getTracer('resonai-backend').startSpan('db.transaction', {
      attributes: {
        'db.transaction.isolation_level': options?.isolationLevel || 'ReadCommitted',
      }
    });

    try {
      const result = await operation(tx);
      childSpan.setStatus({ code: 1 }); // OK
      return result;
    } catch (error) {
      childSpan.setStatus({
        code: 2, // ERROR
        message: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    } finally {
      childSpan.end();
    }
  }, {
    timeout: options?.timeout || 10000, // 10 second timeout
    isolationLevel: options?.isolationLevel,
  });
}

// Query performance monitoring
export function withQueryMonitoring<T>(
  operation: () => Promise<T>,
  queryName: string
): Promise<T> {
  trace.getActiveSpan();
  const startTime = Date.now();
  
  return operation().then(
    (result) => {
      const duration = Date.now() - startTime;
      
      trace.getActiveSpan()?.setAttributes({
        [`db.query.${queryName}.success`]: true,
        [`db.query.${queryName}.duration_ms`]: duration,
      });

      return result;
    },
    (error) => {
      const duration = Date.now() - startTime;
      
      trace.getActiveSpan()?.setAttributes({
        [`db.query.${queryName}.error`]: true,
        [`db.query.${queryName}.duration_ms`]: duration,
        [`db.query.${queryName}.error_message`]: error instanceof Error ? error.message : 'Unknown error',
      });

      throw error;
    }
  );
}

// Database migration utilities
export class DatabaseMigration {
  // Check if migrations are up to date
  static async checkMigrationStatus(): Promise<{
    isUpToDate: boolean;
    pendingMigrations: string[];
    appliedMigrations: string[];
  }> {
    try {
      const migrations = await db.$queryRaw`
        SELECT migration_name, finished_at 
        FROM _prisma_migrations 
        ORDER BY finished_at DESC
      ` as any[];

      const appliedMigrations = migrations
        .filter(m => m.finished_at)
        .map(m => m.migration_name);
      
      const pendingMigrations = migrations
        .filter(m => !m.finished_at)
        .map(m => m.migration_name);

      return {
        isUpToDate: pendingMigrations.length === 0,
        pendingMigrations,
        appliedMigrations,
      };

    } catch (error) {
      console.error('Failed to check migration status:', error);
      return {
        isUpToDate: false,
        pendingMigrations: [],
        appliedMigrations: [],
      };
    }
  }

  // Get database schema version
  static async getSchemaVersion(): Promise<string | null> {
    try {
      const result = await db.$queryRaw`
        SELECT migration_name 
        FROM _prisma_migrations 
        WHERE finished_at IS NOT NULL 
        ORDER BY finished_at DESC 
        LIMIT 1
      ` as any[];

      return result[0]?.migration_name || null;

    } catch (error) {
      console.error('Failed to get schema version:', error);
      return null;
    }
  }
}

// Export the database instance
export default db;
