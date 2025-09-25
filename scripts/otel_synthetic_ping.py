#!/usr/bin/env python3
"""
Synthetic Telemetry Ping Script
Emits OTLP metrics, logs, and traces to verify the full observability pipeline.
Part of the push-button automation system.
"""

import json
import time
import uuid
import requests
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SyntheticTelemetryPing:
    def __init__(self, otlp_endpoint: str = "http://localhost:5318"):
        self.otlp_endpoint = otlp_endpoint
        self.session_id = str(uuid.uuid4())
        self.ping_id = str(uuid.uuid4())
        
    def emit_log(self, message: str, level: str = "INFO", **attributes) -> bool:
        """Emit a synthetic log entry via OTLP HTTP"""
        try:
            timestamp_ns = int(time.time() * 1_000_000_000)
            
            log_data = {
                "resourceLogs": [{
                    "resource": {
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "synthetic-ping"}},
                            {"key": "service.namespace", "value": {"stringValue": "observability"}},
                            {"key": "deployment.environment", "value": {"stringValue": "local-dev"}},
                            {"key": "host.name", "value": {"stringValue": "windows-host"}}
                        ]
                    },
                    "scopeLogs": [{
                        "scope": {"name": "synthetic-ping", "version": "1.0.0"},
                        "logRecords": [{
                            "timeUnixNano": str(timestamp_ns),
                            "observedTimeUnixNano": str(timestamp_ns),
                            "severityText": level,
                            "severityNumber": self._get_severity_number(level),
                            "body": {"stringValue": message},
                            "attributes": [
                                {"key": "synthetic_id", "value": {"stringValue": self.ping_id}},
                                {"key": "session_id", "value": {"stringValue": self.session_id}},
                                {"key": "canary", "value": {"stringValue": "true"}},
                                {"key": "dataset", "value": {"stringValue": "synthetic"}},
                                {"key": "source", "value": {"stringValue": "python-ping"}},
                                {"key": "timestamp", "value": {"stringValue": datetime.now(timezone.utc).isoformat()}}
                            ] + [{"key": k, "value": {"stringValue": str(v)}} for k, v in attributes.items()]
                        }]
                    }]
                }]
            }
            
            response = requests.post(
                f"{self.otlp_endpoint}/v1/logs",
                json=log_data,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"✅ Log emitted successfully: {message}")
                return True
            else:
                logger.error(f"❌ Log emission failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Log emission error: {e}")
            return False
    
    def emit_metric(self, name: str, value: float, unit: str = "", **attributes) -> bool:
        """Emit a synthetic metric via OTLP HTTP"""
        try:
            timestamp_ns = int(time.time() * 1_000_000_000)
            
            metric_data = {
                "resourceMetrics": [{
                    "resource": {
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "synthetic-ping"}},
                            {"key": "service.namespace", "value": {"stringValue": "observability"}},
                            {"key": "deployment.environment", "value": {"stringValue": "local-dev"}},
                            {"key": "host.name", "value": {"stringValue": "windows-host"}}
                        ]
                    },
                    "scopeMetrics": [{
                        "scope": {"name": "synthetic-ping", "version": "1.0.0"},
                        "metrics": [{
                            "name": name,
                            "description": f"Synthetic metric: {name}",
                            "unit": unit,
                            "gauge": {
                                "dataPoints": [{
                                    "timeUnixNano": str(timestamp_ns),
                                    "asDouble": value,
                                    "attributes": [
                                        {"key": "synthetic_id", "value": {"stringValue": self.ping_id}},
                                        {"key": "session_id", "value": {"stringValue": self.session_id}},
                                        {"key": "canary", "value": {"stringValue": "true"}},
                                        {"key": "dataset", "value": {"stringValue": "synthetic"}},
                                        {"key": "source", "value": {"stringValue": "python-ping"}}
                                    ] + [{"key": k, "value": {"stringValue": str(v)}} for k, v in attributes.items()]
                                }]
                            }
                        }]
                    }]
                }]
            }
            
            response = requests.post(
                f"{self.otlp_endpoint}/v1/metrics",
                json=metric_data,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"✅ Metric emitted successfully: {name}={value}")
                return True
            else:
                logger.error(f"❌ Metric emission failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Metric emission error: {e}")
            return False
    
    def emit_trace(self, operation_name: str, duration_ms: float, **attributes) -> bool:
        """Emit a synthetic trace via OTLP HTTP"""
        try:
            timestamp_ns = int(time.time() * 1_000_000_000)
            trace_id = uuid.uuid4().hex
            span_id = uuid.uuid4().hex[:16]
            
            trace_data = {
                "resourceSpans": [{
                    "resource": {
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "synthetic-ping"}},
                            {"key": "service.namespace", "value": {"stringValue": "observability"}},
                            {"key": "deployment.environment", "value": {"stringValue": "local-dev"}},
                            {"key": "host.name", "value": {"stringValue": "windows-host"}}
                        ]
                    },
                    "scopeSpans": [{
                        "scope": {"name": "synthetic-ping", "version": "1.0.0"},
                        "spans": [{
                            "traceId": trace_id,
                            "spanId": span_id,
                            "name": operation_name,
                            "kind": "SPAN_KIND_INTERNAL",
                            "startTimeUnixNano": str(timestamp_ns),
                            "endTimeUnixNano": str(timestamp_ns + int(duration_ms * 1_000_000)),
                            "status": {"code": "STATUS_CODE_OK"},
                            "attributes": [
                                {"key": "synthetic_id", "value": {"stringValue": self.ping_id}},
                                {"key": "session_id", "value": {"stringValue": self.session_id}},
                                {"key": "canary", "value": {"stringValue": "true"}},
                                {"key": "dataset", "value": {"stringValue": "synthetic"}},
                                {"key": "source", "value": {"stringValue": "python-ping"}},
                                {"key": "duration_ms", "value": {"doubleValue": duration_ms}}
                            ] + [{"key": k, "value": {"stringValue": str(v)}} for k, v in attributes.items()]
                        }]
                    }]
                }]
            }
            
            response = requests.post(
                f"{self.otlp_endpoint}/v1/traces",
                json=trace_data,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"✅ Trace emitted successfully: {operation_name} ({duration_ms}ms)")
                return True
            else:
                logger.error(f"❌ Trace emission failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Trace emission error: {e}")
            return False
    
    def _get_severity_number(self, level: str) -> int:
        """Convert log level to OTLP severity number"""
        severity_map = {
            "TRACE": 1, "DEBUG": 5, "INFO": 9, "WARN": 13, "ERROR": 17, "FATAL": 21
        }
        return severity_map.get(level.upper(), 9)
    
    def ping(self) -> Dict[str, bool]:
        """Emit a complete synthetic telemetry ping"""
        logger.info(f"🚀 Starting synthetic telemetry ping (session: {self.session_id})")
        
        results = {}
        
        # Emit log
        results["log"] = self.emit_log(
            f"Synthetic ping from Python script - session {self.session_id}",
            level="INFO",
            ping_type="python-script",
            version="1.0.0"
        )
        
        # Emit metric
        results["metric"] = self.emit_metric(
            "synthetic_ping_counter",
            value=1.0,
            unit="1",
            ping_type="python-script",
            version="1.0.0"
        )
        
        # Emit trace
        results["trace"] = self.emit_trace(
            "synthetic_ping_operation",
            duration_ms=25.5,
            ping_type="python-script",
            version="1.0.0"
        )
        
        # Summary
        success_count = sum(results.values())
        total_count = len(results)
        
        if success_count == total_count:
            logger.info(f"🎉 Synthetic ping completed successfully ({success_count}/{total_count})")
        else:
            logger.warning(f"⚠️  Synthetic ping partially successful ({success_count}/{total_count})")
        
        return results

def main():
    """Main entry point for the synthetic ping script"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Emit synthetic telemetry to verify OTLP pipeline")
    parser.add_argument("--endpoint", default="http://localhost:5318", 
                       help="OTLP HTTP endpoint (default: http://localhost:5318)")
    parser.add_argument("--count", type=int, default=1, 
                       help="Number of pings to emit (default: 1)")
    parser.add_argument("--interval", type=float, default=1.0, 
                       help="Interval between pings in seconds (default: 1.0)")
    parser.add_argument("--verbose", action="store_true", 
                       help="Enable verbose logging")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    ping = SyntheticTelemetryPing(args.endpoint)
    
    logger.info(f"🎯 Starting {args.count} synthetic ping(s) to {args.endpoint}")
    
    for i in range(args.count):
        if i > 0:
            logger.info(f"⏳ Waiting {args.interval}s before next ping...")
            time.sleep(args.interval)
        
        logger.info(f"📡 Ping {i+1}/{args.count}")
        results = ping.ping()
        
        # Brief summary
        success_count = sum(results.values())
        logger.info(f"   Result: {success_count}/{len(results)} telemetry types successful")
    
    logger.info("🏁 Synthetic ping script completed")

if __name__ == "__main__":
    main()




