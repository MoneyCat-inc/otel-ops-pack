#!/usr/bin/env python3
"""Start GPU Sidecar Services"""

import subprocess
import sys
import time
import requests

def start_sidecar_service(service_name, port):
    """Start a GPU sidecar service"""
    print(f"Starting {service_name}...")
    try:
        # Start the service using docker-compose
        result = subprocess.run([
            "docker-compose", "-f", "docker-compose.gpu.yml", "up", "-d", service_name
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✓ {service_name} started successfully")
            
            # Wait for health check
            for i in range(30):  # Wait up to 30 seconds
                try:
                    response = requests.get(f"http://localhost:{port}/health", timeout=2)
                    if response.status_code == 200:
                        print(f"✓ {service_name} is healthy")
                        return True
                except:
                    pass
                time.sleep(1)
            
            print(f"⚠ {service_name} started but health check failed")
            return False
        else:
            print(f"✗ Failed to start {service_name}: {result.stderr}")
            return False
    except Exception as e:
        print(f"✗ Error starting {service_name}: {e}")
        return False

def main():
    """Start all GPU sidecar services"""
    services = [
        ("gpu-compression-sidecar", 8001),
        ("gpu-aggregation-sidecar", 8002),
        ("gpu-inference-sidecar", 8003)
    ]
    
    all_started = True
    for service_name, port in services:
        if not start_sidecar_service(service_name, port):
            all_started = False
    
    if all_started:
        print("\n✓ All GPU sidecar services started successfully")
        print("\nNext steps:")
        print("1. Check service health: python scripts/check-gpu-sidecars.py")
        print("2. View logs: docker-compose -f docker-compose.gpu.yml logs")
        print("3. Stop services: docker-compose -f docker-compose.gpu.yml down")
    else:
        print("\n✗ Some GPU sidecar services failed to start")
        sys.exit(1)

if __name__ == "__main__":
    main()
