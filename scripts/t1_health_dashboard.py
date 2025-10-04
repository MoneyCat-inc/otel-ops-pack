#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🐾 T1 Rolling-Stats Health Dashboard
GPU Pattern-Sifter EPIC - Lane T1
Create T1-specific health dashboard in SigNoz
"""

import json
import time
import sys
import requests
from datetime import datetime, timezone

# Handle Windows encoding for emoji
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach())
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.detach())

class T1HealthDashboard:
    def __init__(self, signoz_url: str = "http://localhost:8080"):
        self.signoz_url = signoz_url
        
    def create_t1_dashboard(self) -> bool:
        """Create T1-specific health dashboard in SigNoz"""
        try:
            dashboard_config = {
                "title": "T1 Rolling-Stats Health Dashboard",
                "description": "GPU Pattern-Sifter EPIC - Lane T1 monitoring dashboard",
                "panels": [
                    {
                        "title": "GPU Availability Status",
                        "type": "stat",
                        "targets": [
                            {
                                "expr": "gpu_available{service=\"t1-rolling-stats\"}",
                                "legendFormat": "GPU Available"
                            }
                        ],
                        "fieldConfig": {
                            "defaults": {
                                "color": {"mode": "thresholds"},
                                "thresholds": {
                                    "steps": [
                                        {"color": "red", "value": 0},
                                        {"color": "green", "value": 1}
                                    ]
                                }
                            }
                        }
                    },
                    {
                        "title": "Performance Ratio (CPU/GPU)",
                        "type": "graph",
                        "targets": [
                            {
                                "expr": "performance_ratio{service=\"t1-rolling-stats\"}",
                                "legendFormat": "Speedup Ratio"
                            }
                        ],
                        "yAxes": [
                            {
                                "label": "Speedup Factor",
                                "min": 0,
                                "max": 10
                            }
                        ]
                    },
                    {
                        "title": "GPU Timing Breakdown",
                        "type": "graph",
                        "targets": [
                            {
                                "expr": "gpu_timing_h2d{service=\"t1-rolling-stats\"}",
                                "legendFormat": "Host-to-Device"
                            },
                            {
                                "expr": "gpu_timing_kernel{service=\"t1-rolling-stats\"}",
                                "legendFormat": "Kernel Execution"
                            },
                            {
                                "expr": "gpu_timing_d2h{service=\"t1-rolling-stats\"}",
                                "legendFormat": "Device-to-Host"
                            }
                        ],
                        "yAxes": [
                            {
                                "label": "Time (ms)",
                                "min": 0
                            }
                        ]
                    },
                    {
                        "title": "Parity Validation",
                        "type": "stat",
                        "targets": [
                            {
                                "expr": "parity_max_diff{service=\"t1-rolling-stats\"}",
                                "legendFormat": "Max Absolute Difference"
                            }
                        ],
                        "fieldConfig": {
                            "defaults": {
                                "color": {"mode": "thresholds"},
                                "thresholds": {
                                    "steps": [
                                        {"color": "green", "value": 0},
                                        {"color": "yellow", "value": 1e-6},
                                        {"color": "red", "value": 1e-3}
                                    ]
                                }
                            }
                        }
                    },
                    {
                        "title": "Fallback Events",
                        "type": "stat",
                        "targets": [
                            {
                                "expr": "fallback_triggered{service=\"t1-rolling-stats\"}",
                                "legendFormat": "CPU Fallback"
                            }
                        ],
                        "fieldConfig": {
                            "defaults": {
                                "color": {"mode": "thresholds"},
                                "thresholds": {
                                    "steps": [
                                        {"color": "green", "value": 0},
                                        {"color": "red", "value": 1}
                                    ]
                                }
                            }
                        }
                    },
                    {
                        "title": "Algorithm Status",
                        "type": "stat",
                        "targets": [
                            {
                                "expr": "algorithm_status{service=\"t1-rolling-stats\"}",
                                "legendFormat": "T1 Health"
                            }
                        ],
                        "fieldConfig": {
                            "defaults": {
                                "color": {"mode": "thresholds"},
                                "thresholds": {
                                    "steps": [
                                        {"color": "red", "value": 0},
                                        {"color": "green", "value": 1}
                                    ]
                                }
                            }
                        }
                    }
                ],
                "time": {
                    "from": "now-1h",
                    "to": "now"
                },
                "refresh": "30s"
            }
            
            print(f"📊 Creating T1 Health Dashboard...")
            print(f"   Title: {dashboard_config['title']}")
            print(f"   Panels: {len(dashboard_config['panels'])}")
            
            # Create dashboard via SigNoz API
            dashboard_endpoint = f"{self.signoz_url}/api/v1/dashboards"
            response = requests.post(
                dashboard_endpoint,
                json=dashboard_config,
                timeout=10
            )
            
            if response.status_code in [200, 201]:
                dashboard_id = response.json().get("id", "unknown")
                print(f"   ✅ Dashboard created successfully (ID: {dashboard_id})")
                print(f"   🔗 View at: {self.signoz_url}/dashboard/{dashboard_id}")
                return True
            else:
                print(f"   ❌ Dashboard creation failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"   ❌ Dashboard creation error: {e}")
            return False
    
    def create_t1_alerts(self) -> bool:
        """Create T1-specific alerting rules"""
        try:
            alert_configs = [
                {
                    "name": "T1-GPU-Fallback-Alert",
                    "condition": "fallback_triggered{service=\"t1-rolling-stats\"} == 1",
                    "severity": "warning",
                    "message": "T1 Rolling-Stats fell back to CPU execution",
                    "threshold": 1
                },
                {
                    "name": "T1-Parity-Degradation-Alert", 
                    "condition": "parity_max_diff{service=\"t1-rolling-stats\"} > 1e-3",
                    "severity": "critical",
                    "message": "T1 Rolling-Stats parity degradation detected",
                    "threshold": 1e-3
                },
                {
                    "name": "T1-Performance-Degradation-Alert",
                    "condition": "performance_ratio{service=\"t1-rolling-stats\"} < 0.5",
                    "severity": "warning", 
                    "message": "T1 Rolling-Stats performance degradation detected",
                    "threshold": 0.5
                },
                {
                    "name": "T1-Algorithm-Failure-Alert",
                    "condition": "algorithm_status{service=\"t1-rolling-stats\"} == 0",
                    "severity": "critical",
                    "message": "T1 Rolling-Stats algorithm failure detected",
                    "threshold": 0
                }
            ]
            
            print(f"🚨 Creating T1 Alert Rules...")
            
            alerts_created = 0
            for alert_config in alert_configs:
                print(f"   Creating: {alert_config['name']}")
                
                # Create alert via SigNoz API
                alert_endpoint = f"{self.signoz_url}/api/v1/alerts"
                response = requests.post(
                    alert_endpoint,
                    json=alert_config,
                    timeout=10
                )
                
                if response.status_code in [200, 201]:
                    print(f"   ✅ Alert created: {alert_config['name']}")
                    alerts_created += 1
                else:
                    print(f"   ❌ Alert failed: {alert_config['name']} ({response.status_code})")
            
            print(f"📊 Alerts Summary: {alerts_created}/{len(alert_configs)} created")
            return alerts_created == len(alert_configs)
            
        except Exception as e:
            print(f"   ❌ Alert creation error: {e}")
            return False
    
    def setup_t1_monitoring(self) -> bool:
        """Set up complete T1 monitoring infrastructure"""
        print("🐾 T1 Rolling-Stats Health Dashboard Setup")
        print("==========================================")
        
        # Create dashboard
        dashboard_success = self.create_t1_dashboard()
        
        # Create alerts
        alert_success = self.create_t1_alerts()
        
        # Summary
        print(f"\n🎯 T1 Monitoring Setup Summary:")
        print(f"   {'✅' if dashboard_success else '❌'} Health Dashboard")
        print(f"   {'✅' if alert_success else '❌'} Alert Rules")
        print(f"   🔗 SigNoz URL: {self.signoz_url}")
        
        return dashboard_success and alert_success

def main():
    """Main setup function"""
    dashboard = T1HealthDashboard()
    success = dashboard.setup_t1_monitoring()
    
    if success:
        print("\n🎉 T1 Rolling-Stats monitoring infrastructure ready!")
        return 0
    else:
        print("\n❌ T1 monitoring setup failed")
        return 1

if __name__ == '__main__':
    exit(main())
