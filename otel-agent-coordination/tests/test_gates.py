"""
Tests for BossCatGate
"""
import pytest
from otel_ops_pack.gates import BossCatGate, GateResult


def test_gate_initialization():
    """Test gate can be initialized"""
    config = {
        "name": "test_gate",
        "description": "Test gate",
        "requirements": []
    }
    gate = BossCatGate(config)
    assert gate.name == "test_gate"


def test_gate_result_structure():
    """Test GateResult dataclass"""
    result = GateResult(
        status="GREEN",
        passed=True,
        evidence=[],
        missing_requirements=[]
    )
    assert result.status == "GREEN"
    assert result.passed is True
