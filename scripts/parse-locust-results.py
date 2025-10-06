#!/usr/bin/env python3
"""
Locust Results Parser
Parses Locust CSV outputs into consolidated JSON artifact
"""

import argparse
import csv
import json
import os
from pathlib import Path
from typing import Dict, Any, List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LocustResultsParser:
    """Parses Locust CSV results into consolidated JSON"""
    
    def __init__(self, artifacts_dir: str):
        self.artifacts_dir = Path(artifacts_dir)
        self.results = {
            "generated_at": None,
            "overall_status": "UNKNOWN",
            "metrics": {},
            "thresholds": {},
            "failure_reasons": []
        }
    
    def parse_locust_csv(self, csv_prefix: str) -> Dict[str, Any]:
        """Parse Locust CSV files with given prefix"""
        logger.info(f"Parsing Locust CSV files with prefix: {csv_prefix}")
        
        # Expected CSV files
        csv_files = {
            "requests": f"{csv_prefix}_requests.csv",
            "failures": f"{csv_prefix}_failures.csv", 
            "stats": f"{csv_prefix}_stats.csv",
            "exceptions": f"{csv_prefix}_exceptions.csv"
        }
        
        parsed_data = {}
        
        for file_type, filename in csv_files.items():
            file_path = self.artifacts_dir / filename
            if file_path.exists():
                parsed_data[file_type] = self._parse_csv_file(file_path)
                logger.info(f"[OK] Parsed {file_type} data from {filename}")
            else:
                logger.warning(f"[WARNING]  CSV file not found: {filename}")
        
        return parsed_data
    
    def _parse_csv_file(self, file_path: Path) -> List[Dict[str, Any]]:
        """Parse a single CSV file"""
        data = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Convert numeric fields
                    for key, value in row.items():
                        if value.replace('.', '').replace('-', '').isdigit():
                            try:
                                row[key] = float(value)
                            except ValueError:
                                pass
                    data.append(row)
        except Exception as e:
            logger.error(f"Error parsing CSV file {file_path}: {e}")
        
        return data
    
    def calculate_metrics(self, parsed_data: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate metrics from parsed CSV data"""
        metrics = {}
        
        # Calculate request metrics
        if "requests" in parsed_data and parsed_data["requests"]:
            requests_data = parsed_data["requests"]
            total_requests = len(requests_data)
            failed_requests = sum(1 for req in requests_data if req.get("Failure Message", "").strip())
            
            metrics["requests"] = total_requests
            metrics["failed_requests"] = failed_requests
            metrics["error_rate"] = failed_requests / total_requests if total_requests > 0 else 0
            metrics["success_rate"] = 1 - metrics["error_rate"]
        
        # Calculate response time metrics
        if "requests" in parsed_data and parsed_data["requests"]:
            response_times = [req.get("Response Time", 0) for req in parsed_data["requests"] if req.get("Response Time", 0) > 0]
            if response_times:
                response_times.sort()
                metrics["avg_response_time"] = sum(response_times) / len(response_times)
                metrics["min_response_time"] = min(response_times)
                metrics["max_response_time"] = max(response_times)
                metrics["p95_response_time"] = response_times[int(len(response_times) * 0.95)] if len(response_times) > 0 else 0
                metrics["p99_response_time"] = response_times[int(len(response_times) * 0.99)] if len(response_times) > 0 else 0
        
        # Calculate RPS metrics
        if "stats" in parsed_data and parsed_data["stats"]:
            stats_data = parsed_data["stats"]
            for stat in stats_data:
                if stat.get("Name") == "Aggregated":
                    metrics["requests_per_second"] = stat.get("Requests/s", 0)
                    metrics["total_requests"] = stat.get("Request Count", 0)
                    metrics["total_failures"] = stat.get("Failure Count", 0)
                    break
        
        return metrics
    
    def evaluate_thresholds(self, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate metrics against thresholds"""
        thresholds = {
            "error_rate_max": 0.05,  # 5% max error rate
            "p95_response_time_max": 1000,  # 1 second max P95
            "avg_response_time_max": 500,  # 500ms max average
        }
        
        failures = []
        
        if metrics.get("error_rate", 0) > thresholds["error_rate_max"]:
            failures.append(f"Error rate {metrics['error_rate']:.2%} exceeds threshold {thresholds['error_rate_max']:.2%}")
        
        if metrics.get("p95_response_time", 0) > thresholds["p95_response_time_max"]:
            failures.append(f"P95 response time {metrics['p95_response_time']:.2f}ms exceeds threshold {thresholds['p95_response_time_max']}ms")
        
        if metrics.get("avg_response_time", 0) > thresholds["avg_response_time_max"]:
            failures.append(f"Average response time {metrics['avg_response_time']:.2f}ms exceeds threshold {thresholds['avg_response_time_max']}ms")
        
        return {
            "thresholds": thresholds,
            "failures": failures,
            "passed": len(failures) == 0
        }
    
    def parse_and_consolidate(self, csv_prefix: str) -> Dict[str, Any]:
        """Parse Locust CSV files and create consolidated summary"""
        from datetime import datetime
        
        # Parse CSV files
        parsed_data = self.parse_locust_csv(csv_prefix)
        
        # Calculate metrics
        metrics = self.calculate_metrics(parsed_data)
        
        # Evaluate thresholds
        evaluation = self.evaluate_thresholds(metrics)
        
        # Create consolidated result
        self.results.update({
            "generated_at": datetime.now().isoformat(),
            "overall_status": "PASS" if evaluation["passed"] else "FAIL",
            "metrics": metrics,
            "thresholds": evaluation["thresholds"],
            "failure_reasons": evaluation["failures"],
            "raw_data": parsed_data
        })
        
        return self.results
    
    def save_summary(self, output_file: str):
        """Save consolidated summary to file"""
        try:
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            with open(output_file, 'w') as f:
                json.dump(self.results, f, indent=2)
            logger.info(f"[OK] Locust summary saved to {output_file}")
        except Exception as e:
            logger.error(f"[ERROR] Failed to save Locust summary: {e}")
            raise

def main():
    parser = argparse.ArgumentParser(description="Locust Results Parser")
    parser.add_argument(
        "--artifacts-dir",
        required=True,
        help="Directory containing Locust CSV files"
    )
    parser.add_argument(
        "--csv-prefix",
        default="locust-results",
        help="Prefix for Locust CSV files"
    )
    parser.add_argument(
        "--output",
        default="artifacts/locust/locust-summary.json",
        help="Output file for consolidated summary"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        # Create parser
        parser_instance = LocustResultsParser(args.artifacts_dir)
        
        # Parse and consolidate results
        results = parser_instance.parse_and_consolidate(args.csv_prefix)
        
        # Save summary
        parser_instance.save_summary(args.output)
        
        # Print summary
        print(f"[OK] Locust results parsed successfully")
        print(f"[STATS] Overall Status: {results['overall_status']}")
        print(f"📈 Total Requests: {results['metrics'].get('requests', 0)}")
        print(f"[ERROR] Error Rate: {results['metrics'].get('error_rate', 0):.2%}")
        print(f"⏱️  P95 Response Time: {results['metrics'].get('p95_response_time', 0):.2f}ms")
        
        if results['failure_reasons']:
            print(f"[WARNING]  Failures: {', '.join(results['failure_reasons'])}")
        
        return 0 if results['overall_status'] == 'PASS' else 1
        
    except Exception as e:
        logger.error(f"[ERROR] Failed to parse Locust results: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
