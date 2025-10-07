#!/usr/bin/env python3
"""
BossCat Synthetic OTLP Trace Generator
Generates synthetic traces for gate verification testing
"""

import argparse
import time
import random
import uuid
from typing import List, Dict, Any
import logging

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter as OTLPHTTPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.semconv.resource import ResourceAttributes
from opentelemetry.semconv.trace import SpanAttributes

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BossCatSyntheticTraceGenerator:
    """Generates synthetic traces for BossCat gate verification"""
    
    def __init__(self, endpoint: str, service_name: str = "bosscat-synthetic", protocol: str = "grpc", insecure: bool = True):
        self.endpoint = endpoint
        self.service_name = service_name
        self.protocol = protocol.lower()
        self.insecure = insecure
        self.setup_tracer()
    
    def setup_tracer(self):
        """Setup OpenTelemetry tracer with OTLP exporter"""
        # Create resource
        resource = Resource.create({
            ResourceAttributes.SERVICE_NAME: self.service_name,
            ResourceAttributes.SERVICE_VERSION: "1.0.0",
            ResourceAttributes.DEPLOYMENT_ENVIRONMENT: "bosscat-testing",
        })
        
        # Create tracer provider
        tracer_provider = TracerProvider(resource=resource)
        
        # Create OTLP exporter based on protocol
        if self.protocol == "http":
            otlp_exporter = OTLPHTTPSpanExporter(
                endpoint=self.endpoint,
            )
        else:  # Default to gRPC
            otlp_exporter = OTLPSpanExporter(
                endpoint=self.endpoint,
                insecure=self.insecure,
            )
        
        # Create span processor
        span_processor = BatchSpanProcessor(otlp_exporter)
        tracer_provider.add_span_processor(span_processor)
        
        # Set global tracer provider
        trace.set_tracer_provider(tracer_provider)
        
        self.tracer = trace.get_tracer(__name__)
        logger.info(f"Tracer setup complete for service: {self.service_name}")
    
    def generate_synthetic_trace(self, trace_id: str = None) -> str:
        """Generate a single synthetic trace with root and child spans"""
        if not trace_id:
            trace_id = str(uuid.uuid4())
        
        with self.tracer.start_as_current_span(
            "bc.synthetic.root",
            attributes={
                SpanAttributes.HTTP_METHOD: "POST",
                SpanAttributes.HTTP_URL: f"{self.endpoint}/api/v1/traces",
                "test.type": "synthetic",
                "test.scenario": "gate_verification",
                "bosscat.trace_id": trace_id,
            }
        ) as root_span:
            root_span.set_status(trace.Status(trace.StatusCode.OK))
            
            # Add some processing time
            time.sleep(random.uniform(0.01, 0.05))
            
            # Create child span
            with self.tracer.start_as_current_span(
                "bc.synthetic.child",
                attributes={
                    SpanAttributes.HTTP_STATUS_CODE: 200,
                    "test.child_operation": "data_processing",
                    "bosscat.child_id": str(uuid.uuid4()),
                }
            ) as child_span:
                child_span.set_status(trace.Status(trace.StatusCode.OK))
                
                # Simulate some work
                time.sleep(random.uniform(0.005, 0.02))
                
                # Add some events
                child_span.add_event("processing_started", {
                    "timestamp": time.time(),
                    "data_size": random.randint(100, 1000),
                })
                
                time.sleep(random.uniform(0.01, 0.03))
                
                child_span.add_event("processing_completed", {
                    "timestamp": time.time(),
                    "processed_records": random.randint(10, 100),
                })
        
        logger.info(f"Generated synthetic trace: {trace_id}")
        return trace_id
    
    def generate_trace_batch(self, count: int = 10) -> List[str]:
        """Generate a batch of synthetic traces"""
        trace_ids = []
        logger.info(f"Generating {count} synthetic traces...")
        
        for i in range(count):
            trace_id = self.generate_synthetic_trace()
            trace_ids.append(trace_id)
            
            # Small delay between traces
            time.sleep(random.uniform(0.1, 0.3))
        
        logger.info(f"Generated {len(trace_ids)} synthetic traces")
        return trace_ids
    
    def generate_canary_trace(self) -> str:
        """Generate a canary test trace"""
        trace_id = str(uuid.uuid4())
        
        with self.tracer.start_as_current_span(
            "bc.canary.test",
            attributes={
                "test.type": "canary",
                "test.scenario": "health_check",
                "bosscat.canary_id": trace_id,
                "canary.version": "1.0.0",
                "canary.environment": "bosscat-testing",
            }
        ) as span:
            span.set_status(trace.Status(trace.StatusCode.OK))
            
            # Simulate canary test operations
            time.sleep(random.uniform(0.02, 0.08))
            
            span.add_event("canary_test_started", {
                "timestamp": time.time(),
                "test_suite": "gate_verification",
            })
            
            time.sleep(random.uniform(0.01, 0.05))
            
            span.add_event("canary_test_passed", {
                "timestamp": time.time(),
                "test_result": "success",
            })
        
        logger.info(f"Generated canary trace: {trace_id}")
        return trace_id

def main():
    parser = argparse.ArgumentParser(description="BossCat Synthetic OTLP Trace Generator")
    parser.add_argument(
        "--endpoint",
        required=True,
        help="OTLP endpoint URL (e.g., http://localhost:4317)"
    )
    parser.add_argument(
        "--protocol",
        choices=["grpc", "http"],
        default="grpc",
        help="OTLP protocol to use (default: grpc)"
    )
    parser.add_argument(
        "--secure",
        action="store_true",
        help="Use secure connection (default: insecure for local testing)"
    )
    parser.add_argument(
        "--service-name",
        default="bosscat-synthetic",
        help="Service name for traces"
    )
    parser.add_argument(
        "--trace-count",
        type=int,
        default=10,
        help="Number of traces to generate"
    )
    parser.add_argument(
        "--canary",
        action="store_true",
        help="Generate canary test trace"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Create trace generator
    generator = BossCatSyntheticTraceGenerator(
        endpoint=args.endpoint,
        service_name=args.service_name,
        protocol=args.protocol,
        insecure=not args.secure
    )
    
    try:
        if args.canary:
            # Generate canary trace
            trace_id = generator.generate_canary_trace()
            print(f"[OK] Canary trace generated: {trace_id}")
        else:
            # Generate batch of traces
            trace_ids = generator.generate_trace_batch(args.trace_count)
            print(f"[OK] Generated {len(trace_ids)} synthetic traces")
            print(f"Trace IDs: {', '.join(trace_ids[:5])}{'...' if len(trace_ids) > 5 else ''}")
        
        # Wait for traces to be exported
        logger.info("Waiting for traces to be exported...")
        time.sleep(2)
        
    except Exception as e:
        logger.error(f"Error generating traces: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
