"""
BossCat Gate - Evidence-based quality checkpoints
"""
from typing import Dict, Any, List
from dataclasses import dataclass
import yaml


@dataclass
class GateResult:
    """Result of gate evaluation"""
    status: str  # GREEN, AMBER, RED
    passed: bool
    evidence: List[Dict[str, Any]]
    missing_requirements: List[str]


class BossCatGate:
    """Evidence-based gate for agent quality control"""
    
    def __init__(self, config: Dict[str, Any]):
        self.name = config.get("name", "unnamed_gate")
        self.description = config.get("description", "")
        self.requirements = config.get("requirements", [])
    
    @classmethod
    def from_yaml(cls, filepath: str) -> "BossCatGate":
        """Load gate configuration from YAML file"""
        with open(filepath, 'r') as f:
            config = yaml.safe_load(f)
        return cls(config)
    
    def evaluate(self, task_id: str, coordinator: Any) -> GateResult:
        """
        Evaluate gate by checking for required evidence
        
        Args:
            task_id: ID of task to evaluate
            coordinator: TelemetryCoordinator instance for queries
            
        Returns:
            GateResult with status and evidence
        """
        evidence = []
        missing = []
        
        for req in self.requirements:
            req_name = req.get("name")
            has_evidence = coordinator.check_task_complete(
                req.get("span_name", req_name),
                task_id
            )
            
            if has_evidence:
                evidence.append({"requirement": req_name, "met": True})
            else:
                missing.append(req_name)
        
        # Determine status
        if not missing:
            status = "GREEN"
            passed = True
        elif len(missing) < len(self.requirements):
            status = "AMBER"
            passed = False
        else:
            status = "RED"
            passed = False
        
        return GateResult(
            status=status,
            passed=passed,
            evidence=evidence,
            missing_requirements=missing
        )
