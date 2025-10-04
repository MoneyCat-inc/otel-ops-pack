#!/usr/bin/env python3
"""
ONNX Runtime GPU Inference Harness
Cat Nap Control Room · Resonai [OTel] · GPU Acceleration

Local-first stdio integration with GPU→CPU fallback and kill-switch compliance.
"""

import argparse
import json
import sys
import time
import os


def load_inputs(path):
    """Load input data from JSON file"""
    with open(path, "r", encoding="utf-8") as f:
        j = json.load(f)
    # assume single input named "input" for PoC
    return {"input": j["input"]}


def try_session(model, providers):
    """Try to create ONNX Runtime session with given providers"""
    import onnxruntime as ort
    so = ort.SessionOptions()
    so.log_severity_level = 2  # info+
    try:
        return ort.InferenceSession(model, providers=providers, sess_options=so), None
    except Exception as e:
        return None, str(e)


def main():
    """Main inference function with GPU→CPU fallback logic"""
    ap = argparse.ArgumentParser(description="ONNX Runtime GPU Inference Harness")
    ap.add_argument("--model", required=True, help="Path to ONNX model file")
    ap.add_argument("--input", required=True, help="Path to input JSON file")
    ap.add_argument("--provider", default="cuda", help="Execution provider: cuda|directml|cpu|tensorrt")
    ap.add_argument("--allow-cpu-fallback", action="store_true", help="Allow CPU fallback if GPU fails")
    args = ap.parse_args()

    # Provider mapping
    prov_map = {
        "cuda": ["CUDAExecutionProvider"],
        "tensorrt": ["TensorrtExecutionProvider"],
        "directml": ["DmlExecutionProvider"],
        "cpu": ["CPUExecutionProvider"]
    }
    want = prov_map.get(args.provider, ["CPUExecutionProvider"])
    
    # Explicit attempt first
    sess, err = try_session(args.model, want)
    active = None

    if sess is None and args.allow_cpu_fallback and want[0] != "CPUExecutionProvider":
        # Fallback pattern with explicit log
        sess, err2 = try_session(args.model, ["CPUExecutionProvider"])
        if sess is None:
            print(json.dumps({"ok": False, "error": f"gpu_failed:{err}; cpu_failed:{err2}"}))
            return 0
        active = "CPUExecutionProvider"
        fell_back = True
    elif sess is None:
        print(json.dumps({"ok": False, "error": f"provider_failed:{err}"}))
        return 0
    else:
        # If TRT selected, chain CUDA as safety net; if CUDA selected, chain CPU
        chain = []
        if want[0] == "TensorrtExecutionProvider":
            chain = ["CUDAExecutionProvider", "CPUExecutionProvider"]
        elif want[0] == "CUDAExecutionProvider":
            chain = ["CPUExecutionProvider"]
        if chain:
            # Rebuild with chained providers for mixed graphs
            sess, _ = try_session(args.model, want + chain)
        active = sess.get_providers()[0]
        fell_back = (active == "CPUExecutionProvider" and want[0] != "CPUExecutionProvider")

    # Load inputs and run inference
    feeds = load_inputs(args.input)
    
    # Warmup runs
    for _ in range(2):
        sess.run(None, feeds)
    
    # Timed inference
    t0 = time.perf_counter()
    out = sess.run(None, feeds)
    dt_ms = (time.perf_counter() - t0) * 1000.0

    # Output results
    print(json.dumps({
        "ok": True,
        "provider": active,
        "fellBackToCpu": fell_back,
        "latencyMs": dt_ms,
        "outputs": [o if isinstance(o, (int, float, str)) else None for o in out]  # trimmed for PoC
    }))


if __name__ == "__main__":
    # Hard stop if kill-switch present (BossCat rule)
    if os.path.exists(".agent/LOCK"):
        print(json.dumps({"ok": False, "error": "kill_switch"}))
        sys.exit(0)
    
    sys.exit(main())
