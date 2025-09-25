import fs from "fs";
import http from "http";
import WebSocket, { WebSocketServer } from "ws";

const PORT = 8080;
const JSON_PATH = "./errors.json";
const SIGNOZ_ENDPOINT = "http://localhost:14318/v1/metrics";

const server = http.createServer();
const wss = new WebSocketServer({ server });

async function emitSigNozMetrics(data) {
  try {
    const parsed = JSON.parse(data);
    const stats = parsed.statistics;
    
    // Create metrics payload
    const metricsPayload = {
      resourceMetrics: [{
        resource: {
          attributes: [
            { key: "service.name", value: { stringValue: "iona-error-system" } },
            { key: "service.version", value: { stringValue: "1.1" } }
          ]
        },
        scopeMetrics: [{
          scope: { name: "iona-error-metrics", version: "1.1" },
          metrics: [
            {
              name: "iona.errors.total",
              description: "Total IONA error entries",
              unit: "1",
              gauge: {
                dataPoints: [{
                  timeUnixNano: Date.now() * 1000000,
                  asDouble: stats.total,
                  attributes: [
                    { key: "metric.type", value: { stringValue: "counter" } }
                  ]
                }]
              }
            },
            {
              name: "iona.errors.resolution_rate",
              description: "IONA error resolution rate percentage",
              unit: "1",
              gauge: {
                dataPoints: [{
                  timeUnixNano: Date.now() * 1000000,
                  asDouble: stats.resolutionRate,
                  attributes: [
                    { key: "metric.type", value: { stringValue: "percentage" } }
                  ]
                }]
              }
            },
            {
              name: "iona.errors.open_count",
              description: "Open IONA error entries",
              unit: "1",
              gauge: {
                dataPoints: [{
                  timeUnixNano: Date.now() * 1000000,
                  asDouble: stats.open,
                  attributes: [
                    { key: "metric.type", value: { stringValue: "gauge" } }
                  ]
                }]
              }
            }
          ]
        }]
      }]
    };

    // Send to SigNoz
    const response = await fetch(SIGNOZ_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(metricsPayload)
    });

    if (response.ok) {
      console.log(`[SigNoz] Metrics emitted successfully`);
    } else {
      console.error(`[SigNoz] Failed to emit metrics: ${response.status}`);
    }
  } catch (err) {
    console.error("[SigNoz] Error emitting metrics:", err);
  }
}

async function emitSigNozTraces(data) {
  try {
    const parsed = JSON.parse(data);
    const entries = parsed.entries;
    
    // Emit trace for each error entry
    for (const entry of entries) {
      const traceId = generateTraceId();
      const spanId = generateSpanId();
      
      const tracesPayload = {
        resourceSpans: [{
          resource: {
            attributes: [
              { key: "service.name", value: { stringValue: "iona-error-system" } },
              { key: "service.version", value: { stringValue: "1.1" } },
              { key: "deployment.environment", value: { stringValue: "local" } }
            ]
          },
          scopeSpans: [{
            scope: { name: "iona-error-tracing", version: "1.1" },
            spans: [{
              traceId: traceId,
              spanId: spanId,
              parentSpanId: "",
              name: `iona.error.${entry.isResolved ? 'resolved' : 'open'}`,
              kind: 1, // INTERNAL
              startTimeUnixNano: Date.now() * 1000000,
              endTimeUnixNano: Date.now() * 1000000 + 1000000, // 1ms duration
              attributes: [
                { key: "error.id", value: { stringValue: entry.id } },
                { key: "error.type", value: { stringValue: entry.type } },
                { key: "error.context", value: { stringValue: entry.context } },
                { key: "error.impact", value: { stringValue: entry.impact } },
                { key: "error.resolution", value: { stringValue: entry.resolution } },
                { key: "error.status", value: { stringValue: entry.status } },
                { key: "error.evidence", value: { stringValue: entry.evidence } },
                { key: "error.lifecycle_stage", value: { stringValue: entry.isResolved ? "resolved" : "open" } }
              ],
              status: { code: 1 } // OK
            }]
          }]
        }]
      };

      // Send to SigNoz traces endpoint
      const tracesResponse = await fetch("http://localhost:14318/v1/traces", {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(tracesPayload)
      });

      if (tracesResponse.ok) {
        console.log(`[SigNoz] Trace emitted for error ${entry.id}`);
      } else {
        console.error(`[SigNoz] Failed to emit trace for ${entry.id}: ${tracesResponse.status}`);
      }
    }
  } catch (err) {
    console.error("[SigNoz] Error emitting traces:", err);
  }
}

async function emitSigNozLogs(data) {
  try {
    const parsed = JSON.parse(data);
    const entries = parsed.entries;
    const stats = parsed.statistics;
    
    // Emit log for each error entry
    for (const entry of entries) {
      const logLevel = entry.type === "Guardrail Violation" ? "WARN" : 
                     entry.type === "System Error" ? "ERROR" : "INFO";
      
      const logMessage = `IONA Error ${entry.isResolved ? 'Resolved' : 'Open'}: ${entry.type} - ${entry.context}`;
      
      const logsPayload = {
        resourceLogs: [{
          resource: {
            attributes: [
              { key: "service.name", value: { stringValue: "iona-error-system" } },
              { key: "service.version", value: { stringValue: "1.1" } },
              { key: "deployment.environment", value: { stringValue: "local" } }
            ]
          },
          scopeLogs: [{
            scope: { name: "iona-error-logging", version: "1.1" },
            logRecords: [{
              timeUnixNano: Date.now() * 1000000,
              severityNumber: logLevel === "ERROR" ? 17 : logLevel === "WARN" ? 13 : 9,
              severityText: logLevel,
              body: { stringValue: logMessage },
              attributes: [
                { key: "error.id", value: { stringValue: entry.id } },
                { key: "error.type", value: { stringValue: entry.type } },
                { key: "error.context", value: { stringValue: entry.context } },
                { key: "error.impact", value: { stringValue: entry.impact } },
                { key: "error.resolution", value: { stringValue: entry.resolution } },
                { key: "error.status", value: { stringValue: entry.status } },
                { key: "error.evidence", value: { stringValue: entry.evidence } },
                { key: "log.event", value: { stringValue: entry.isResolved ? "error.resolved" : "error.open" } },
                { key: "log.level", value: { stringValue: logLevel } },
                { key: "error.total_count", value: { stringValue: stats.total.toString() } },
                { key: "error.resolution_rate", value: { stringValue: stats.resolutionRate.toString() } }
              ]
            }]
          }]
        }]
      };

      // Send to SigNoz logs endpoint
      const logsResponse = await fetch("http://localhost:14318/v1/logs", {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(logsPayload)
      });

      if (logsResponse.ok) {
        console.log(`[SigNoz] Log emitted for error ${entry.id}`);
      } else {
        console.error(`[SigNoz] Failed to emit log for ${entry.id}: ${logsResponse.status}`);
      }
    }
  } catch (err) {
    console.error("[SigNoz] Error emitting logs:", err);
  }
}

function generateTraceId() {
  return Array.from({length: 32}, () => Math.floor(Math.random() * 16).toString(16)).join('');
}

function generateSpanId() {
  return Array.from({length: 16}, () => Math.floor(Math.random() * 16).toString(16)).join('');
}

function broadcastUpdate() {
  try {
    const data = fs.readFileSync(JSON_PATH, "utf-8");
    
    // Broadcast to WebSocket clients
    wss.clients.forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(data);
      }
    });
    
    // Emit metrics to SigNoz
    emitSigNozMetrics(data);
    
    // Emit traces to SigNoz
    emitSigNozTraces(data);
    
    // Emit logs to SigNoz
    emitSigNozLogs(data);
    
    console.log(`[WS] Broadcast update at ${new Date().toISOString()}`);
  } catch (err) {
    console.error("[WS] Failed to read errors.json:", err);
  }
}

// Watch file for changes
fs.watchFile(JSON_PATH, { interval: 2000 }, () => {
  broadcastUpdate();
});

wss.on("connection", ws => {
  console.log("[WS] Dashboard connected");
  // send initial snapshot
  broadcastUpdate();
});

server.listen(PORT, () => {
  console.log(`🚀 IONA Error WS server running on ws://localhost:${PORT}`);
});
