#!/usr/bin/env python3
"""
BossCat Synthetic Trace Verification Script
Verifies that synthetic traces are properly ingested by SigNoz
"""

import argparse
import time
import requests
import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BossCatTraceVerifier:
    """Verifies synthetic trace ingestion in SigNoz"""
    
    def __init__(self, signoz_url: str, timeout: int = 60):
        self.signoz_url = signoz_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        })
    
    def check_signoz_health(self) -> bool:
        """Check if SigNoz is healthy and accessible"""
        try:
            response = self.session.get(
                f"{self.signoz_url}/api/v1/health",
                timeout=10
            )
            if response.status_code == 200:
                logger.info("[OK] SigNoz health check passed")
                return True
            else:
                logger.error(f"[ERROR] SigNoz health check failed: {response.status_code}")
                return False
        except Exception as e:
            logger.error(f"[ERROR] SigNoz health check failed: {e}")
            return False
    
    def query_traces(self, query: str, start_time: int, end_time: int) -> Optional[Dict]:
        """Query traces from SigNoz"""
        try:
            params = {
                'query': query,
                'start': start_time,
                'end': end_time,
                'limit': 100,
            }
            
            response = self.session.get(
                f"{self.signoz_url}/api/v1/traces",
                params=params,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"[ERROR] Trace query failed: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"[ERROR] Trace query error: {e}")
            return None
    
    def query_logs(self, query: str, start_time: int, end_time: int) -> Optional[Dict]:
        """Query logs from SigNoz"""
        try:
            params = {
                'query': query,
                'start': start_time,
                'end': end_time,
                'limit': 100,
            }
            
            response = self.session.get(
                f"{self.signoz_url}/api/v1/logs",
                params=params,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"[ERROR] Logs query failed: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"[ERROR] Logs query error: {e}")
            return None
    
    def verify_synthetic_traces(self) -> bool:
        """Verify that synthetic traces are present"""
        logger.info("[SEARCH] Verifying synthetic traces...")
        
        # Calculate time range (last 10 minutes)
        end_time = int(time.time())
        start_time = end_time - 600  # 10 minutes ago
        
        # Query for synthetic traces
        trace_query = 'attributes.test.type = "synthetic"'
        trace_data = self.query_traces(trace_query, start_time, end_time)
        
        if not trace_data:
            logger.error("[ERROR] Failed to query traces")
            return False
        
        traces = trace_data.get('data', [])
        if not traces:
            logger.error("[ERROR] No synthetic traces found")
            return False
        
        logger.info(f"[OK] Found {len(traces)} synthetic traces")
        
        # Verify trace attributes
        for trace in traces[:5]:  # Check first 5 traces
            attributes = trace.get('attributes', {})
            if attributes.get('test.type') != 'synthetic':
                logger.warning(f"[WARNING]  Trace missing synthetic test.type attribute")
            else:
                logger.info(f"[OK] Trace {trace.get('trace_id', 'unknown')} has correct attributes")
        
        return True
    
    def verify_canary_traces(self) -> bool:
        """Verify that canary traces are present"""
        logger.info("[SEARCH] Verifying canary traces...")
        
        # Calculate time range (last 10 minutes)
        end_time = int(time.time())
        start_time = end_time - 600  # 10 minutes ago
        
        # Query for canary traces
        canary_query = 'attributes.test.type = "canary"'
        trace_data = self.query_traces(canary_query, start_time, end_time)
        
        if not trace_data:
            logger.error("[ERROR] Failed to query canary traces")
            return False
        
        traces = trace_data.get('data', [])
        if not traces:
            logger.error("[ERROR] No canary traces found")
            return False
        
        logger.info(f"[OK] Found {len(traces)} canary traces")
        return True
    
    def verify_trace_ingestion_latency(self) -> bool:
        """Verify trace ingestion latency is acceptable"""
        logger.info("[SEARCH] Verifying trace ingestion latency...")
        
        # Query for recent traces
        end_time = int(time.time())
        start_time = end_time - 300  # Last 5 minutes
        
        trace_query = 'attributes.test.type = "synthetic"'
        trace_data = self.query_traces(trace_query, start_time, end_time)
        
        if not trace_data:
            logger.error("[ERROR] Failed to query traces for latency check")
            return False
        
        traces = trace_data.get('data', [])
        if not traces:
            logger.error("[ERROR] No traces found for latency check")
            return False
        
        # Check ingestion latency (trace timestamp vs current time)
        current_time = time.time()
        max_latency = 0
        
        for trace in traces:
            trace_time = trace.get('timestamp', 0) / 1000000  # Convert from microseconds
            latency = current_time - trace_time
            max_latency = max(max_latency, latency)
        
        # Acceptable latency threshold: 30 seconds
        if max_latency > 30:
            logger.error(f"[ERROR] Trace ingestion latency too high: {max_latency:.2f}s")
            return False
        
        logger.info(f"[OK] Trace ingestion latency acceptable: {max_latency:.2f}s")
        return True
    
    def verify_gate_readiness(self) -> bool:
        """Comprehensive gate readiness verification"""
        logger.info("🚪 Starting BossCat gate readiness verification...")
        
        # Check SigNoz health
        if not self.check_signoz_health():
            return False
        
        # Verify synthetic traces
        if not self.verify_synthetic_traces():
            return False
        
        # Verify canary traces
        if not self.verify_canary_traces():
            return False
        
        # Verify trace ingestion latency
        if not self.verify_trace_ingestion_latency():
            return False
        
        logger.info("[OK] BossCat gate readiness verification completed successfully")
        return True
    
    def wait_for_traces(self, max_wait_time: int = 60) -> bool:
        """Wait for traces to appear in SigNoz"""
        logger.info(f"⏳ Waiting for traces to appear (max {max_wait_time}s)...")
        
        start_time = time.time()
        while time.time() - start_time < max_wait_time:
            if self.verify_synthetic_traces():
                logger.info("[OK] Traces found!")
                return True
            
            logger.info("⏳ Traces not found yet, waiting...")
            time.sleep(5)
        
        logger.error("[ERROR] Timeout waiting for traces")
        return False

def main():
    parser = argparse.ArgumentParser(description="BossCat Synthetic Trace Verification")
    parser.add_argument(
        "--signoz-url",
        required=True,
        help="SigNoz URL (e.g., http://localhost:8080)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="Timeout in seconds for verification"
    )
    parser.add_argument(
        "--wait-for-traces",
        action="store_true",
        help="Wait for traces to appear before verification"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Create verifier
    verifier = BossCatTraceVerifier(
        signoz_url=args.signoz_url,
        timeout=args.timeout
    )
    
    try:
        if args.wait_for_traces:
            # Wait for traces to appear
            if not verifier.wait_for_traces(args.timeout):
                return 1
        
        # Perform verification
        if verifier.verify_gate_readiness():
            print("[OK] BossCat gate verification PASSED")
            return 0
        else:
            print("[ERROR] BossCat gate verification FAILED")
            return 1
            
    except Exception as e:
        logger.error(f"[ERROR] Verification error: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
