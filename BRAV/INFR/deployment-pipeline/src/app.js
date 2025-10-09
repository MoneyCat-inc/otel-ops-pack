/**
 * Deployment Pipeline API - Minimal REST Service
 * Tetragrammaton YHWH Architecture Implementation
 * 
 * YOD (Foundation) - Core service logic and routing
 * HE (Interface) - HTTP API endpoints and request handling
 * VAV (Validation) - Input validation and error handling
 * HE (Integration) - Service orchestration and middleware integration
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

// YOD (Foundation) - Core service configuration
const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// HE (Interface) - Middleware configuration
app.use(helmet()); // Security headers
app.use(cors()); // CORS support
app.use(morgan('combined')); // Request logging
app.use(express.json()); // JSON body parsing
app.use(express.urlencoded({ extended: true })); // URL-encoded body parsing

// VAV (Validation) - Input validation middleware
const validateRequest = (req, res, next) => {
  try {
    // Basic request validation
    if (req.method === 'POST' && !req.body) {
      return res.status(400).json({ 
        error: 'Invalid request body',
        code: 'INVALID_BODY'
      });
    }
    next();
  } catch (error) {
    res.status(500).json({ 
      error: 'Validation error',
      code: 'VALIDATION_ERROR'
    });
  }
};

// Apply validation middleware
app.use(validateRequest);

// YOD (Foundation) - Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'deployment-pipeline-api',
    version: '1.0.0',
    environment: NODE_ENV,
    uptime: process.uptime()
  });
});

// HE (Interface) - Main API endpoints
app.get('/api/v1/status', (req, res) => {
  res.status(200).json({
    message: 'Deployment Pipeline API is operational',
    timestamp: new Date().toISOString(),
    endpoints: [
      'GET /health',
      'GET /api/v1/status',
      'POST /api/v1/echo',
      'GET /api/v1/metrics'
    ]
  });
});

// HE (Interface) - Echo endpoint for testing
app.post('/api/v1/echo', (req, res) => {
  const { message } = req.body;
  
  // VAV (Validation) - Input validation
  if (!message) {
    return res.status(400).json({
      error: 'Message field is required',
      code: 'MISSING_MESSAGE'
    });
  }

  // YOD (Foundation) - Core processing logic
  const response = {
    echo: message,
    timestamp: new Date().toISOString(),
    processed: true,
    length: message.length
  };

  res.status(200).json(response);
});

// HE (Integration) - Metrics endpoint for monitoring
app.get('/api/v1/metrics', (req, res) => {
  const metrics = {
    timestamp: new Date().toISOString(),
    service: 'deployment-pipeline-api',
    version: '1.0.0',
    environment: NODE_ENV,
    uptime: process.uptime(),
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
    },
    tetragrammaton: {
      architecture: 'YHWH (Yod-He-Vav-He)',
      yod_foundation: 'Core service logic implemented',
      he_interface: 'HTTP API endpoints operational',
      vav_validation: 'Input validation active',
      he_integration: 'Service orchestration complete'
    }
  };

  res.status(200).json(metrics);
});

// VAV (Validation) - Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(500).json({
    error: 'Internal server error',
    code: 'INTERNAL_ERROR',
    timestamp: new Date().toISOString()
  });
});

// VAV (Validation) - 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    code: 'NOT_FOUND',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

// HE (Integration) - Server startup orchestration
const startServer = () => {
  const server = app.listen(PORT, () => {
    console.log(`🚀 Deployment Pipeline API started on port ${PORT}`);
    console.log(`📊 Environment: ${NODE_ENV}`);
    console.log(`🐾 Tetragrammaton Architecture: YHWH (Yod-He-Vav-He)`);
    console.log(`✅ YOD Foundation: Core service logic operational`);
    console.log(`✅ HE Interface: HTTP API endpoints ready`);
    console.log(`✅ VAV Validation: Input validation active`);
    console.log(`✅ HE Integration: Service orchestration complete`);
    console.log(`🌐 Health check: http://localhost:${PORT}/health`);
    console.log(`📈 Metrics: http://localhost:${PORT}/api/v1/metrics`);
  });

  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('🛑 SIGTERM received, shutting down gracefully');
    server.close(() => {
      console.log('✅ Server closed');
      process.exit(0);
    });
  });

  process.on('SIGINT', () => {
    console.log('🛑 SIGINT received, shutting down gracefully');
    server.close(() => {
      console.log('✅ Server closed');
      process.exit(0);
    });
  });

  return server;
};

// Start server if this file is run directly
if (require.main === module) {
  startServer();
}

module.exports = { app, startServer };
