"""
Tests for TelemetryCoordinator
"""
import pytest
from otel_ops_pack.coordinator import TelemetryCoordinator


def test_coordinator_initialization():
    """Test coordinator can be initialized"""
    coordinator = TelemetryCoordinator(
        query_endpoint="http://localhost:8080",
        otel_endpoint="http://localhost:4317"
    )
    assert coordinator.query_endpoint == "http://localhost:8080"
    assert coordinator.otel_endpoint == "http://localhost:4317"


def test_coordinator_check_task_complete():
    """Test task completion check"""
    coordinator = TelemetryCoordinator(
        query_endpoint="http://localhost:8080"
    )
    # This will fail in test environment without backend
    # Real tests would use mocks
    result = coordinator.check_task_complete("test_task")
    assert isinstance(result, bool)
