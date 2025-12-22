"""
TelemetryCoordinator - Core coordination layer for agents
"""
from typing import Optional, Dict, Any
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
import requests


class TelemetryCoordinator:
    """Coordinator for agent communication through telemetry"""
    
    def __init__(
        self,
        query_endpoint: str,
        otel_endpoint: str = "http://localhost:4317",
        service_name: str = "agent-coordinator"
    ):
        """
        Initialize coordinator
        
        Args:
            query_endpoint: Telemetry backend query endpoint (e.g., SigNoz)
            otel_endpoint: OpenTelemetry collector endpoint
            service_name: Service name for telemetry
        """
        self.query_endpoint = query_endpoint
        self.otel_endpoint = otel_endpoint
        self.service_name = service_name
        
        # Initialize OpenTelemetry
        self._setup_telemetry()
    
    def _setup_telemetry(self) -> None:
        """Initialize OpenTelemetry tracer"""
        provider = TracerProvider()
        processor = BatchSpanProcessor(
            OTLPSpanExporter(endpoint=self.otel_endpoint)
        )
        provider.add_span_processor(processor)
        trace.set_tracer_provider(provider)
        self.tracer = trace.get_tracer(self.service_name)
    
    def check_task_complete(
        self,
        task_name: str,
        agent_id: Optional[str] = None
    ) -> bool:
        """
        Check if a task has been completed by querying telemetry
        
        Args:
            task_name: Name of the task to check
            agent_id: Optional agent ID to filter by
            
        Returns:
            True if task is complete, False otherwise
        """
        query = {
            "span_name": task_name,
            "status": "complete"
        }
        if agent_id:
            query["agent.id"] = agent_id
        
        try:
            response = requests.post(
                f"{self.query_endpoint}/api/v1/query",
                json=query,
                timeout=5
            )
            return response.status_code == 200 and len(response.json()) > 0
        except Exception as e:
            print(f"Error querying telemetry: {e}")
            return False
    
    def emit_task_complete(
        self,
        task_name: str,
        agent_id: str,
        attributes: Optional[Dict[str, Any]] = None
    ) -> None:
        """
        Emit a task completion event via telemetry
        
        Args:
            task_name: Name of the completed task
            agent_id: ID of the agent completing the task
            attributes: Additional attributes to attach
        """
        with self.tracer.start_as_current_span(task_name) as span:
            span.set_attribute("agent.id", agent_id)
            span.set_attribute("task.status", "complete")
            
            if attributes:
                for key, value in attributes.items():
                    span.set_attribute(key, value)
