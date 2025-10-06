/**
 * Deployment Pipeline API Test Suite
 * Tetragrammaton YHWH Architecture Testing
 * 
 * Tests validate all four elements of the Tetragrammaton structure:
 * YOD (Foundation) - Core service logic
 * HE (Interface) - API endpoints and request handling
 * VAV (Validation) - Input validation and error handling
 * HE (Integration) - Service orchestration and middleware
 */

const request = require('supertest');
const { app } = require('../src/app');

describe('Deployment Pipeline API - Tetragrammaton Tests', () => {
  
  describe('YOD (Foundation) - Core Service Logic', () => {
    
    test('should start server and respond to health check', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);
      
      expect(response.body).toMatchObject({
        status: 'healthy',
        service: 'deployment-pipeline-api',
        version: '1.0.0'
      });
      expect(response.body.timestamp).toBeDefined();
      expect(response.body.uptime).toBeDefined();
    });

    test('should return service metrics', async () => {
      const response = await request(app)
        .get('/api/v1/metrics')
        .expect(200);
      
      expect(response.body).toMatchObject({
        service: 'deployment-pipeline-api',
        version: '1.0.0',
        uptime: expect.any(Number)
      });
      expect(response.body.memory).toBeDefined();
      expect(response.body.tetragrammaton).toBeDefined();
    });

  });

  describe('HE (Interface) - API Endpoints', () => {
    
    test('should return API status', async () => {
      const response = await request(app)
        .get('/api/v1/status')
        .expect(200);
      
      expect(response.body).toMatchObject({
        message: 'Deployment Pipeline API is operational',
        endpoints: expect.arrayContaining([
          'GET /health',
          'GET /api/v1/status',
          'POST /api/v1/echo',
          'GET /api/v1/metrics'
        ])
      });
    });

    test('should handle echo endpoint with valid input', async () => {
      const testMessage = 'Hello, Tetragrammaton!';
      const response = await request(app)
        .post('/api/v1/echo')
        .send({ message: testMessage })
        .expect(200);
      
      expect(response.body).toMatchObject({
        echo: testMessage,
        processed: true,
        length: testMessage.length
      });
      expect(response.body.timestamp).toBeDefined();
    });

  });

  describe('VAV (Validation) - Input Validation and Error Handling', () => {
    
    test('should reject echo request without message', async () => {
      const response = await request(app)
        .post('/api/v1/echo')
        .send({})
        .expect(400);
      
      expect(response.body).toMatchObject({
        error: 'Message field is required',
        code: 'MISSING_MESSAGE'
      });
    });

    test('should reject echo request with empty message', async () => {
      const response = await request(app)
        .post('/api/v1/echo')
        .send({ message: '' })
        .expect(400);
      
      expect(response.body).toMatchObject({
        error: 'Message field is required',
        code: 'MISSING_MESSAGE'
      });
    });

    test('should handle 404 for unknown endpoints', async () => {
      const response = await request(app)
        .get('/api/v1/unknown')
        .expect(404);
      
      expect(response.body).toMatchObject({
        error: 'Endpoint not found',
        code: 'NOT_FOUND',
        path: '/api/v1/unknown'
      });
    });

  });

  describe('HE (Integration) - Service Orchestration', () => {
    
    test('should validate Tetragrammaton architecture in metrics', async () => {
      const response = await request(app)
        .get('/api/v1/metrics')
        .expect(200);
      
      expect(response.body.tetragrammaton).toMatchObject({
        architecture: 'YHWH (Yod-He-Vav-He)',
        yod_foundation: 'Core service logic implemented',
        he_interface: 'HTTP API endpoints operational',
        vav_validation: 'Input validation active',
        he_integration: 'Service orchestration complete'
      });
    });

    test('should handle concurrent requests', async () => {
      const requests = Array(5).fill().map(() =>
        request(app).get('/health')
      );
      
      const responses = await Promise.all(requests);
      
      responses.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.body.status).toBe('healthy');
      });
    });

    test('should maintain service state across requests', async () => {
      // First request
      const response1 = await request(app)
        .get('/health')
        .expect(200);
      
      // Wait a moment
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Second request
      const response2 = await request(app)
        .get('/health')
        .expect(200);
      
      // Uptime should be increasing
      expect(response2.body.uptime).toBeGreaterThan(response1.body.uptime);
    });

  });

  describe('End-to-End Integration Tests', () => {
    
    test('should complete full request cycle', async () => {
      // Health check
      await request(app)
        .get('/health')
        .expect(200);
      
      // Status check
      await request(app)
        .get('/api/v1/status')
        .expect(200);
      
      // Echo test
      const echoResponse = await request(app)
        .post('/api/v1/echo')
        .send({ message: 'Deployment Pipeline Test' })
        .expect(200);
      
      expect(echoResponse.body.echo).toBe('Deployment Pipeline Test');
      
      // Metrics check
      const metricsResponse = await request(app)
        .get('/api/v1/metrics')
        .expect(200);
      
      expect(metricsResponse.body.tetragrammaton).toBeDefined();
    });

    test('should handle error scenarios gracefully', async () => {
      // Invalid endpoint
      await request(app)
        .get('/invalid')
        .expect(404);
      
      // Invalid method
      await request(app)
        .put('/health')
        .expect(404);
    });

  });

});
