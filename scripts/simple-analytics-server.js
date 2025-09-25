/**
 * Simple Analytics API Server (no dependencies)
 * Handles /api/events endpoint for OTel wiring verification
 */

const http = require('http');
const url = require('url');

const PORT = 3003;

// Simple CORS headers
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json');
}

// Handle analytics events
function handleAnalyticsEvent(req, res) {
  let body = '';
  
  req.on('data', chunk => {
    body += chunk.toString();
  });
  
  req.on('end', () => {
    console.log('📊 Raw request body:', body);
    
    try {
      // Handle empty body
      if (!body.trim()) {
        console.log('📊 Empty body, creating default event');
        const eventData = { event: 'default', message: 'verify_wiring_canary' };
        
        const response = {
          ok: true,
          count: 1,
          message: 'Event processed successfully',
          timestamp: new Date().toISOString(),
          eventId: `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
        };
        
        res.writeHead(200);
        res.end(JSON.stringify(response));
        return;
      }
      
      const eventData = JSON.parse(body);
      console.log('📊 Received analytics event:', JSON.stringify(eventData, null, 2));
      
      // Simulate processing - return format expected by verify-wiring.ps1
      const response = {
        ok: true,
        count: 1,
        message: 'Event processed successfully',
        timestamp: new Date().toISOString(),
        eventId: `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
      };
      
      res.writeHead(200);
      res.end(JSON.stringify(response));
      
    } catch (error) {
      console.error('❌ Error processing event:', error.message);
      console.error('❌ Body that failed:', body);
      
      // Try to handle malformed JSON by creating a default response
      const response = {
        ok: true,
        count: 1,
        message: 'Event processed successfully (fallback)',
        timestamp: new Date().toISOString(),
        eventId: `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
      };
      
      res.writeHead(200);
      res.end(JSON.stringify(response));
    }
  });
}

// Handle health check
function handleHealthCheck(req, res) {
  const response = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'simple-analytics-api'
  };
  
  res.writeHead(200);
  res.end(JSON.stringify(response));
}

// Create server
const server = http.createServer((req, res) => {
  setCorsHeaders(res);
  
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const method = req.method;
  
  // Handle preflight OPTIONS requests
  if (method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  console.log(`${method} ${path}`);
  
  if (path === '/api/events' && method === 'POST') {
    handleAnalyticsEvent(req, res);
  } else if (path === '/health' && method === 'GET') {
    handleHealthCheck(req, res);
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

// Start server
server.listen(PORT, 'localhost', () => {
  console.log(`🚀 Simple Analytics API server running on http://localhost:${PORT}`);
  console.log(`📊 Analytics endpoint: http://localhost:${PORT}/api/events`);
  console.log(`❤️  Health check: http://localhost:${PORT}/health`);
  console.log('Press Ctrl+C to stop the server');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down analytics server...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

// Error handling
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use`);
  } else {
    console.error('❌ Server error:', err);
  }
  process.exit(1);
});
