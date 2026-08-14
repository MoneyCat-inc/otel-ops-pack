#!/usr/bin/env python3
"""BossCat gate readiness verifier."""

import argparse
import json
import logging
import os
import platform
import re
import socket
import subprocess
import time
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple

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


def check_windows_service(service_name: str) -> bool:
    """
    Check if Windows service is running.
    Uses 'sc query' command (works on Windows).
    Returns True if service exists and status is RUNNING, False otherwise.
    """
    if platform.system() != "Windows":
        LOG.warning("check_windows_service called on non-Windows platform")
        return False

    try:
        result = subprocess.run(
            ["sc", "query", service_name],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode != 0:
            LOG.warning("Service '%s' not found or inaccessible", service_name)
            return False

        # Parse output: look for "STATE" line with "RUNNING"
        output = result.stdout.upper()
        if "STATE" in output and "RUNNING" in output:
            # Verify it's actually RUNNING (not STOPPED, START_PENDING, etc.)
            state_line = [line for line in output.split("\n") if "STATE" in line]
            if state_line and "RUNNING" in state_line[0]:
                return True

        LOG.warning("Service '%s' exists but not RUNNING", service_name)
        return False
    except Exception as exc:
        LOG.error("Failed to check Windows service '%s': %s", service_name, exc)
        return False


def check_port_reachable(host: str, port: int, timeout: float = 2.0) -> bool:
    """
    Check if TCP port is reachable (supports both IPv4 and IPv6).
    Uses getaddrinfo() to resolve all addresses and attempts connection with appropriate family.
    Returns True if any resolved address succeeds, False if all attempts fail.
    """
    try:
        # Resolve all addresses (IPv4 + IPv6)
        addrinfos = socket.getaddrinfo(host, port, socket.AF_UNSPEC, socket.SOCK_STREAM)
        
        if not addrinfos:
            LOG.debug("No addresses resolved for %s:%d", host, port)
            return False
        
        # Try each resolved address
        for addrinfo in addrinfos:
            family, socktype, proto, canonname, sockaddr = addrinfo
            try:
                sock = socket.socket(family, socktype, proto)
                sock.settimeout(timeout)
                result = sock.connect_ex(sockaddr)
                sock.close()
                if result == 0:
                    LOG.debug("Port check succeeded for %s:%d (family=%d)", host, port, family)
                    return True
            except Exception as exc:
                LOG.debug("Connection attempt failed for %s:%d (family=%d): %s", host, port, family, exc)
                continue
        
        LOG.debug("All connection attempts failed for %s:%d", host, port)
        return False
    except Exception as exc:
        LOG.debug("Port check failed for %s:%d: %s", host, port, exc)
        return False


def parse_host_port(endpoint: str) -> Optional[Tuple[str, int]]:
    """
    Parse endpoint string into (host, port). Returns None on failure.
    
    Accepts:
    - URL schemes: http://localhost:5321, https://host:4318
    - Quoted values: "127.0.0.1:5320", 'localhost:5321'
    - Plain host:port: 127.0.0.1:5320, localhost:5321
    - IPv6: [::1]:4317
    
    Normalizes by:
    - Stripping surrounding quotes
    - Extracting host/port from URL scheme if present
    - Parsing host:port directly if no scheme
    """
    if not endpoint:
        return None
    
    # Strip surrounding quotes
    endpoint = endpoint.strip().strip('"').strip("'")
    
    # Handle URL schemes (http://, https://)
    if "://" in endpoint:
        # Extract host:port from URL
        try:
            from urllib.parse import urlparse
            parsed = urlparse(endpoint)
            host = parsed.hostname or "localhost"
            port = parsed.port
            if port is None:
                # FAIL-SAFE: OTLP endpoints must have explicit ports
                # Do not guess 80/443 (prevents accidental pass on open web ports)
                return None
            # Normalize 0.0.0.0 to 127.0.0.1 for probing (0.0.0.0 means "all interfaces" but is not routable)
            if host == "0.0.0.0":
                host = "127.0.0.1"
            return host, port
        except Exception:
            return None
    
    # Handle IPv6 format [::1]:4317
    if endpoint.startswith("[") and "]" in endpoint:
        bracket_end = endpoint.index("]")
        host = endpoint[1:bracket_end]
        if ":" not in endpoint[bracket_end + 1:]:
            return None
        port_str = endpoint[bracket_end + 2:]  # Skip ]:
        try:
            port = int(port_str)
            return host, port
        except ValueError:
            return None
    
    # Handle plain host:port
    if ":" not in endpoint:
        return None
    
    host, _, port_str = endpoint.rpartition(":")
    try:
        port = int(port_str)
    except ValueError:
        return None
    host = host.strip() or "localhost"
    
    # Normalize 0.0.0.0 to 127.0.0.1 for probing (0.0.0.0 means "all interfaces" but is not routable)
    # This prevents false-FAIL when config binds to 0.0.0.0 but clients connect via localhost
    if host == "0.0.0.0":
        host = "127.0.0.1"
    
    return host, port


def discover_otlp_required_endpoints(config_path: str = "config.yaml") -> List[Tuple[str, int]]:
    """
    Discover OTLP endpoints to probe from configuration / environment.

    Precedence:
    1. OTEL_GATE_OTLP_ENDPOINTS env var (comma-separated host:port or URLs)
    2. Endpoints discovered from config.yaml under receivers.otlp.protocols.*

    FAIL-SAFE: If nothing can be discovered, returns an empty list and callers
    must treat otlp_reachable as False.
    
    Block scoping: Only parses endpoints inside receivers: -> otlp: -> protocols: blocks.
    """
    # 1) Environment override (highest priority)
    env_val = os.environ.get("OTEL_GATE_OTLP_ENDPOINTS")
    if env_val:
        endpoints: List[Tuple[str, int]] = []
        for item in env_val.split(","):
            parsed = parse_host_port(item.strip())
            if parsed:
                endpoints.append(parsed)
            else:
                LOG.warning("Invalid OTEL_GATE_OTLP_ENDPOINTS entry ignored: %r", item)
        if endpoints:
            LOG.info("Using OTLP endpoints from OTEL_GATE_OTLP_ENDPOINTS: %s", endpoints)
            return endpoints

    endpoints: List[Tuple[str, int]] = []

    # 2) Best-effort discovery from config.yaml (Windows collector config)
    if not os.path.exists(config_path):
        LOG.warning("Config file not found: %s", config_path)
        return endpoints

    try:
        with open(config_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except Exception as exc:
        LOG.warning("Failed to read %s for OTLP discovery: %s", config_path, exc)
        return endpoints

    # YAML block scoping: track receivers -> otlp -> protocols hierarchy
    section: Optional[str] = None  # "receivers", "exporters", or None
    in_receivers = False
    in_otlp = False
    in_protocols = False
    indent_level = 0

    for raw in lines:
        line = raw.rstrip("\n")
        stripped = line.lstrip()
        current_indent = len(line) - len(stripped)
        
        # Ignore blank lines and comment-only lines (do not exit block scope)
        if not stripped or stripped.startswith("#"):
            continue
        
        # Track top-level sections (no leading whitespace)
        if current_indent == 0 and re.match(r"^[A-Za-z]", stripped):
            if stripped.startswith("receivers:"):
                section = "receivers"
                in_receivers = True
                in_otlp = False
                in_protocols = False
            elif stripped.startswith("exporters:"):
                section = "exporters"
                in_receivers = False
                in_otlp = False
                in_protocols = False
            else:
                section = None
                in_receivers = False
                in_otlp = False
                in_protocols = False
            continue

        # Only process if we're in receivers section
        if not in_receivers:
            continue

        # Track receivers.otlp: (indented under receivers)
        if in_receivers and current_indent > 0 and stripped.startswith("otlp:"):
            in_otlp = True
            in_protocols = False
            indent_level = current_indent
            continue

        # If we've left the otlp block (dedent to same or less than otlp indent), reset
        if in_otlp and current_indent <= indent_level:
            if not stripped.startswith("otlp") and not stripped.startswith("protocols"):
                in_otlp = False
                in_protocols = False

        # Track protocols: (indented under otlp)
        if in_otlp and current_indent > indent_level and stripped.startswith("protocols:"):
            in_protocols = True
            indent_level = current_indent
            continue

        # If we've left protocols block (dedent to same or less than protocols indent), reset protocols flag
        if in_protocols and current_indent <= indent_level:
            if not any(p in stripped for p in ["protocols:", "grpc:", "http:", "endpoint:"]):
                in_protocols = False

        # Only parse endpoint: lines when inside receivers.otlp.protocols.*
        if in_receivers and in_otlp and in_protocols and "endpoint:" in stripped:
            # Extract endpoint value (handles quoted and unquoted)
            # Pattern: endpoint: value or endpoint: "value" or endpoint: 'value'
            m = re.search(r"endpoint:\s*(.+)", stripped)
            if m:
                endpoint_str = m.group(1).strip()
                parsed = parse_host_port(endpoint_str)
                if parsed:
                    if parsed not in endpoints:
                        endpoints.append(parsed)
                        LOG.debug("Discovered OTLP endpoint from %s: %s:%d", config_path, parsed[0], parsed[1])
                else:
                    LOG.warning("Invalid endpoint format in %s (line: %s): %r", config_path, line, endpoint_str)

    if endpoints:
        LOG.info("Discovered OTLP receiver endpoints from %s: %s", config_path, endpoints)
    else:
        LOG.error(
            "Could not discover any OTLP endpoints from env or %s; "
            "otlp_reachable will be treated as FAIL (fail-safe).",
            config_path,
        )

    return endpoints


class GateVerifier:
    def __init__(self, artifacts_dir: str, signoz_url: str, config_path: str = "config.yaml"):
        self.artifacts_dir = artifacts_dir
        self.signoz_url = signoz_url.rstrip("/")
        self.config_path = config_path
        self.session = requests.Session()
        self.session.headers.update({
            "Accept": "application/json",
            "Content-Type": "application/json",
        })
        # Add SigNoz API key authentication if available
        api_key = os.environ.get("SIGNOZ_API_KEY")
        if api_key:
            self.session.headers.update({"X-SigNoz-Key": api_key})
            LOG.info("SigNoz API key authentication enabled")
        # Initialize results with schema-required fields
        timestamp_utc = datetime.utcnow().isoformat() + "Z"
        self.results: Dict[str, Any] = {
            "timestamp_utc": timestamp_utc,  # Schema required
            "service_name": "gate-readiness-verifier",  # Schema required (default, can be overridden)
            "generated_at": timestamp_utc,  # Backwards compatibility
            "signoz_url": self.signoz_url,
            "artifacts_dir": artifacts_dir,
            "tests": {},
            "gate_checks": {},  # Schema required (populated after tests run)
            "steps": {  # Schema required (minimal structure for this verifier)
                "quick_monitor": "skip",  # This verifier doesn't run quick-monitor
                "canary_send": {
                    "exit_code": -1,
                    "status": "skip",
                    "log_confirmed": False,
                    "api_confirmed": False,
                    "api_reason": "skipped_by_config"
                }
            },
            "outcome": "UNKNOWN",  # Schema required (computed after gate_checks)
            "exit_code": -1,  # Schema required (computed after gate_checks)
            "overall_status": "UNKNOWN",  # Backwards compatibility
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

    # -------------------- Gate Checks Mapping --------------------

    def compute_gate_checks(self) -> Dict[str, bool]:
        """
        Map test results to gate_checks schema (5 required boolean checks).
        Mapping table: tests.* -> gate_checks[name] = boolean
        
        FAIL-SAFE SEMANTICS: If a check cannot be determined, emit False (fails safe).
        Missing evidence is FAIL, not PASS.
        """
        checks: Dict[str, bool] = {}
        
        # 1. collector_service_running: DIRECT PROBE - Check Windows service directly
        # Schema says: "Windows OTel collector service is running"
        service_name = "otelcol-contrib"  # Standard Windows service name
        checks["collector_service_running"] = check_windows_service(service_name)
        if not checks["collector_service_running"]:
            LOG.warning("Gate check FAIL: collector_service_running=False (service '%s' not RUNNING)", service_name)
        
        # 2. otlp_reachable: CONFIG-DRIVEN DIRECT PROBE
        # BossCat doctrine: probe configured OTLP endpoints, not assumed defaults.
        required_endpoints = discover_otlp_required_endpoints(self.config_path)
        if not required_endpoints:
            checks["otlp_reachable"] = False
            LOG.warning("Gate check FAIL: otlp_reachable=False (no OTLP endpoints discovered)")
        else:
            all_ok = True
            for host, port in required_endpoints:
                ok = check_port_reachable(host, port)
                LOG.info("OTLP probe %s:%d -> %s", host, port, "OK" if ok else "FAIL")
                if not ok:
                    all_ok = False
            checks["otlp_reachable"] = all_ok
            if not all_ok:
                LOG.warning("Gate check FAIL: otlp_reachable=False (one or more configured OTLP endpoints unreachable)")
            else:
                LOG.info("Gate check PASS: otlp_reachable=True (all configured OTLP endpoints reachable)")
        
        # 3. span_rate_nonzero: Derived from synthetic traces OR canary traces
        # Schema says: "Spans are being ingested (log OR API confirmed)"
        synthetic = self.results["tests"].get("synthetic_traces", {})
        canary = self.results["tests"].get("canary_traces", {})
        checks["span_rate_nonzero"] = (
            synthetic.get("overall_status") == "PASS" or
            canary.get("overall_status") == "PASS" or
            synthetic.get("count", 0) > 0 or
            canary.get("count", 0) > 0
        )
        if not checks["span_rate_nonzero"]:
            LOG.warning("Gate check FAIL: span_rate_nonzero=False (no synthetic/canary traces found)")
        
        # 4. export_drops_zero: FAIL-SAFE - Missing evidence is FAIL
        # Schema says: "No dropped spans detected in collector logs"
        k6_status = self.results["tests"].get("k6_performance", {}).get("overall_status", "UNKNOWN")
        locust_status = self.results["tests"].get("locust_user_journey", {}).get("overall_status", "UNKNOWN")
        
        # FAIL-SAFE: Only PASS if both tests explicitly PASS. MISSING/UNKNOWN/FAIL => FAIL.
        if k6_status != "PASS" or locust_status != "PASS":
            checks["export_drops_zero"] = False
            LOG.warning(
                "Gate check FAIL: export_drops_zero=False (k6_status=%s, locust_status=%s - missing/unknown/fail not allowed)",
                k6_status,
                locust_status,
            )
        else:
            checks["export_drops_zero"] = True
        
        # 5. error_ratio_under_5pct: FAIL-SAFE - Missing evidence is FAIL
        # Schema says: "Error ratio is under 5% threshold"
        # FAIL-SAFE: Only PASS if both tests explicitly PASS. MISSING/UNKNOWN/FAIL => FAIL.
        if k6_status != "PASS" or locust_status != "PASS":
            checks["error_ratio_under_5pct"] = False
            LOG.warning(
                "Gate check FAIL: error_ratio_under_5pct=False (k6_status=%s, locust_status=%s - missing/unknown/fail not allowed)",
                k6_status,
                locust_status,
            )
        else:
            checks["error_ratio_under_5pct"] = True
        
        return checks

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

    def compute_outcome_and_exit_code(self) -> tuple[str, int]:
        """
        Compute outcome (OK/WARN/FAIL) and exit_code (0/1/2) based on gate_checks.
        Matches verify-pipeline.ps1 logic with fail-safe semantics.
        
        Hard failures (exit_code=2):
        - collector_service_running=False
        - otlp_reachable=False
        - export_drops_zero=False
        
        Warnings (exit_code=1):
        - span_rate_nonzero=False
        - error_ratio_under_5pct=False
        """
        gate_checks = self.results.get("gate_checks", {})
        
        # Hard failures: critical checks must pass (fail-safe: default to False if missing)
        hard_fail = (
            not gate_checks.get("collector_service_running", False) or
            not gate_checks.get("otlp_reachable", False) or
            not gate_checks.get("export_drops_zero", False)  # Changed default to False (fail-safe)
        )
        
        # Warnings: non-critical checks failing
        warn = (
            not gate_checks.get("span_rate_nonzero", False) or
            not gate_checks.get("error_ratio_under_5pct", False)  # Changed default to False (fail-safe)
        )
        
        if hard_fail:
            return ("FAIL", 2)
        elif warn:
            return ("WARN", 1)
        else:
            return ("OK", 0)

    def run(self) -> Dict[str, Any]:
        self.load_k6_results()
        self.load_locust_summary()
        self.check_signoz_health()
        self.verify_synthetic_traces()
        self.verify_canary_traces()
        
        # Compute gate_checks from test results
        self.results["gate_checks"] = self.compute_gate_checks()
        
        # Compute overall status from tests
        self.results["overall_status"] = self.compute_overall_status()
        
        # Compute outcome and exit_code based on gate_checks (schema requirement)
        outcome, exit_code = self.compute_outcome_and_exit_code()
        self.results["outcome"] = outcome
        self.results["exit_code"] = exit_code
        
        return self.results


def main() -> int:
    parser = argparse.ArgumentParser(description="BossCat gate readiness verifier")
    parser.add_argument("--artifacts-dir", required=True, help="Directory containing test artifacts")
    parser.add_argument("--signoz-url", required=True, help="SigNoz base URL (e.g. http://localhost:8080)")
    parser.add_argument("--output", default="artifacts/gate-verification-results.json", help="Path to write verification report")
    parser.add_argument("--config", default="config.yaml", help="Path to collector config file (default: config.yaml)")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, format="%(levelname)s %(message)s")

    os.makedirs(os.path.dirname(args.output), exist_ok=True)

    verifier = GateVerifier(artifacts_dir=args.artifacts_dir, signoz_url=args.signoz_url, config_path=args.config)
    results = verifier.run()

    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(results, handle, indent=2)

    LOG.info("Gate verification summary saved to %s", args.output)
    LOG.info("Overall status: %s", results.get("overall_status"))
    LOG.info("Gate checks: %s", results.get("gate_checks", {}))
    LOG.info("Outcome: %s (exit_code: %d)", results.get("outcome"), results.get("exit_code", -1))
    
    # Return exit_code from gate_checks evaluation (schema-compliant)
    return results.get("exit_code", 1)


if __name__ == "__main__":
    raise SystemExit(main())
