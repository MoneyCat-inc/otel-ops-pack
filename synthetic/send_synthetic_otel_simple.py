import time
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

SERVICE_NAME = "synthetic-windows-check"
ENDPOINT = "http://localhost:4317"   # your collector gRPC

res = Resource.create({
    "service.name": SERVICE_NAME,
    "service.namespace": "boss-cat",
    "deployment.environment": "production",
    "host.platform": "windows",
})

# Traces only for now
tp = TracerProvider(resource=res)
tp.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=ENDPOINT, insecure=True)))
trace.set_tracer_provider(tp)
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("bc.synthetic.root") as span:
    span.set_attribute("check.kind", "gate-verification")
    span.set_attribute("component", "windows-collector")
    span.set_attribute("test.type", "end-to-end-verification")
    time.sleep(0.2)
    with tracer.start_as_current_span("bc.synthetic.child") as cspan:
        cspan.set_attribute("child.step", "inner-op")
        cspan.set_attribute("child.duration", "100ms")
        time.sleep(0.1)

# flush
time.sleep(2.0)
print("SUCCESS: Sent synthetic trace to", ENDPOINT, "as service:", SERVICE_NAME)
print("   - Root span: bc.synthetic.root")
print("   - Child span: bc.synthetic.child")
print("   - Check SigNoz UI for service:", SERVICE_NAME)
