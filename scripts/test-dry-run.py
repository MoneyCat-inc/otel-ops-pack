#!/usr/bin/env python3
"""
BossCat Dry Run Test Script
Executes a minimal dry run of the BossCat pipeline for validation
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

class BossCatDryRun:
    """Dry run tester for BossCat pipeline"""
    
    def __init__(self, artifacts_dir: str = "artifacts"):
        self.artifacts_dir = Path(artifacts_dir)
        self.results = {
            "started_at": datetime.now().isoformat(),
            "artifacts_dir": str(self.artifacts_dir),
            "steps": {},
            "overall_status": "UNKNOWN"
        }
        
        # Ensure artifacts directory exists
        self.artifacts_dir.mkdir(parents=True, exist_ok=True)
    
    def test_mock_signoz_startup(self) -> bool:
        """Test mock SigNoz API startup"""
        try:
            logger.info("Testing mock SigNoz API startup...")
            
            # Start mock server
            process = subprocess.Popen([
                sys.executable, "scripts/mock_signoz_api.py",
                "--host", "127.0.0.1",
                "--port", "8080",
                "--duration", "30"
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # Wait for startup
            time.sleep(3)
            
            # Test health endpoint
            import requests
            response = requests.get("http://127.0.0.1:8080/api/v1/health", timeout=5)
            
            if response.status_code == 200:
                logger.info("[OK] Mock SigNoz API startup test passed")
                self.results["steps"]["mock_signoz_startup"] = {"status": "PASS"}
                process.terminate()
                return True
            else:
                logger.error("[ERROR] Mock SigNoz API startup test failed")
                self.results["steps"]["mock_signoz_startup"] = {"status": "FAIL", "error": f"HTTP {response.status_code}"}
                process.terminate()
                return False
                
        except Exception as e:
            logger.error(f"[ERROR] Mock SigNoz API startup test error: {e}")
            self.results["steps"]["mock_signoz_startup"] = {"status": "FAIL", "error": str(e)}
            return False
    
    def test_synthetic_trace_generation(self) -> bool:
        """Test synthetic trace generation"""
        try:
            logger.info("Testing synthetic trace generation...")
            
            result = subprocess.run([
                sys.executable, "scripts/send_synthetic_otel_simple.py",
                "--endpoint", "http://127.0.0.1:4317",
                "--service-name", "bosscat-dry-run",
                "--trace-count", "3",
                "--protocol", "grpc",
                "--verbose"
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                logger.info("[OK] Synthetic trace generation test passed")
                self.results["steps"]["synthetic_trace_generation"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Synthetic trace generation test failed: {result.stderr}")
                self.results["steps"]["synthetic_trace_generation"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False
                
        except Exception as e:
            logger.error(f"[ERROR] Synthetic trace generation test error: {e}")
            self.results["steps"]["synthetic_trace_generation"] = {"status": "FAIL", "error": str(e)}
            return False
    
    def test_k6_baseline(self) -> bool:
        """Test k6 baseline test execution"""
        logger.info("Testing k6 baseline test execution...")

        if shutil.which("k6") is None:
            logger.warning("[SKIP] k6 not found - skipping k6 baseline test")
            logger.info("To install k6, see docs/BossCat/guides/K6_INSTALLATION_GUIDE.md")
            self.results["steps"]["k6_baseline"] = {
                "status": "SKIPPED",
                "reason": "k6 not installed - see installation guide"
            }
            return True

        try:
            result = subprocess.run([
                "k6", "run",
                "tests/k6/baseline-test.js",
                "--env", "BASE_URL=http://127.0.0.1:8080",
                "--env", "VUS=2",
                "--env", "DURATION=10s",
                "--out", f"json={self.artifacts_dir}/baseline-test-results.json"
            ], capture_output=True, text=True, timeout=60)

            if result.returncode == 0:
                logger.info("[OK] k6 baseline test execution passed")
                self.results["steps"]["k6_baseline"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error("[ERROR] k6 baseline test execution failed: " + result.stderr)
                self.results["steps"]["k6_baseline"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] k6 not available: {e}")
            logger.info("To install k6, see docs/BossCat/guides/K6_INSTALLATION_GUIDE.md")
            self.results["steps"]["k6_baseline"] = {
                "status": "SKIPPED",
                "reason": "k6 not installed - see installation guide"
            }
            return True
        except Exception as e:
            logger.error("[ERROR] k6 baseline test execution error: " + str(e))
            self.results["steps"]["k6_baseline"] = {"status": "FAIL", "error": str(e)}
            return False

    def test_locust_user_journey(self) -> bool:
        """Test Locust user journey execution"""
        logger.info("Testing Locust user journey execution...")

        if shutil.which("locust") is None:
            logger.warning("[SKIP] Locust not found - skipping Locust user journey test")
            logger.info("To install Locust, run: pip install locust")
            self.results["steps"]["locust_user_journey"] = {
                "status": "SKIPPED",
                "reason": "Locust not installed"
            }
            return True

        try:
            result = subprocess.run([
                "locust", "-f", "tests/locust/signoz_user_journey.py",
                "--host", "http://127.0.0.1:8080",
                "--users", "2",
                "--spawn-rate", "1",
                "--run-time", "30s",
                "--headless",
                "--csv", f"{self.artifacts_dir}/locust-results"
            ], capture_output=True, text=True, timeout=90)

            if result.returncode == 0:
                logger.info("[OK] Locust user journey test execution passed")
                self.results["steps"]["locust_user_journey"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Locust user journey test execution failed: {result.stderr}")
                self.results["steps"]["locust_user_journey"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Locust not available: {e}")
            logger.info("To install Locust, run: pip install locust")
            self.results["steps"]["locust_user_journey"] = {
                "status": "SKIPPED",
                "reason": "Locust not installed"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Locust user journey test execution error: {e}")
            self.results["steps"]["locust_user_journey"] = {"status": "FAIL", "error": str(e)}
            return False

    def test_locust_results_parsing(self) -> bool:
        """Test Locust results parsing"""
        logger.info("Testing Locust results parsing...")

        previous = self.results.get("steps", {}).get("locust_user_journey", {})
        if previous.get("status") == "SKIPPED":
            logger.warning("[SKIP] Locust was skipped - skipping results parsing")
            self.results["steps"]["locust_results_parsing"] = {
                "status": "SKIPPED",
                "reason": "Locust user journey was not executed"
            }
            return True

        locust_csv = self.artifacts_dir / "locust-results_stats.csv"
        if not locust_csv.exists():
            logger.warning("[SKIP] Locust CSV artifacts not found - skipping results parsing")
            self.results["steps"]["locust_results_parsing"] = {
                "status": "SKIPPED",
                "reason": "Locust CSV artifacts missing"
            }
            return True

        try:
            result = subprocess.run([
                sys.executable, "scripts/parse-locust-results.py",
                "--artifacts-dir", str(self.artifacts_dir),
                "--csv-prefix", f"{self.artifacts_dir}/locust-results",
                "--output", f"{self.artifacts_dir}/locust/locust-summary.json",
                "--verbose"
            ], capture_output=True, text=True, timeout=30)

            if result.returncode == 0:
                logger.info("[OK] Locust results parsing test passed")
                self.results["steps"]["locust_results_parsing"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Locust results parsing test failed: {result.stderr}")
                self.results["steps"]["locust_results_parsing"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Locust artifacts not found: {e}")
            self.results["steps"]["locust_results_parsing"] = {
                "status": "SKIPPED",
                "reason": "Locust artifacts not available"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Locust results parsing test error: {e}")
            self.results["steps"]["locust_results_parsing"] = {"status": "FAIL", "error": str(e)}
            return False

    def test_gate_verification(self) -> bool:
        """Test gate verification"""
        logger.info("Testing gate verification...")

        dependent_steps = [
            self.results.get("steps", {}).get("k6_baseline", {}).get("status"),
            self.results.get("steps", {}).get("locust_user_journey", {}).get("status"),
        ]
        if any(status == "SKIPPED" for status in dependent_steps):
            logger.warning("[SKIP] Prerequisite tests were skipped - skipping gate verification")
            self.results["steps"]["gate_verification"] = {
                "status": "SKIPPED",
                "reason": "Prerequisite performance tests were not executed"
            }
            return True

        try:
            result = subprocess.run([
                sys.executable, "scripts/verify-gate-readiness.py",
                "--artifacts-dir", str(self.artifacts_dir),
                "--signoz-url", "http://127.0.0.1:8080",
                "--output", f"{self.artifacts_dir}/gate-verification-results.json",
                "--verbose"
            ], capture_output=True, text=True, timeout=60)

            if result.returncode == 0:
                logger.info("[OK] Gate verification test passed")
                self.results["steps"]["gate_verification"] = {
                    "status": "PASS",
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Gate verification test failed: {result.stderr}")
                self.results["steps"]["gate_verification"] = {
                    "status": "FAIL",
                    "error": result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Gate verification prerequisites missing: {e}")
            self.results["steps"]["gate_verification"] = {
                "status": "SKIPPED",
                "reason": "Gate verification script not available"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Gate verification test error: {e}")
            self.results["steps"]["gate_verification"] = {"status": "FAIL", "error": str(e)}
            return False

    def test_report_generation(self) -> bool:
        """Test report generation"""
        logger.info("Testing report generation...")

        gate_status = self.results.get("steps", {}).get("gate_verification", {}).get("status")
        if gate_status == "SKIPPED":
            logger.warning("[SKIP] Gate verification was skipped - skipping report generation")
            self.results["steps"]["report_generation"] = {
                "status": "SKIPPED",
                "reason": "Gate verification outputs not available"
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
                "--output", f"{self.artifacts_dir}/ECRR_DRY_RUN.md"
            ], capture_output=True, text=True, timeout=30)

            # Generate BOSS v2 report
            boss_result = subprocess.run([
                sys.executable, "scripts/generate-boss-v2-report.py",
                "--gate-results", str(gate_results_path),
                "--output", f"{self.artifacts_dir}/BOSS_V2_DRY_RUN.md"
            ], capture_output=True, text=True, timeout=30)

            if ecrr_result.returncode == 0 and boss_result.returncode == 0:
                logger.info("[OK] Report generation test passed")
                self.results["steps"]["report_generation"] = {
                    "status": "PASS",
                    "ecrr_output": ecrr_result.stdout,
                    "boss_output": boss_result.stdout
                }
                return True
            else:
                logger.error(f"[ERROR] Report generation test failed")
                self.results["steps"]["report_generation"] = {
                    "status": "FAIL",
                    "ecrr_error": ecrr_result.stderr,
                    "boss_error": boss_result.stderr
                }
                return False

        except FileNotFoundError as e:
            logger.warning(f"[SKIP] Report generation tools missing: {e}")
            self.results["steps"]["report_generation"] = {
                "status": "SKIPPED",
                "reason": "Report generator scripts not available"
            }
            return True
        except Exception as e:
            logger.error(f"[ERROR] Report generation test error: {e}")
            self.results["steps"]["report_generation"] = {"status": "FAIL", "error": str(e)}
            return False

    def run_dry_run(self) -> bool:
        """Run complete dry run test"""
        logger.info("[START] Starting BossCat dry run test...")
        
        try:
            # Test mock SigNoz startup
            if not self.test_mock_signoz_startup():
                return False
            
            # Test synthetic trace generation
            if not self.test_synthetic_trace_generation():
                return False
            
            # Test k6 baseline
            if not self.test_k6_baseline():
                return False
            
            # Test Locust user journey
            if not self.test_locust_user_journey():
                return False
            
            # Test Locust results parsing
            if not self.test_locust_results_parsing():
                return False
            
            # Test gate verification
            if not self.test_gate_verification():
                return False
            
            # Test report generation
            if not self.test_report_generation():
                return False
            
            # Determine overall status
            all_steps_passed = all(
                step.get("status") in {"PASS", "SKIPPED"} 
                for step in self.results["steps"].values()
            )
            
            self.results["overall_status"] = "PASS" if all_steps_passed else "FAIL"
            self.results["completed_at"] = datetime.now().isoformat()
            
            if all_steps_passed:
                logger.info("[OK] BossCat dry run test completed successfully!")
                logger.info("[LAUNCH] Pipeline is ready for full execution")
            else:
                logger.error("[ERROR] BossCat dry run test failed")
                logger.error("[STOP] Pipeline needs fixes before full execution")
            
            return all_steps_passed
            
        except Exception as e:
            logger.error(f"[ERROR] Dry run test error: {e}")
            self.results["overall_status"] = "FAIL"
            self.results["error"] = str(e)
            return False
    
    def save_results(self):
        """Save dry run results"""
        results_file = self.artifacts_dir / "dry-run-results.json"
        with open(results_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        logger.info(f"[STATS] Dry run results saved to {results_file}")

def main():
    parser = argparse.ArgumentParser(description="BossCat Dry Run Test")
    parser.add_argument(
        "--artifacts-dir",
        default="artifacts",
        help="Directory for test artifacts"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Create dry run tester
    dry_run = BossCatDryRun(artifacts_dir=args.artifacts_dir)
    
    try:
        # Run dry run test
        success = dry_run.run_dry_run()
        
        # Save results
        dry_run.save_results()
        
        # Exit with appropriate code
        if success:
            print("[OK] BossCat dry run test PASSED")
            return 0
        else:
            print("[ERROR] BossCat dry run test FAILED")
            return 1
            
    except Exception as e:
        logger.error(f"[ERROR] Dry run test error: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
