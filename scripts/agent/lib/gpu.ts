/**
 * GPU Inference Library - ONNX Runtime stdio wrapper
 * Cat Nap Control Room · Resonai [OTel] · GPU Acceleration
 * 
 * Local-first stdio integration with ECRR evidence collection
 */

import { spawnSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

export interface GpuInferenceOptions {
  model: string;
  inputJson: unknown;
  provider: "cuda" | "directml" | "cpu" | "tensorrt";
  allowCpuFallback: boolean;
  ecrrDir: string;
}

export interface GpuInferenceResult {
  payload: any;
  artifact: string;
  code: number;
}

/**
 * Run GPU inference once with stdio communication
 * 
 * @param opts Inference options
 * @returns Result with payload, artifact path, and exit code
 */
export function runGpuOnce(opts: GpuInferenceOptions): GpuInferenceResult {
  // Ensure temp directory exists
  mkdirSync(".agent/tmp", { recursive: true });
  
  // Write input JSON to temp file
  const inPath = ".agent/tmp/gpu_input.json";
  writeFileSync(inPath, JSON.stringify(opts.inputJson));

  // Build command arguments
  const args = [
    "scripts/agent/tools/gpu_infer.py",
    "--model", opts.model,
    "--input", inPath,
    "--provider", opts.provider,
    opts.allowCpuFallback ? "--allow-cpu-fallback" : ""
  ].filter(Boolean);

  // Execute Python script
  const res = spawnSync("python", args, { encoding: "utf8" });
  const stdout = (res.stdout || "").trim();
  
  // Parse JSON response
  const payload = (() => {
    try {
      return JSON.parse(stdout);
    } catch {
      return { ok: false, error: "bad_json", raw: stdout };
    }
  })();

  // Write ECRR evidence
  mkdirSync(opts.ecrrDir, { recursive: true });
  const artifact = join(opts.ecrrDir, `gpu_run_${Date.now()}.json`);
  writeFileSync(artifact, JSON.stringify(payload, null, 2));

  return { payload, artifact, code: res.status ?? 0 };
}
