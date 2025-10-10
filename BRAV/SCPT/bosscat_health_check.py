#!/usr/bin/env python3
"""Quick health check for SigNoz endpoints and ports."""

import argparse
import socket
import sys
from typing import Tuple

import requests


def check_port(host: str, port: int, timeout: float = 2.0) -> Tuple[bool, str]:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        try:
            sock.connect((host, port))
            return True, "open"
        except Exception as exc:  # noqa: BLE001
            return False, str(exc)


def check_http(url: str, timeout: float = 5.0) -> Tuple[bool, str]:
    try:
        response = requests.get(url, timeout=timeout)
        response.raise_for_status()
        return True, f"HTTP {response.status_code}"
    except Exception as exc:  # noqa: BLE001
        return False, str(exc)


def main() -> int:
    parser = argparse.ArgumentParser(description="BossCat SigNoz health check")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--signoz-url", default="http://127.0.0.1:8080")
    args = parser.parse_args()

    ports = [4317, 4318, 13134, 55679]
    failures = 0

    print("[CHECK] Port connectivity")
    for port in ports:
        ok, message = check_port(args.host, port)
        status = "OK" if ok else "FAIL"
        print(f"- {status:4} port {port}: {message}")
        if not ok:
            failures += 1

    print("\n[CHECK] SigNoz health endpoint")
    ok, message = check_http(f"{args.signoz_url.rstrip('/')}/api/v1/health")
    status = "OK" if ok else "FAIL"
    print(f"- {status:4} health: {message}")
    if not ok:
        failures += 1

    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
