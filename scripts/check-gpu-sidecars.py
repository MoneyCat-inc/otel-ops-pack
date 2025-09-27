#!/usr/bin/env python3
"""GPU Sidecar Health Check Script"""

import sys
import requests
import json

def check_sidecar_health(port, name):
    """Check if a sidecar service is healthy"""
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] {name} (port {port}): {data.get('status', 'unknown')}")
            if 'gpu_available' in data:
                print(f"  GPU available: {data['gpu_available']}")
            return True
        else:
            print(f"[FAIL] {name} (port {port}): HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] {name} (port {port}): {e}")
        return False

def main():
    """Check all GPU sidecar services"""
    services = [
        (8001, "Compression Sidecar"),
        (8002, "Aggregation Sidecar"), 
        (8003, "Inference Sidecar")
    ]
    
    all_healthy = True
    for port, name in services:
        if not check_sidecar_health(port, name):
            all_healthy = False
    
    if all_healthy:
        print("\n[SUCCESS] All GPU sidecar services are healthy")
        sys.exit(0)
    else:
        print("\n[ERROR] Some GPU sidecar services are unhealthy")
        sys.exit(1)

if __name__ == "__main__":
    main()
