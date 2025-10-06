#!/usr/bin/env python3
"""Simple mock SigNoz API for CI runs."""

import argparse
import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

MOCK_DATA = {
  "logs": {
    "data": [
      {
        "id": "mock-log-1",
        "timestamp": 0,
        "resource": {"service.name": "mock-service"},
        "attributes": {
          "message": "canary test log",
          "level": "info",
          "test.type": "canary"
        }
      },
      {
        "id": "mock-log-2",
        "timestamp": 0,
        "resource": {"service.name": "mock-service"},
        "attributes": {
          "message": "synthetic trace ingestion",
          "level": "info",
          "test.type": "synthetic"
        }
      }
    ]
  },
  "metrics": {
    "status": "ok",
    "series": [
      {
        "name": "otelcol_processor_batch_batch_send_size_sum",
        "points": [[0, 1.0]]
      }
    ]
  },
  "traces": {
    "data": [
      {
        "trace_id": "mock-trace-1",
        "span_id": "mock-span-1",
        "timestamp": 0,
        "attributes": {"test.type": "synthetic"}
      },
      {
        "trace_id": "mock-trace-2",
        "span_id": "mock-span-2",
        "timestamp": 0,
        "attributes": {"test.type": "canary"}
      }
    ]
  }
}


class MockHandler(BaseHTTPRequestHandler):
    server_version = "MockSigNoz/1.0"

    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

    def log_message(self, format, *args):
        return

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/v1/health":
            self._set_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode("utf-8"))
            return
        if parsed.path == "/api/v1/logs":
            self._set_headers()
            self.wfile.write(json.dumps(MOCK_DATA["logs"]).encode("utf-8"))
            return
        if parsed.path == "/api/v1/metrics":
            self._set_headers()
            self.wfile.write(json.dumps(MOCK_DATA["metrics"]).encode("utf-8"))
            return
        if parsed.path == "/api/v1/traces":
            self._set_headers()
            self.wfile.write(json.dumps(MOCK_DATA["traces"]).encode("utf-8"))
            return

        self._set_headers(404)
        self.wfile.write(json.dumps({"error": "not_found"}).encode("utf-8"))


def run_server(host: str, port: int):
    server = HTTPServer((host, port), MockHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, thread


def main() -> int:
    parser = argparse.ArgumentParser(description="Mock SigNoz API server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument(
        "--duration",
        type=int,
        default=0,
        help="Optional duration to run before exiting (seconds)"
    )
    args = parser.parse_args()

    server, thread = run_server(args.host, args.port)
    print(f"Mock SigNoz API listening on http://{args.host}:{args.port}")

    try:
        if args.duration > 0:
            thread.join(timeout=args.duration)
            server.shutdown()
        else:
            thread.join()
    except KeyboardInterrupt:
        server.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
