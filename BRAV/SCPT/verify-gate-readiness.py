#!/usr/bin/env python3
"""BossCat gate readiness verifier."""

import argparse
import json
import logging
import os
import time
from datetime import datetime
from typing import Dict, Any, List

import requests

LOG = logging.getLogger("bosscat.gate")


def load_json(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def safe_get(dct: Dict[str, Any], *path, default=None):
    cur: Any = dct
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur


class GateVerifier:
    def __init__(self, artifacts_dir: str, signoz_url: str):
        self.artifacts_dir = artifacts_dir
        self.signoz_url = signoz_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update({
            "Accept": "application/json",
            "Content-Type": "application/json",
        })
        self.results: Dict[str, Any] = {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "signoz_url": self.signoz_url,
            "artifacts_dir": artifacts_dir,
            "tests": {},
            "overall_status": "UNKNOWN",
        }

    # -------------------- Artifact helpers --------------------

    def load_k6_results(self) -> Dict[str, Any]:
        summary: Dict[str, Any] = {
            "overall_status": "UNKNOWN",
            "per_test": [],
            "failure_reasons": []
        }
        tests = ["baseline", "load", "stress", "soak"]
        found_any = False
        aggregated_failures: List[str] = []
        for test in tests:
            path = os.path.join(self.artifacts_dir, f"{test}-test-results.json")
            if not os.path.exists(path):
                LOG.warning("k6 summary missing: %s", path)
                continue
            found_any = True
            data = load_json(path)
            status = data.get("overall_status", "UNKNOWN")
            summary["per_test"].append({
                "name": test,
                "status": status,
                "failure_reasons": data.get("failure_reasons", []),
                "metrics": data.get("metrics", {})
            })
            if status != "PASS":
                aggregated_failures.extend(data.get("failure_reasons", []))
        if not found_any:
            summary["overall_status"] = "MISSING"
            summary["failure_reasons"].append("No k6 summaries found")
        else:
            summary["overall_status"] = "PASS" if not aggregated_failures else "FAIL"
            summary["failure_reasons"] = aggregated_failures
        self.results["tests"]["k6_performance"] = summary
        return summary

    def load_locust_summary(self) -> Dict[str, Any]:
        path = os.path.join(self.artifacts_dir, "locust", "locust-summary.json")
        if not os.path.exists(path):
            LOG.warning("Locust summary missing: %s", path)
            summary = {
                "overall_status": "MISSING",
                "failure_reasons": ["Locust summary not found"],
                "metrics": {}
            }
            self.results["tests"]["locust_user_journey"] = summary
            return summary
        data = load_json(path)
        summary = {
            "overall_status": data.get("overall_status", "UNKNOWN"),
            "failure_reasons": data.get("failure_reasons", []),
            "metrics": data.get("metrics", {}),
            "thresholds": data.get("thresholds", {}),
        }
        self.results["tests"]["locust_user_journey"] = summary
        return summary

    # -------------------- SigNoz API helpers --------------------

    def check_signoz_health(self) -> Dict[str, Any]:
        endpoint = f"{self.signoz_url}/api/v1/health"
        try:
            response = self.session.get(endpoint, timeout=10)
            response.raise_for_status()
            data = response.json()
            status = "PASS" if data.get("status") == "ok" else "FAIL"
            result = {
                "overall_status": status,
                "details": data
            }
        except Exception as exc:
            LOG.error("SigNoz health check failed: %s", exc)
            result = {
                "overall_status": "FAIL",
                "failure_reasons": [str(exc)]
            }
        self.results["tests"]["signoz_health"] = result
        return result

    def query_signoz(self, path: str, params: Dict[str, Any]) -> Dict[str, Any]:
        endpoint = f"{self.signoz_url}{path}"
        response = self.session.get(endpoint, params=params, timeout=15)
        response.raise_for_status()
        return response.json()

    def verify_synthetic_traces(self) -> Dict[str, Any]:
        now = int(time.time())
        params = {"start": now - 900, "end": now, "limit": 50}
        summary: Dict[str, Any]
        try:
            data = self.query_signoz("/api/v1/traces", params)
            traces = data.get("data", [])
            matches = [t for t in traces if safe_get(t, "attributes", "test.type") == "synthetic"]
            status = "PASS" if matches else "FAIL"
            summary = {
                "overall_status": status,
                "count": len(matches),
                "failure_reasons": [] if matches else ["No synthetic traces discovered"],
            }
        except Exception as exc:
            LOG.error("Synthetic trace verification failed: %s", exc)
            summary = {
                "overall_status": "FAIL",
                "failure_reasons": [str(exc)]
            }
        self.results["tests"]["synthetic_traces"] = summary
        return summary

    def verify_canary_traces(self) -> Dict[str, Any]:
        now = int(time.time())
        params = {"start": now - 900, "end": now, "limit": 50, "query": "test.type = \"canary\""}
        summary: Dict[str, Any]
        try:
            data = self.query_signoz("/api/v1/logs", params)
            logs = data.get("data", [])
            matches = [l for l in logs if safe_get(l, "attributes", "test.type") == "canary"]
            status = "PASS" if matches else "FAIL"
            summary = {
                "overall_status": status,
                "count": len(matches),
                "failure_reasons": [] if matches else ["No canary logs discovered"],
            }
        except Exception as exc:
            LOG.error("Canary trace verification failed: %s", exc)
            summary = {
                "overall_status": "FAIL",
                "failure_reasons": [str(exc)]
            }
        self.results["tests"]["canary_traces"] = summary
        return summary

    # -------------------- Orchestration --------------------

    def compute_overall_status(self) -> str:
        failures = []
        for name, section in self.results["tests"].items():
            status = section.get("overall_status")
            if status not in {"PASS", "MISSING"}:
                failures.append(name)
        if not self.results["tests"]:
            return "UNKNOWN"
        return "PASS" if not failures else "FAIL"

    def run(self) -> Dict[str, Any]:
        self.load_k6_results()
        self.load_locust_summary()
        self.check_signoz_health()
        self.verify_synthetic_traces()
        self.verify_canary_traces()
        self.results["overall_status"] = self.compute_overall_status()
        return self.results


def main() -> int:
    parser = argparse.ArgumentParser(description="BossCat gate readiness verifier")
    parser.add_argument("--artifacts-dir", required=True, help="Directory containing test artifacts")
    parser.add_argument("--signoz-url", required=True, help="SigNoz base URL (e.g. http://localhost:8080)")
    parser.add_argument("--output", default="artifacts/gate-verification-results.json", help="Path to write verification report")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, format="%(levelname)s %(message)s")

    os.makedirs(os.path.dirname(args.output), exist_ok=True)

    verifier = GateVerifier(artifacts_dir=args.artifacts_dir, signoz_url=args.signoz_url)
    results = verifier.run()

    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(results, handle, indent=2)

    LOG.info("Gate verification summary saved to %s", args.output)
    LOG.info("Overall status: %s", results.get("overall_status"))
    return 0 if results.get("overall_status") == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
