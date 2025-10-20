#!/usr/bin/env python3
"""
Synthetic OTLP log sender (local, deterministic).
- Sends logs to OTLP HTTP (default :14318) or gRPC (:14317)
- Prints a one-line JSON summary for each run (label/run/sent/rate)
- Use fixed window to compute logs/sec locally; SigNoz will record visibility.
"""
import argparse, json, logging, os, sys, time, uuid
from datetime import datetime

# --- OpenTelemetry logs setup ---
from opentelemetry.sdk.resources import Resource
from opentelemetry._logs import set_logger_provider, get_logger
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor

def build_exporter(protocol: str, endpoint: str):
    if protocol == "grpc":
        # grpc exporter
        try:
            from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
        except ImportError:
            from opentelemetry.exporter.otlp.proto.grpc.log_exporter import OTLPLogExporter
        # endpoint example: http://localhost:14317
        return OTLPLogExporter(endpoint=endpoint)
    else:
        # http/protobuf exporter
        try:
            from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter
        except ImportError:
            from opentelemetry.exporter.otlp.proto.http.log_exporter import OTLPLogExporter
        # endpoint example: http://localhost:14318/v1/logs
        return OTLPLogExporter(endpoint=endpoint)

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--label", required=True, help="baseline|new|<any tag>")
    ap.add_argument("--run", type=int, required=True)
    ap.add_argument("--duration", type=int, default=60, help="seconds (default 60)")
    ap.add_argument("--rate", type=float, default=0.0, help="target logs/sec (0 = as fast as possible)")
    ap.add_argument("--protocol", choices=["http", "grpc"], default="http")
    ap.add_argument("--endpoint", default="", help="override exporter endpoint")
    ap.add_argument("--service-name", default="synthetic-windows-check")
    return ap.parse_args()

def main():
    args = parse_args()
    run_id = str(uuid.uuid4())
    now_iso = datetime.utcnow().isoformat(timespec="seconds") + "Z"

    # Endpoint defaults
    if args.protocol == "http":
        endpoint = args.endpoint or "http://localhost:14318/v1/logs"
    else:
        endpoint = args.endpoint or "http://localhost:14317"

    # OTel setup
    resource = Resource.create({
        "service.name": args.service_name,
        "service.instance.id": run_id,
        "synthetic.label": args.label,
        "synthetic.run": str(args.run),
    })
    logger_provider = LoggerProvider(resource=resource)
    exporter = build_exporter("grpc" if args.protocol == "grpc" else "http", endpoint)
    logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))
    set_logger_provider(logger_provider)

    # Python logging bridged to OTel logs
    handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)
    pylog = logging.getLogger("synthetic")
    pylog.handlers.clear()
    pylog.addHandler(handler)
    pylog.setLevel(logging.INFO)

    # Emit logs for a fixed window
    start = time.monotonic()
    deadline = start + args.duration
    sent = 0
    # warmup marker
    pylog.info("synthetic.start",
               extra={"otel.attributes": {"run_id": run_id, "label": args.label, "phase": "start", "ts": now_iso}})
    while True:
        now = time.monotonic()
        if now >= deadline:
            break
        # payload
        pylog.info("synthetic.log",
                   extra={"otel.attributes": {
                       "run_id": run_id,
                       "label": args.label,
                       "seq": sent,
                       "ts": datetime.utcnow().isoformat(timespec="milliseconds") + "Z"
                   }})
        sent += 1
        if args.rate > 0:
            # simple rate control: sleep to match target rate
            next_due = start + (sent / args.rate)
            to_sleep = max(0.0, next_due - time.monotonic())
            if to_sleep > 0:
                time.sleep(to_sleep)

    # end marker
    pylog.info("synthetic.end",
               extra={"otel.attributes": {"run_id": run_id, "label": args.label, "phase": "end",
                                          "sent": sent, "duration": args.duration}})
    # flush & shutdown
    logger_provider.shutdown()

    rate = sent / float(args.duration) if args.duration > 0 else float("nan")
    summary = {
        "result": "OK",
        "label": args.label,
        "run": args.run,
        "protocol": args.protocol,
        "endpoint": endpoint,
        "sent": sent,
        "duration_s": args.duration,
        "rate_logs_per_s": round(rate, 3),
        "service_name": args.service_name,
        "run_id": run_id,
        "ts_utc": now_iso
    }
    print(json.dumps(summary), file=sys.stdout)
    return 0

if __name__ == "__main__":
    sys.exit(main())

