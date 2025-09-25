/**
 * Mock Resonai Analytics API Server
 * Simple Express server to handle /api/events endpoint for OTel wiring verification
 */

const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3003;

// Middleware
app.use(cors());
app.use(express.json());

// Mock analytics endpoint
app.post('/api/events', (req, res) => {
  console.log('📊 Received analytics event:', JSON.stringify(req.body, null, 2));
  
  // Simulate processing delay
  setTimeout(() => {
    res.status(200).json({
      success: true,
      message: 'Event processed successfully',
      timestamp: new Date().toISOString(),
      eventId: `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    });
  }, 100);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'mock-resonai-analytics'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Mock Resonai Analytics API server running on http://localhost:${PORT}`);
  console.log(`📊 Analytics endpoint: http://localhost:${PORT}/api/events`);
  console.log(`❤️  Health check: http://localhost:${PORT}/health`);
  console.log('Press Ctrl+C to stop the server');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down mock Resonai server...');
  process.exit(0);
});
