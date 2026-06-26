#!/usr/bin/env python3
"""
BossCat T1 Rolling-Stats Production Deployment Harness
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from rolling_run import get_git_sha, run_benchmark, run_validator

PRODUCTION_EVIDENCE = Path("CHAR/ECRR/ECRR_REPORTS/t1_production_evidence.json")


def ensure_utf8() -> None:
    if sys.platform == "win32":
        import codecs
        sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
        sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())


def build_deployment_metadata() -> Dict[str, Any]:
    version = os.getenv("T1_RELEASE_VERSION", "1.0.0")
    deployed_at = datetime.now(timezone.utc).isoformat()
    git_sha = get_git_sha() or ("0" * 40)
    pipeline_url = os.getenv("T1_PIPELINE_URL")
    deployed_by = os.getenv("USER") or os.getenv("USERNAME")

    metadata: Dict[str, Any] = {
        "environment": "production",
        "version": version,
        "deployed_at": deployed_at,
        "gitSha": git_sha,
    }

    if pipeline_url:
        metadata["pipelineUrl"] = pipeline_url
    if deployed_by:
        metadata["deployedBy"] = deployed_by

    return metadata


def send_to_signoz(evidence: Dict[str, Any], context: Dict[str, Any]) -> bool:
    """Simulate emission of production metrics to SigNoz."""
    print("[t1-prod] Sending metrics to SigNoz (simulated)")

    timings = context.get("timings", {})
    parity = context.get("parity", {})

    metrics = {
        "gpu_available": 1 if context.get("gpu_available") else 0,
        "fallback_triggered": 1 if evidence["run"]["fellBackToCpu"] else 0,
        "performance_ratio": (timings.get("cpuMs", 0.0) / timings.get("accMs", 1.0)) if timings.get("accMs") else 1.0,
        "parity_max_diff": parity.get("maxAbsDiff", 0.0),
        "gpu_timing_total": timings.get("gpuMs", 0.0),
        "gpu_timing_h2d": timings.get("h2dMs", 0.0),
        "gpu_timing_kernel": timings.get("kernelMs", 0.0),
        "gpu_timing_d2h": timings.get("d2hMs", 0.0),
    }

    labels = {
        "environment": evidence["deployment"]["environment"],
        "epic": "gpu-pattern-sifter",
        "lane": "T1",
        "provider": evidence["run"]["providerFinal"],
        "gpu_model": context.get("gpu_model") or "none",
    }

    print(f"  metrics: {metrics}")
    print(f"  labels: {labels}")
    print("  status: delivered (simulated)")
    return True


def save_evidence(evidence: Dict[str, Any]) -> None:
    PRODUCTION_EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    PRODUCTION_EVIDENCE.write_text(json.dumps(evidence, indent=2), encoding="utf-8")
    print(f"[t1-prod] Evidence saved to {PRODUCTION_EVIDENCE}")


def main() -> int:
    ensure_utf8()

    print("[t1-prod] BossCat Rolling-Stats Production Deployment")
    print("[t1-prod] ===========================================")

    deployment_meta = build_deployment_metadata()
    evidence, context = run_benchmark(deployment_override=deployment_meta)

    save_evidence(evidence)
    run_validator(PRODUCTION_EVIDENCE)

    send_to_signoz(evidence, context)

    print("\n[t1-prod] Deployment Summary:")
    print(f"  Provider: {evidence['run']['providerFinal']}")
    print(f"  GPU timings: {context['timings']['gpuMs']:.2f} ms")
    print(f"  CPU timings: {context['timings']['cpuMs']:.2f} ms")
    print(f"  Parity (maxAbsDiff): {context['parity']['maxAbsDiff']:.2e}")

    if evidence['parity']['maxAbsDiff'] > 1e-5:
        print("[t1-prod] Warning: parity drift detected")
        return 1

    print("[t1-prod] Production deployment complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())

