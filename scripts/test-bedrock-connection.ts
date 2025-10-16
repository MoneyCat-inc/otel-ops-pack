import {
  BedrockRuntimeClient,
  InvokeModelCommand,
  InvokeModelWithResponseStreamCommand,
  ResponseStream
} from "@aws-sdk/client-bedrock-runtime";

const region = process.env.AWS_REGION ?? "us-east-1";
const modelId =
  process.env.BEDROCK_MODEL_ID ??
  "anthropic.claude-3-haiku-20240307-v1:0"; // ensure you enabled this model in Bedrock

const client = new BedrockRuntimeClient({ region });
const td = new TextDecoder();

async function basic() {
  const body = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 64,
    messages: [{ role: "user", content: "Reply with: BEDROCK_CONNECTED" }]
  };

  const res = await client.send(
    new InvokeModelCommand({
      modelId,
      contentType: "application/json",
      accept: "application/json",
      body: Buffer.from(JSON.stringify(body))
    })
  );

  const json = JSON.parse(td.decode(res.body as Uint8Array));
  console.log("[Basic]", JSON.stringify(json, null, 2));
}

async function streaming() {
  const body = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 64,
    messages: [{ role: "user", content: "Stream the word STREAMING." }]
  };

  const res = await client.send(
    new InvokeModelWithResponseStreamCommand({
      modelId,
      contentType: "application/json",
      accept: "application/json",
      body: Buffer.from(JSON.stringify(body))
    })
  );

  for await (const part of res.body as AsyncIterable<ResponseStream>) {
    if ("chunk" in part && part.chunk?.bytes) process.stdout.write(td.decode(part.chunk.bytes));
  }
  process.stdout.write("\n");
}

(async () => {
  console.log(`Region: ${region} | Model: ${modelId}`);
  await basic();
  await streaming();
})();

