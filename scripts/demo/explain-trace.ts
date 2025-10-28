#!/usr/bin/env ts-node
/**
 * Investor Demo: Bedrock-Powered Trace Explanation
 * Authority: BossCat OEM | Executor: Cursor{Implementer}
 * Phase 3: AI-powered trace analysis via Amazon Bedrock
 * 
 * Extracts trace summary and sends to Bedrock Claude for natural-language explanation
 */

import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";

// Configuration
const AWS_REGION = process.env.AWS_REGION || "us-east-1";
const MODEL_ID = process.env.BEDROCK_MODEL_ID || "anthropic.claude-3-5-sonnet-20241022-v2:0";

// Initialize Bedrock client
const bedrockClient = new BedrockRuntimeClient({ region: AWS_REGION });

// Trace summary structure (input from SigNoz or manual)
interface TraceSpan {
  name: string;
  duration_ms: number;
  service: string;
  status: "ok" | "error";
  attributes?: Record<string, any>;
}

interface TraceSummary {
  trace_id: string;
  total_duration_ms: number;
  spans: TraceSpan[];
  error_count: number;
  service_count: number;
}

/**
 * Generate natural-language explanation for a trace using Bedrock
 */
async function explainTrace(traceSummary: TraceSummary): Promise<string> {
  // Build context for Claude
  const spansList = traceSummary.spans
    .map(
      (s, i) =>
        `${i + 1}. ${s.name} (${s.service}): ${s.duration_ms}ms [${s.status}]`
    )
    .join("\n");

  const prompt = `You are an expert observability engineer analyzing a distributed trace for an investor demo.

Trace Summary:
- Trace ID: ${traceSummary.trace_id}
- Total Duration: ${traceSummary.total_duration_ms}ms
- Services Involved: ${traceSummary.service_count}
- Errors: ${traceSummary.error_count}

Span Breakdown:
${spansList}

Provide a concise 2-3 sentence explanation of:
1. What this trace represents (the user request flow)
2. Any performance bottlenecks or anomalies
3. Whether this is healthy or needs attention

Keep it investor-friendly (non-technical audience).`;

  // Prepare Bedrock API request
  const payload = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 300,
    messages: [
      {
        role: "user",
        content: prompt,
      },
    ],
  };

  try {
    const command = new InvokeModelCommand({
      modelId: MODEL_ID,
      contentType: "application/json",
      accept: "application/json",
      body: JSON.stringify(payload),
    });

    const response = await bedrockClient.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));

    return responseBody.content[0].text;
  } catch (error: any) {
    console.error("[Bedrock] Error:", error.message);
    throw new Error(`Bedrock invocation failed: ${error.message}`);
  }
}

// CLI usage
async function main() {
  // Example trace (replace with actual SigNoz query result)
  const exampleTrace: TraceSummary = {
    trace_id: "a1b2c3d4e5f6g7h8",
    total_duration_ms: 245,
    service_count: 3,
    error_count: 0,
    spans: [
      { name: "GET /test", duration_ms: 245, service: "bosscat-svc2-api", status: "ok" },
      { name: "db.query.users", duration_ms: 45, service: "bosscat-svc2-api", status: "ok" },
      { name: "cache.get", duration_ms: 12, service: "bosscat-svc2-api", status: "ok" },
      { name: "POST /process", duration_ms: 78, service: "bosscat-svc3-worker", status: "ok" },
    ],
  };

  console.log("🤖 Explaining trace via Bedrock Claude...\n");
  console.log(`Trace ID: ${exampleTrace.trace_id}`);
  console.log(`Duration: ${exampleTrace.total_duration_ms}ms\n`);

  try {
    const explanation = await explainTrace(exampleTrace);
    console.log("📝 Explanation:\n");
    console.log(explanation);
    console.log("");
    process.exit(0);
  } catch (error: any) {
    console.error("❌ Failed:", error.message);
    console.error("\nTroubleshooting:");
    console.error("  1. Verify AWS credentials configured");
    console.error("  2. Check IAM policy includes bedrock:InvokeModel");
    console.error("  3. Confirm region", AWS_REGION, "has Bedrock access");
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

export { explainTrace, TraceSummary, TraceSpan };

