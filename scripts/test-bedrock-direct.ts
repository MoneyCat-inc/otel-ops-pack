#!/usr/bin/env node
// Gate #015 - Direct Bedrock API Test (Bypass MCP)
// Tests if Bedrock API is accessible via AWS SDK

import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';

async function testBedrock() {
  console.log('🔌 Testing Bedrock API Direct Connection\n');
  
  const region = process.env.AWS_REGION || 'us-east-1';
  // Use inference profile ARN for cross-region models
  const modelId = 'us.anthropic.claude-3-5-sonnet-20241022-v2:0';
  
  console.log(`Region: ${region}`);
  console.log(`Model: ${modelId}\n`);
  
  try {
    const client = new BedrockRuntimeClient({ region });
    
    const payload = {
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 50,
      messages: [{
        role: 'user',
        content: 'Say only "BEDROCK_CONNECTED" and nothing else.'
      }]
    };
    
    console.log('▶ Sending test request...');
    
    const command = new InvokeModelCommand({
      modelId,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(payload)
    });
    
    const response = await client.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    
    console.log('✅ SUCCESS - Bedrock API Accessible\n');
    console.log('Response:', responseBody.content[0].text);
    console.log('Tokens:', JSON.stringify(responseBody.usage));
    console.log('\n🎉 BEDROCK_CONNECTED - MCP can proceed');
    
    process.exit(0);
  } catch (error: any) {
    console.error('❌ FAILED - Bedrock API Inaccessible\n');
    console.error('Error:', error.message);
    console.error('Code:', error.name);
    
    if (error.message?.includes('UnrecognizedClientException')) {
      console.error('\n💡 Suggestion: Check AWS credentials are configured');
    } else if (error.message?.includes('AccessDeniedException')) {
      console.error('\n💡 Suggestion: Add IAM policy for bedrock:InvokeModel');
    } else if (error.message?.includes('ResourceNotFoundException')) {
      console.error('\n💡 Suggestion: Enable Bedrock service and request model access');
    }
    
    process.exit(20);
  }
}

testBedrock();

