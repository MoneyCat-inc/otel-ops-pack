#!/usr/bin/env node
// Gate #015 Job-2: Bedrock Co-Author for Preset Iteration
// ECRR: BossCat - AI-assisted preset authoring

import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { readFileSync } from 'fs';

const client = new BedrockRuntimeClient({ 
  region: process.env.AWS_REGION || 'us-east-1' 
});

// Use inference profile ID for cross-region models
const modelId = 'us.anthropic.claude-3-5-sonnet-20241022-v2:0';

interface CoAuthorRequest {
  preset?: string;
  metrics?: {
    blackout_pct: number;
    mean_luma: number;
    motion?: number;
  };
  iteration: number;
  brief?: string;
}

export async function suggestPresetImprovement(req: CoAuthorRequest): Promise<string> {
  const { preset, metrics, iteration, brief } = req;
  
  let prompt = `You are a ProjectM Milkdrop preset (.milk format) optimization expert.

CURRENT STATE (Iteration ${iteration}):`;
  
  if (metrics) {
    prompt += `
- Blackout: ${metrics.blackout_pct}% (target: ≤40%, ideal: ≤20%)
- Mean Luminance: ${metrics.mean_luma.toFixed(4)} (0-1 scale)`;
    if (metrics.motion !== undefined) {
      prompt += `
- Motion: Δluma = ${metrics.motion.toFixed(4)}`;
    }
  }
  
  if (preset) {
    prompt += `

CURRENT PRESET:
\`\`\`
${preset.substring(0, 800)}${preset.length > 800 ? '\n... (truncated)' : ''}
\`\`\``;
  }
  
  prompt += `

TASK: Suggest ONE small improvement to reduce blackout and increase visual motion.
Focus on parameters like: fDecay, fVideoEchoZoom, per_frame zoom/rot, wave parameters.

OUTPUT FORMAT (JSON only):
{
  "reasoning": "one sentence why this helps",
  "parameter": "specific parameter name",
  "change": "from X to Y",
  "expected_impact": "reduced blackout / more motion"
}`;

  if (brief) {
    prompt += `\n\nUSER BRIEF: ${brief}`;
  }
  
  const payload = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 300,
    messages: [{ role: 'user', content: prompt }]
  };
  
  const command = new InvokeModelCommand({
    modelId,
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(payload)
  });
  
  const response = await client.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));
  const suggestion = responseBody.content[0].text;
  
  return suggestion;
}

// CLI mode
if (require.main === module) {
  const args = process.argv.slice(2);
  const presetFile = args[0];
  const iteration = parseInt(args[1] || '1');
  const metricsFile = args[2];
  
  if (!presetFile) {
    console.error('Usage: npx tsx bedrock-coauthor.ts <preset.milk> [iteration] [metrics.json]');
    process.exit(1);
  }
  
  const preset = readFileSync(presetFile, 'utf-8');
  let metrics;
  if (metricsFile) {
    metrics = JSON.parse(readFileSync(metricsFile, 'utf-8'));
  }
  
  suggestPresetImprovement({ preset, metrics, iteration })
    .then(suggestion => {
      console.log(suggestion);
      process.exit(0);
    })
    .catch(err => {
      console.error('Error:', err.message);
      process.exit(1);
    });
}

