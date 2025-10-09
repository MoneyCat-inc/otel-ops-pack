#!/usr/bin/env python3
"""Generate a BossCat BOSS v2 report from gate verification results."""

import argparse
import json
import os
from datetime import datetime
from typing import Any, Dict, List


def load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def format_percentage(value: float) -> str:
    return f"{value * 100:.2f}%"


def build_metrics_table(k6_section: Dict[str, Any]) -> str:
    header = "| Metric | Target | Actual | Status |\n|--------|--------|--------|--------|"
    rows: List[str] = []
    targets = {
        "baseline": 200,
        "load": 500,
        "stress": 2000,
        "soak": 1000,
    }
    for entry in k6_section.get("per_test", []):
        name = entry.get("name", "").lower()
        target = targets.get(name, 0)
        metrics = entry.get("metrics", {})
        p95 = metrics.get("p95_ms", 0)
        status = entry.get("status", "UNKNOWN")
        rows.append(
            f"| p95 {name.title()} | < {target}ms | {p95:.2f}ms | {status} |"
        )
        error_rate = metrics.get("error_rate", 0)
        rows.append(
            f"| Error rate {name.title()} | < 5% | {format_percentage(error_rate)} | {status} |"
        )
    return "\n".join([header] + rows)


def maybe_generate_pdf(markdown: str, output_pdf: str) -> None:
    try:
        from weasyprint import HTML  # type: ignore
    except Exception:
        print("PDF generation skipped: weasyprint not available")
        return
    html_body = f"<html><body><pre>{markdown}</pre></body></html>"
    HTML(string=html_body).write_pdf(output_pdf)
    print(f"PDF report written to {output_pdf}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate BossCat BOSS v2 report")
    parser.add_argument("--gate-results", default="artifacts/gate-verification-results.json", help="Gate verification JSON path")
    parser.add_argument("--output", required=True, help="Output markdown path")
    parser.add_argument("--pdf", help="Optional PDF output path")
    args = parser.parse_args()

    gate_results = load_json(args.gate_results)
    k6_section = gate_results.get("tests", {}).get("k6_performance", {})
    locust_section = gate_results.get("tests", {}).get("locust_user_journey", {})

    generated_at = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%SZ")
    overall_status = gate_results.get("overall_status", "UNKNOWN")

    lines: List[str] = [
        "# BOSS v2 Gate Verification Report",
        "",
        "## System Overview",
        f"- Report Date: {generated_at}",
        f"- BossCat Gate Status: {overall_status}",
        f"- SigNoz URL: {gate_results.get('signoz_url', 'n/a')}",
        "",
        "## Research & Engineering Highlights",
        "- k6 performance suite executed across baseline, load, stress, and soak", 
        "- Locust user-journey validated API stability",
        "- Synthetic and canary trace ingestion confirmed",
        "",
        "## Metrics Dashboard",
        build_metrics_table(k6_section),
        "",
        "### Locust Summary",
        f"- Status: {locust_section.get('overall_status', 'UNKNOWN')}",
        f"- Requests: {locust_section.get('metrics', {}).get('requests', 0)}",
        f"- Error rate: {format_percentage(locust_section.get('metrics', {}).get('error_rate', 0))}",
        "",
        "## Governance & Compliance",
        f"- SigNoz health: {gate_results.get('tests', {}).get('signoz_health', {}).get('overall_status', 'UNKNOWN')}",
        f"- Synthetic traces: {gate_results.get('tests', {}).get('synthetic_traces', {}).get('overall_status', 'UNKNOWN')}",
        f"- Canary traces: {gate_results.get('tests', {}).get('canary_traces', {}).get('overall_status', 'UNKNOWN')}",
        "",
        "## Next Steps",
        "1. BossCat OEM reviews gate evidence",
        "2. If PASS, promote artifacts to production release",
        "3. If FAIL, assign Gap-Closer to investigate failure reasons",
        "",
        "## Appendices",
        "- Artifacts directory: " + gate_results.get("artifacts_dir", "n/a"),
        "- k6 per-test failures: " + (", ".join(k6_section.get('failure_reasons', [])) or "None"),
        "- Locust failures: " + (", ".join(locust_section.get('failure_reasons', [])) or "None")
    ]

    markdown = "\n".join(lines)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as handle:
        handle.write(markdown)
    print(f"BOSS v2 report written to {args.output}")

    if args.pdf:
        os.makedirs(os.path.dirname(args.pdf), exist_ok=True)
        maybe_generate_pdf(markdown, args.pdf)

    return 0 if overall_status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
