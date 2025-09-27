#!/usr/bin/env node
/**
 * Simple Telemetry Test
 * Sends basic telemetry data to verify the pipeline works
 */

// Simple test without complex OTel setup
import * as https from 'https';
import * as http from 'http';

interface OTLPTrace {
  resourceSpans: Array<{
    resource: {
      attributes: Array<{
        key: string;
        value: { stringValue: string };
      }>;
    };
    scopeSpans: Array<{
      scope: {
        name: string;
        version: string;
      };
      spans: Array<{
        traceId: string;
        spanId: string;
        name: string;
        startTimeUnixNano: string;
        endTimeUnixNano: string;
        attributes: Array<{
          key: string;
          value: { stringValue: string };
        }>;
        status: {
          code: number;
        };
      }>;
    }>;
  }>;
}

function generateTraceId(): string {
  return Array.from({ length: 32 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
}

function generateSpanId(): string {
  return Array.from({ length: 16 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
}

function createTestTrace(): OTLPTrace {
  const now = Date.now();
  const traceId = generateTraceId();
  const spanId = generateSpanId();
  
  return {
    resourceSpans: [{
      resource: {
        attributes: [
          { key: "service.name", value: { stringValue: "resonai-agent-test" } },
          { key: "service.version", value: { stringValue: "1.0.0" } }
        ]
      },
      scopeSpans: [{
        scope: {
          name: "resonai.agent",
          version: "1.0.0"
        },
        spans: [{
          traceId: traceId,
          spanId: spanId,
          name: "agent.queue.tick",
          startTimeUnixNano: (now * 1000000).toString(),
          endTimeUnixNano: ((now + 100) * 1000000).toString(),
          attributes: [
            { key: "queue.depth", value: { stringValue: "3" } },
            { key: "agent.max_jobs", value: { stringValue: "2" } },
            { key: "agent.lock_present", value: { stringValue: "false" } }
          ],
          status: {
            code: 1 // OK
          }
        }]
      }]
    }]
  };
}

function sendOTLPTrace(trace: OTLPTrace): Promise<void> {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(trace);
    
    const options = {
      hostname: 'localhost',
      port: 4318,
      path: '/v1/traces',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = http.request(options, (res) => {
      console.log(`✅ OTLP trace sent - Status: ${res.statusCode}`);
      resolve();
    });

    req.on('error', (err) => {
      console.error(`❌ OTLP trace failed: ${err.message}`);
      reject(err);
    });

    req.write(data);
    req.end();
  });
}

async function main() {
  console.log('🧪 Sending test telemetry data...');
  
  try {
    const trace = createTestTrace();
    await sendOTLPTrace(trace);
    
    console.log('✅ Test telemetry sent successfully!');
    console.log('📊 Check SigNoz UI at http://localhost:8080 to see the trace');
    console.log(`🔍 Look for service: resonai-agent-test`);
    console.log(`🔍 Look for span: agent.queue.tick`);
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  }
}

// Run the test
main().catch(console.error);
