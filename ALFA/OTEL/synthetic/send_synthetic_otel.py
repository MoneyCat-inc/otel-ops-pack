import time
from opentelemetry import trace, _logs
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry._logs.severity import SeverityNumber

SERVICE_NAME = "synthetic-windows-check"
ENDPOINT = "http://localhost:4317"   # your collector gRPC

res = Resource.create({
    "service.name": SERVICE_NAME,
    "service.namespace": "boss-cat",
    "deployment.environment": "production",
    "host.platform": "windows",
})

# Traces
tp = TracerProvider(resource=res)
tp.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=ENDPOINT, insecure=True)))
trace.set_tracer_provider(tp)
tracer = trace.get_tracer(__name__)

# Logs
lp = LoggerProvider(resource=res)
lp.add_log_record_processor(BatchLogRecordProcessor(OTLPLogExporter(endpoint=ENDPOINT, insecure=True)))
_logs.set_logger_provider(lp)
logger = lp.get_logger("synthetic-logger")

with tracer.start_as_current_span("bc.synthetic.root") as span:
    span.set_attribute("check.kind", "gate-verification")
    span.set_attribute("component", "windows-collector")
    logger.emit(
        body="Synthetic log from BossCat gate verification",
        severity=SeverityNumber.INFO,
        attributes={"component": "windows-collector"}
    )
    time.sleep(0.2)
    with tracer.start_as_current_span("bc.synthetic.child") as cspan:
        cspan.set_attribute("child.step", "inner-op")
        time.sleep(0.1)

# flush
time.sleep(1.0)
print("Sent synthetic trace + log to", ENDPOINT, "as service:", SERVICE_NAME)
