#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🐾 T1 Rolling-Stats SigNoz Integration
GPU Pattern-Sifter EPIC - Lane T1
Real-time OTLP metrics integration with SigNoz
"""

import json
import time
import sys
from datetime import datetime, timezone
from typing import Dict, Any
import requests

# Handle Windows encoding for emoji
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach())
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.detach())

class T1SigNozIntegration:
    def __init__(self, signoz_url: str = "http://localhost:8080"):
        self.signoz_url = signoz_url
        self.otlp_endpoint = f"{signoz_url}/v1/traces"  # OTLP endpoint
        
    def send_t1_metrics_via_otlp(self, evidence: Dict[str, Any]) -> bool:
        """Send T1 metrics to SigNoz via OTLP"""
        try:
            timestamp = int(time.time() * 1000000000)  # nanoseconds
            
            # Create OTLP trace with T1 metrics
            trace_data = {
                "resourceSpans": [{
                    "resource": {
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "t1-rolling-stats"}},
                            {"key": "service.version", "value": {"stringValue": "1.0.0"}},
                            {"key": "environment", "value": {"stringValue": evidence["deployment"]["environment"]}},
                            {"key": "epic", "value": {"stringValue": "gpu-pattern-sifter"}},
                            {"key": "lane", "value": {"stringValue": "T1"}},
                            {"key": "provider", "value": {"stringValue": evidence["run"]["providerFinal"]}},
                            {"key": "gpu_model", "value": {"stringValue": evidence["env"]["gpu_model"] or "none"}}
                        ]
                    },
                    "scopeSpans": [{
                        "scope": {"name": "t1-rolling-stats"},
                        "spans": [{
                            "traceId": "12345678901234567890123456789012",
                            "spanId": "1234567890123456",
                            "name": "t1-rolling-stats-execution",
                            "kind": "SPAN_KIND_INTERNAL",
                            "startTimeUnixNano": str(timestamp),
                            "endTimeUnixNano": str(timestamp + int(evidence["timings"]["accMs"] * 1000000)),
                            "attributes": [
                                {"key": "gpu_available", "value": {"intValue": 1 if evidence["env"]["providers"] else 0}},
                                {"key": "fallback_triggered", "value": {"intValue": 1 if evidence["run"]["fellBackToCpu"] else 0}},
                                {"key": "performance_ratio", "value": {"doubleValue": evidence["timings"]["cpuMs"] / evidence["timings"]["accMs"] if evidence["timings"]["accMs"] > 0 else 1.0}},
                                {"key": "algorithm_status", "value": {"intValue": 1}},
                                {"key": "parity_max_diff", "value": {"doubleValue": evidence["parity"]["maxAbsDiff"]}},
                                {"key": "gpu_timing_total", "value": {"doubleValue": evidence["timings"]["gpuMs"]}},
                                {"key": "gpu_timing_h2d", "value": {"doubleValue": evidence["timings"]["h2dMs"]}},
                                {"key": "gpu_timing_kernel", "value": {"doubleValue": evidence["timings"]["kernelMs"]}},
                                {"key": "gpu_timing_d2h", "value": {"doubleValue": evidence["timings"]["d2hMs"]}},
                                {"key": "window_size", "value": {"intValue": evidence["params"]["window"]}},
                                {"key": "stride_size", "value": {"intValue": evidence["params"]["stride"]}}
                            ]
                        }]
                    }]
                }]
            }
            
            print(f"📊 Sending T1 OTLP trace to SigNoz...")
            print(f"   Endpoint: {self.otlp_endpoint}")
            print(f"   Service: t1-rolling-stats")
            print(f"   Provider: {evidence['run']['providerFinal']}")
            print(f"   GPU Model: {evidence['env']['gpu_model'] or 'none'}")
            
            # Send to SigNoz OTLP endpoint
            headers = {
                "Content-Type": "application/json",
                "User-Agent": "T1-Rolling-Stats/1.0.0"
            }
            
            response = requests.post(
                self.otlp_endpoint,
                json=trace_data,
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                print(f"   ✅ OTLP trace sent successfully")
                return True
            else:
                print(f"   ❌ OTLP send failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"   ❌ OTLP integration failed: {e}")
            return False
    
    def send_t1_metrics_via_api(self, evidence: Dict[str, Any]) -> bool:
        """Send T1 metrics to SigNoz via API (alternative method)"""
        try:
            # Create metrics payload
            metrics_payload = {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "service": "t1-rolling-stats",
                "metrics": {
                    "gpu_available": 1 if evidence["env"]["providers"] else 0,
                    "fallback_triggered": 1 if evidence["run"]["fellBackToCpu"] else 0,
                    "performance_ratio": evidence["timings"]["cpuMs"] / evidence["timings"]["accMs"] if evidence["timings"]["accMs"] > 0 else 1.0,
                    "algorithm_status": 1,
                    "parity_max_diff": evidence["parity"]["maxAbsDiff"],
                    "gpu_timing_total": evidence["timings"]["gpuMs"],
                    "gpu_timing_h2d": evidence["timings"]["h2dMs"],
                    "gpu_timing_kernel": evidence["timings"]["kernelMs"],
                    "gpu_timing_d2h": evidence["timings"]["d2hMs"]
                },
                "labels": {
                    "environment": evidence["deployment"]["environment"],
                    "epic": "gpu-pattern-sifter",
                    "lane": "T1",
                    "provider": evidence["run"]["providerFinal"],
                    "gpu_model": evidence["env"]["gpu_model"] or "none"
                }
            }
            
            print(f"📊 Sending T1 metrics via API...")
            
            # Send to SigNoz API
            api_endpoint = f"{self.signoz_url}/api/v1/metrics"
            response = requests.post(
                api_endpoint,
                json=metrics_payload,
                timeout=10
            )
            
            if response.status_code in [200, 201]:
                print(f"   ✅ API metrics sent successfully")
                return True
            else:
                print(f"   ❌ API send failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"   ❌ API integration failed: {e}")
            return False
    
    def check_signoz_health(self) -> bool:
        """Check if SigNoz is healthy and accessible"""
        try:
            health_endpoint = f"{self.signoz_url}/api/v1/health"
            response = requests.get(health_endpoint, timeout=5)
            
            if response.status_code == 200:
                print(f"✅ SigNoz health check passed")
                return True
            else:
                print(f"❌ SigNoz health check failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ SigNoz health check error: {e}")
            return False
    
    def integrate_t1_metrics(self, evidence_file: str = "CHAR/ECRR/ECRR_REPORTS/t1_production_evidence.json") -> bool:
        """Integrate T1 metrics with SigNoz"""
        print("🐾 T1 Rolling-Stats SigNoz Integration")
        print("======================================")
        
        # Check SigNoz health
        if not self.check_signoz_health():
            print("❌ SigNoz not available, skipping integration")
            return False
        
        # Load evidence
        try:
            with open(evidence_file, 'r') as f:
                evidence = json.load(f)
        except FileNotFoundError:
            print(f"❌ Evidence file not found: {evidence_file}")
            return False
        
        # Try OTLP integration first
        otlp_success = self.send_t1_metrics_via_otlp(evidence)
        
        # Fallback to API if OTLP fails
        if not otlp_success:
            print("🔄 Falling back to API integration...")
            api_success = self.send_t1_metrics_via_api(evidence)
            return api_success
        
        return otlp_success

def main():
    """Main integration function"""
    integrator = T1SigNozIntegration()
    success = integrator.integrate_t1_metrics()
    
    if success:
        print("\n🎉 T1 Rolling-Stats successfully integrated with SigNoz!")
        print("📊 View metrics at: http://localhost:8080")
        return 0
    else:
        print("\n❌ T1 SigNoz integration failed")
        return 1

if __name__ == '__main__':
    exit(main())

