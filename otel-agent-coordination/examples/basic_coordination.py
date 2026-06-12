"""
Basic coordination example - two agents coordinate through telemetry
"""
from otel_ops_pack.coordinator import TelemetryCoordinator
import time


def agent_a(coordinator: TelemetryCoordinator):
    """First agent - does work and emits telemetry"""
    print("Agent A: Starting work...")
    
    # Simulate work
    time.sleep(1)
    
    # Emit completion via telemetry
    coordinator.emit_task_complete(
        task_name="data_processing",
        agent_id="agent-a",
        attributes={"records_processed": 1000}
    )
    
    print("Agent A: Work complete, telemetry emitted")


def agent_b(coordinator: TelemetryCoordinator):
    """Second agent - waits for Agent A by querying telemetry"""
    print("Agent B: Waiting for Agent A to complete...")
    
    # Poll telemetry for Agent A's completion
    max_attempts = 10
    for i in range(max_attempts):
        if coordinator.check_task_complete("data_processing", "agent-a"):
            print("Agent B: Agent A completed, proceeding with my work")
            break
        print(f"Agent B: Still waiting... (attempt {i+1}/{max_attempts})")
        time.sleep(1)
    else:
        print("Agent B: Timeout waiting for Agent A")
        return
    
    # Do Agent B's work
    print("Agent B: Doing my work now...")
    time.sleep(1)
    
    coordinator.emit_task_complete(
        task_name="report_generation",
        agent_id="agent-b",
        attributes={"report_created": True}
    )
    
    print("Agent B: Complete!")


if __name__ == "__main__":
    # Initialize coordinator
    coordinator = TelemetryCoordinator(
        query_endpoint="http://localhost:8080",  # SignOz endpoint
        otel_endpoint="http://localhost:4317"
    )
    
    print("=== Basic Coordination Example ===\n")
    
    # Run agents
    agent_a(coordinator)
    agent_b(coordinator)
    
    print("\n=== Example Complete ===")
    print("Check your telemetry backend to see the spans!")
