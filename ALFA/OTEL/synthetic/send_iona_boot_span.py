#!/usr/bin/env python3
"""
IONA Boot Span Generator
Emits a synthetic iona.boot span to verify IONA telemetry integration

Part of: IONA-PR-01 - UI Snapshot Integration
Gate: BossCat Gate Verify
Service: iona-app
"""

import os
import time
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource

def main():
    # Configure OTLP endpoint (default to local collector)
    otlp_endpoint = os.getenv('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://127.0.0.1:4318')
    
    print(f"[iona-boot] Initializing OTLP exporter...")
    print(f"[iona-boot] Endpoint: {otlp_endpoint}")
    
    # Create resource with IONA service attributes
    resource = Resource.create({
        "service.name": "iona-app",
        "service.version": "1.0.0",
        "deployment.environment": "local",
        "telemetry.sdk.name": "opentelemetry",
        "telemetry.sdk.language": "python",
        "telemetry.sdk.version": "1.20.0"
    })
    
    # Set up tracer provider
    provider = TracerProvider(resource=resource)
    
    # Configure OTLP exporter
    otlp_exporter = OTLPSpanExporter(
        endpoint=f"{otlp_endpoint.rstrip('/')}/v1/traces"
    )
    
    # Add span processor
    span_processor = BatchSpanProcessor(otlp_exporter)
    provider.add_span_processor(span_processor)
    
    # Set as global tracer provider
    trace.set_tracer_provider(provider)
    
    # Get tracer
    tracer = trace.get_tracer(__name__)
    
    print("[iona-boot] Emitting iona.boot span...")
    
    # Create iona.boot span
    with tracer.start_as_current_span("iona.boot") as span:
        span.set_attribute("app.name", "iona-app")
        span.set_attribute("app.component", "frontend")
        span.set_attribute("boot.phase", "initialization")
        span.set_attribute("boot.timestamp", int(time.time() * 1000))
        span.set_attribute("gate.test", "bosscat-verify")
        span.set_attribute("synthetic", True)
        
        print("[iona-boot] [OK] Span attributes set")
        
        # Simulate boot time
        time.sleep(0.1)
        
        span.add_event("iona.boot.complete", {
            "duration_ms": 100,
            "status": "success"
        })
    
    # Force flush to ensure span is sent
    provider.force_flush()
    
    print("[iona-boot] [OK] Span emitted successfully")
    print(f"[iona-boot] Service: iona-app")
    print(f"[iona-boot] Span: iona.boot")
    print(f"[iona-boot] Endpoint: {otlp_endpoint}")

if __name__ == "__main__":
    main()

