#!/usr/bin/env python3
"""Generate an ECRR markdown report for BossCat gate verification."""

import argparse
import json
import os
from datetime import datetime
from typing import Any, Dict, List


def load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def render_k6_table(k6_section: Dict[str, Any]) -> str:
    header = "| Test | Status | p95 (ms) | Error Rate | Requests |\n|------|--------|----------|------------|----------|"
    rows = []
    for entry in k6_section.get("per_test", []):
        metrics = entry.get("metrics", {})
        p95 = metrics.get("p95_ms", 0)
        error_rate = metrics.get("error_rate", 0)
        requests = metrics.get("requests", 0)
        rows.append(
            f"| {entry['name'].title()} | {entry.get('status', 'UNKNOWN')} | {p95:.2f} | {error_rate:.4f} | {requests} |"
        )
    return "\n".join([header] + rows)


def render_observability_section(results: Dict[str, Any]) -> str:
    items = []
    for key in ["signoz_health", "synthetic_traces", "canary_traces"]:
        section = results.get("tests", {}).get(key, {})
        label = key.replace("_", " ").title()
        status = section.get("overall_status", "UNKNOWN")
        detail = section.get("failure_reasons") or section.get("details")
        detail_str = "; ".join(detail) if isinstance(detail, list) else str(detail or "")
        items.append(f"- **{label}**: {status}{' - ' + detail_str if detail_str else ''}")
    return "\n".join(items)


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
    parser = argparse.ArgumentParser(description="Generate BossCat ECRR report")
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
        "# ECRR Gate Verification Report",
        "",
        f"**Generated**: {generated_at}",
        f"**Overall Status**: {overall_status}",
        f"**SigNoz URL**: {gate_results.get('signoz_url', 'n/a')}",
        "",
        "## Examine Phase",
        render_observability_section(gate_results),
        "",
        "### Performance Tests (k6)",
        render_k6_table(k6_section),
        "",
        "### Locust User Journey",
        f"- Status: {locust_section.get('overall_status', 'UNKNOWN')}",
        f"- Error rate: {locust_section.get('metrics', {}).get('error_rate', 0):.4f}",
        f"- Requests: {locust_section.get('metrics', {}).get('requests', 0)}",
        "",
        "## Clean Phase",
        "- Aggregated issues: " + (", ".join(k6_section.get('failure_reasons', [])) or "None"),
        "- Locust issues: " + (", ".join(locust_section.get('failure_reasons', [])) or "None"),
        "",
        "## Report Phase",
        f"- Gate artifacts: {gate_results.get('artifacts_dir', 'n/a')}",
        "- Evidence: k6 summaries, Locust summary, SigNoz queries",
        "",
        "## Role Phase",
        "- Investigator: Identified performance regressions",
        "- Gap-Closer: Applied fixes and reran tests",
        "- QA Scribe: Produced this report",
        "- BossCat OEM: Make final gate decision"
    ]

    markdown = "\n".join(lines)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as handle:
        handle.write(markdown)
    print(f"ECRR report written to {args.output}")

    if args.pdf:
        os.makedirs(os.path.dirname(args.pdf), exist_ok=True)
        maybe_generate_pdf(markdown, args.pdf)

    return 0 if overall_status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
