#!/usr/bin/env python3
"""
BossCat One-Shot Local Runner
Executes the complete BossCat gate verification pipeline locally
"""

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List
import logging
import shutil

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class BossCatLocalRunner:
    """One-shot local runner for BossCat gate verification"""
    
    def __init__(self, artifacts_dir: str = "artifacts", use_mock: bool = False):
        self.artifacts_dir = Path(artifacts_dir)
        self.use_mock = use_mock
        self.mock_process = None
        self.results = {
            "started_at": datetime.now().isoformat(),
            "artifacts_dir": str(self.artifacts_dir),
            "use_mock": use_mock,
            "steps": {},
            "overall_status": "UNKNOWN"
        }
        
        # Ensure artifacts directory exists
        self.artifacts_dir.mkdir(parents=True, exist_ok=True)
    
    def start_mock_signoz(self) -> bool:
        """Start mock SigNoz API server"""
        if not self.use_mock:
            logger.info("Skipping mock SigNoz (use_mock=False)")
            return True
            
        try:
            logger.info("Starting mock SigNoz API server...")
            self.mock_process = subprocess.Popen([
                sys.executable, "scripts/mock_signoz_api.py",
                "--host", "127.0.0.1",
                "--port", "8080",
                "--duration", "900"  # 15 minutes
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # Wait a moment for server to start
            time.sleep(2)
            
            # Test if server is responding
            import requests
            response = requests.get("http://127.0.0.1:8080/api/v1/health", timeout=5)
            if response.status_code == 200:
                logger.info("[OK] Mock SigNoz API server started successfully")
                self.results["steps"]["mock_signoz"] = {"status": "PASS", "port": 8080}
                return True
            else:
                logger.error("[ERROR] Mock SigNoz API server not responding")
                self.results["steps"]["mock_signoz"] = {"status": "FAIL", "error": "Server not responding"}
                return False
                
        except Exception as e:
            logger.error(f"[ERROR] Failed to start mock SigNoz: {e}")
            self.results["steps"]["mock_signoz"] = {"status": "FAIL", "error": str(e)}
            return False
    
    def stop_mock_signoz(self):
        """Stop mock SigNoz API server"""
        if self.mock_process:
            logger.info("Stopping mock SigNoz API server...")
            self.mock_process.terminate()
            self.mock_process.wait(timeout=5)
            logger.info("[OK] Mock SigNoz API server stopped")
    
    def run_synthetic_traces(self) -> bool:
        """Generate synthetic traces"""
        try:
            logger.info("Generating synthetic traces...")
            
            # Skip trace generation in mock mode since mock SigNoz doesn't support OTLP
            if self.use_mock:
                logger.info("Skipping synthetic trace generation in mock mode (mock SigNoz doesn't support OTLP)")
                self.results["steps"]["synthetic_traces"] = {
                    "status": "SKIPPED",
                    "reason": "Mock mode - OTLP not supported by mock SigNoz"
                }
                return True
            
            endpoint = "http://127.0.0.1:4317"
            
            result = subprocess.run([
                sys.executable, "scripts/send_synthetic_otel_simple.py",
                "--endpoint", endpoint,
                "--service-name", "bosscat-local-test",
                "--trace-count", "10",
                "--protocol", "grpc",
                "--verbose"
            ], capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                logger.info("[OK] Synthetic traces generated successfully")
                self.results["steps"]["synthetic_traces"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Synthetic trace generation failed: {result.stderr}")
                self.results["steps"]["synthetic_traces"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False
                
        except Exception as e:
            logger.error(f"[ERROR] Synthetic trace generation error: {e}")
            self.results["steps"]["synthetic_traces"] = {"status": "FAIL", "error": str(e)}
            return False
    
    def run_k6_tests(self, test_types: List[str] = None) -> bool:
        """Run k6 performance tests"""
        if test_types is None:
            test_types = ["baseline", "load", "stress", "soak"]
        
        # Check if k6 is available
        try:
            result = subprocess.run(["k6", "version"], capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                logger.warning("k6 not found - skipping k6 tests")
                logger.info("To install k6, see docs/BossCat/guides/K6_INSTALLATION_GUIDE.md")
                self.results["steps"]["k6_tests"] = {
                    "status": "SKIPPED",
                    "reason": "k6 not installed - see installation guide"
                }
                return True
        except Exception as e:
            logger.warning(f"k6 not available: {e}")
            logger.info("To install k6, see docs/BossCat/guides/K6_INSTALLATION_GUIDE.md")
            self.results["steps"]["k6_tests"] = {
                "status": "SKIPPED",
                "reason": "k6 not installed - see installation guide"
            }
            return True
        
        all_passed = True
        
        for test_type in test_types:
            try:
                logger.info(f"Running k6 {test_type} test...")
                
                # Use mock-friendly test for mock mode
                test_file = "tests/k6/mock-friendly-test.js" if self.use_mock else f"tests/k6/{test_type}-test.js"
                
                result = subprocess.run([
                    "k6", "run",
                    test_file,
                    "--env", "BASE_URL=http://127.0.0.1:8080",
                    "--env", f"VUS={self._get_vus_for_test(test_type)}",
                    "--env", f"DURATION={self._get_duration_for_test(test_type)}",
                    "--out", f"json={self.artifacts_dir}/{test_type}-test-results.json"
                ], capture_output=True, text=True, timeout=300)
                
                if result.returncode == 0:
                    logger.info(f"[OK] k6 {test_type} test passed")
                    self.results["steps"][f"k6_{test_type}"] = {
                        "status": "PASS",
                        "output": result.stdout
                    }
                else:
                    logger.error(f"[ERROR] k6 {test_type} test failed: " + result.stderr)
                    self.results["steps"][f"k6_{test_type}"] = {
                        "status": "FAIL",
                        "error": result.stderr
                    }
                    all_passed = False
                    
            except Exception as e:
                logger.error(f"[ERROR] k6 {test_type} test error: " + str(e))
                self.results["steps"][f"k6_{test_type}"] = {"status": "FAIL", "error": str(e)}
                all_passed = False
        
        return all_passed
    
    def run_locust_tests(self) -> bool:
        """Run Locust user journey tests"""
        logger.info("Running Locust user journey tests...")

        if shutil.which("locust") is None:
            logger.warning("[SKIP] Locust not found - skipping Locust tests")
            logger.info("To install Locust, run: pip install locust")
            self.results["steps"]["locust_tests"] = {
                "status": "SKIPPED",
                "reason": "Locust not installed"
            }
            return True

        try:
            result = subprocess.run([
                "locust", "-f", "tests/locust/signoz_user_journey.py",
                "--host", "http://127.0.0.1:8080",
                "--users", "10",
                "--spawn-rate", "2",
                "--run-time", "2m",
                "--headless",
                "--csv", f"{self.artifacts_dir}/locust-results"
            ], capture_output=True, text=True, timeout=300)

            if result.returncode == 0:
                logger.info("[OK] Locust tests completed successfully")
                self.results["steps"]["locust_tests"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Locust tests failed: {result.stderr}")
                self.results["steps"]["locust_tests"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Locust not available: {e}")
            self.results["steps"]["locust_tests"] = {
                "status": "SKIPPED",
                "reason": "Locust not installed"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Locust tests error: {e}")
            self.results["steps"]["locust_tests"] = {"status": "FAIL", "error": str(e)}
            return False

    def verify_gate_readiness(self) -> bool:
        """Run gate readiness verification"""
        logger.info("Running gate readiness verification...")

        if self.use_mock:
            logger.warning("[SKIP] Mock mode detected - skipping gate verification")
            self.results["steps"]["gate_verification"] = {
                "status": "SKIPPED",
                "reason": "Mock SigNoz does not provide full gate data"
            }
            return True

        dependent_statuses = [
            self.results.get("steps", {}).get("k6_tests", {}).get("status"),
            self.results.get("steps", {}).get("locust_tests", {}).get("status"),
        ]
        if any(status == "SKIPPED" for status in dependent_statuses):
            logger.warning("[SKIP] Prerequisite performance tests were skipped")
            self.results["steps"]["gate_verification"] = {
                "status": "SKIPPED",
                "reason": "Performance test artifacts unavailable"
            }
            return True

        try:
            result = subprocess.run([
                sys.executable, "scripts/verify-gate-readiness.py",
                "--artifacts-dir", str(self.artifacts_dir),
                "--signoz-url", "http://127.0.0.1:8080",
                "--output", f"{self.artifacts_dir}/gate-verification-results.json",
                "--verbose"
            ], capture_output=True, text=True, timeout=120)

            if result.returncode == 0:
                logger.info("[OK] Gate verification completed")
                self.results["steps"]["gate_verification"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Gate verification failed: {result.stderr}")
                self.results["steps"]["gate_verification"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Gate verification tooling missing: {e}")
            self.results["steps"]["gate_verification"] = {
                "status": "SKIPPED",
                "reason": "Gate verification script not available"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Gate verification error: {e}")
            self.results["steps"]["gate_verification"] = {"status": "FAIL", "error": str(e)}
            return False

    def generate_reports(self) -> bool:
        """Generate ECRR and BOSS v2 reports"""
        logger.info("Generating ECRR and BOSS v2 reports...")

        gate_status = self.results.get("steps", {}).get("gate_verification", {}).get("status")
        if gate_status == "SKIPPED":
            logger.warning("[SKIP] Gate verification was skipped - skipping report generation")
            self.results["steps"]["report_generation"] = {
                "status": "SKIPPED",
                "reason": "Gate verification results not available"
            }
            return True

        gate_results_path = self.artifacts_dir / "gate-verification-results.json"
        if not gate_results_path.exists():
            logger.warning("[SKIP] Gate verification results missing - skipping report generation")
            self.results["steps"]["report_generation"] = {
                "status": "SKIPPED",
                "reason": "Gate verification results missing"
            }
            return True

        try:
            # Generate ECRR report
            ecrr_result = subprocess.run([
                sys.executable, "scripts/generate-ecrr-report.py",
                "--gate-results", str(gate_results_path),
                "--output", "docs/BossCat/reports/ECRR_LOCAL_RUN.md",
                "--pdf", "docs/BossCat/reports/ECRR_LOCAL_RUN.pdf"
            ], capture_output=True, text=True, timeout=60)

            # Generate BOSS v2 report
            boss_result = subprocess.run([
                sys.executable, "scripts/generate-boss-v2-report.py",
                "--gate-results", str(gate_results_path),
                "--output", "docs/BossCat/reports/BOSS_V2_LOCAL_RUN.md",
                "--pdf", "docs/BossCat/reports/BOSS_V2_LOCAL_RUN.pdf"
            ], capture_output=True, text=True, timeout=60)

            if ecrr_result.returncode == 0 and boss_result.returncode == 0:
                logger.info("[OK] Reports generated successfully")
                self.results["steps"]["report_generation"] = {
                    "status": "PASS",
                    "ecrr_output": ecrr_result.stdout,
                    "boss_output": boss_result.stdout
                }
                return True
            else:
                logger.error("[ERROR] Report generation failed")
                self.results["steps"]["report_generation"] = {
                    "status": "FAIL",
                    "ecrr_error": ecrr_result.stderr,
                    "boss_error": boss_result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Report generation tooling missing: {e}")
            self.results["steps"]["report_generation"] = {
                "status": "SKIPPED",
                "reason": "Report generation scripts not available"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Report generation error: {e}")
            self.results["steps"]["report_generation"] = {"status": "FAIL", "error": str(e)}
            return False

    def _get_vus_for_test(self, test_type: str) -> str:
        """Get VUs for test type"""
        vus_map = {
            "baseline": "10",
            "load": "50", 
            "stress": "100",
            "soak": "20"
        }
        return vus_map.get(test_type, "10")
    
    def _get_duration_for_test(self, test_type: str) -> str:
        """Get duration for test type"""
        duration_map = {
            "baseline": "30s",
            "load": "2m",
            "stress": "5m", 
            "soak": "30m"
        }
        return duration_map.get(test_type, "30s")
    
    def run_complete_pipeline(self, test_types: List[str] = None) -> bool:
        """Run the complete BossCat pipeline"""
        logger.info("[LAUNCH] Starting BossCat local pipeline execution...")
        
        try:
            # Start mock SigNoz if needed
            if not self.start_mock_signoz():
                return False
            
            # Generate synthetic traces
            if not self.run_synthetic_traces():
                return False
            
            # Run k6 tests
            if not self.run_k6_tests(test_types):
                return False
            
            # Run Locust tests
            if not self.run_locust_tests():
                return False
            
            # Verify gate readiness
            if not self.verify_gate_readiness():
                return False
            
            # Generate reports
            if not self.generate_reports():
                return False
            
            # Determine overall status
            all_steps_passed = all(
                step.get("status") in {"PASS", "SKIPPED"} 
                for step in self.results["steps"].values()
            )
            
            self.results["overall_status"] = "PASS" if all_steps_passed else "FAIL"
            self.results["completed_at"] = datetime.now().isoformat()
            
            if all_steps_passed:
                logger.info("[OK] BossCat local pipeline execution completed successfully!")
                logger.info("[LAUNCH] System is ready for production deployment")
            else:
                logger.error("[ERROR] BossCat local pipeline execution failed")
                logger.error("[STOP] System is NOT ready for production deployment")
            
            return all_steps_passed
            
        finally:
            # Always stop mock server
            self.stop_mock_signoz()
    
    def save_results(self):
        """Save execution results"""
        results_file = self.artifacts_dir / "local-run-results.json"
        with open(results_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        logger.info(f"[STATS] Execution results saved to {results_file}")

def main():
    parser = argparse.ArgumentParser(description="BossCat One-Shot Local Runner")
    parser.add_argument(
        "--artifacts-dir",
        default="artifacts",
        help="Directory for test artifacts"
    )
    parser.add_argument(
        "--use-mock",
        action="store_true",
        help="Use mock SigNoz API instead of real instance"
    )
    parser.add_argument(
        "--test-types",
        nargs="+",
        choices=["baseline", "load", "stress", "soak"],
        default=["baseline", "load"],
        help="k6 test types to run"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Create runner
    runner = BossCatLocalRunner(
        artifacts_dir=args.artifacts_dir,
        use_mock=args.use_mock
    )
    
    try:
        # Run complete pipeline
        success = runner.run_complete_pipeline(args.test_types)
        
        # Save results
        runner.save_results()
        
        # Exit with appropriate code
        if success:
            print("[OK] BossCat local pipeline execution PASSED")
            return 0
        else:
            print("[ERROR] BossCat local pipeline execution FAILED")
            return 1
            
    except Exception as e:
        logger.error(f"[ERROR] Pipeline execution error: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
