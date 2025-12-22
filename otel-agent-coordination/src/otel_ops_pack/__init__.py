"""
otel-ops-pack: Telemetry-based AI agent coordination framework
"""
from otel_ops_pack.coordinator.coordinator import TelemetryCoordinator
from otel_ops_pack.gates.gate import BossCatGate, GateResult

__version__ = "0.1.0"
__all__ = ["TelemetryCoordinator", "BossCatGate", "GateResult"]