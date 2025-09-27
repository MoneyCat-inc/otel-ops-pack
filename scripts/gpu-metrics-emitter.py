#!/usr/bin/env python3
"""
GPU Metrics Emitter for OTel Pipeline
Sends GPU metrics from sidecars to OpenTelemetry collector
"""

import time
import json
import requests
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configuration
OTEL_ENDPOINT = "http://localhost:5318/v1/metrics"
GPU_SIDECAR_PORTS = {
    "compression": 8001,
    "aggregation": 8002, 
    "inference": 8003
}

def get_gpu_metrics_from_sidecar(service_name, port):
    """Get GPU metrics from a specific sidecar service"""
    try:
        response = requests.get(f"http://localhost:{port}/metrics", timeout=5)
        if response.status_code == 200:
            return response.json()
        else:
            logger.warning(f"Failed to get metrics from {service_name}: HTTP {response.status_code}")
            return None
    except Exception as e:
        logger.error(f"Error getting metrics from {service_name}: {e}")
        return None

def emit_gpu_metrics_to_otel(metrics_data, service_name):
    """Send GPU metrics to OTel collector"""
    timestamp = int(time.time() * 1000000000)  # nanoseconds
    
    # Create OTLP metrics payload
    otlp_payload = {
        "resourceMetrics": [{
            "resource": {
                "attributes": [
                    {"key": "service.name", "value": {"stringValue": f"gpu-{service_name}-sidecar"}},
                    {"key": "service.namespace", "value": {"stringValue": "gpu-monitoring"}},
                    {"key": "deployment.environment", "value": {"stringValue": "local"}},
                    {"key": "dataset", "value": {"stringValue": "windows-gpu-metrics"}}
                ]
            },
            "scopeMetrics": [{
                "scope": {"name": "gpu-metrics-emitter"},
                "metrics": []
            }]
        }]
    }
    
    # Add GPU metrics
    if metrics_data and "gpu" in metrics_data:
        gpu_info = metrics_data["gpu"]
        
        # GPU Utilization
        if "utilization" in gpu_info:
            otlp_payload["resourceMetrics"][0]["scopeMetrics"][0]["metrics"].append({
                "name": "gpu.utilization.percent",
                "description": "GPU utilization percentage",
                "unit": "%",
                "gauge": {
                    "dataPoints": [{
                        "timeUnixNano": timestamp,
                        "asDouble": float(gpu_info["utilization"])
                    }]
                }
            })
        
        # GPU Memory Usage
        if "memory" in gpu_info:
            memory = gpu_info["memory"]
            if "used" in memory and "total" in memory:
                used = float(memory["used"])
                total = float(memory["total"])
                otlp_payload["resourceMetrics"][0]["scopeMetrics"][0]["metrics"].append({
                    "name": "gpu.memory.used.bytes",
                    "description": "GPU memory used in bytes",
                    "unit": "bytes",
                    "gauge": {
                        "dataPoints": [{
                            "timeUnixNano": timestamp,
                            "asDouble": used
                        }]
                    }
                })
                
                otlp_payload["resourceMetrics"][0]["scopeMetrics"][0]["metrics"].append({
                    "name": "gpu.memory.total.bytes",
                    "description": "GPU memory total in bytes",
                    "unit": "bytes",
                    "gauge": {
                        "dataPoints": [{
                            "timeUnixNano": timestamp,
                            "asDouble": total
                        }]
                    }
                })
                
                # Memory utilization percentage
                if total > 0:
                    utilization = (used / total) * 100
                    otlp_payload["resourceMetrics"][0]["scopeMetrics"][0]["metrics"].append({
                        "name": "gpu.memory.utilization.percent",
                        "description": "GPU memory utilization percentage",
                        "unit": "%",
                        "gauge": {
                            "dataPoints": [{
                                "timeUnixNano": timestamp,
                                "asDouble": utilization
                            }]
                        }
                    })
        
        # GPU Temperature
        if "temperature" in gpu_info:
            otlp_payload["resourceMetrics"][0]["scopeMetrics"][0]["metrics"].append({
                "name": "gpu.temperature.celsius",
                "description": "GPU temperature in Celsius",
                "unit": "°C",
                "gauge": {
                    "dataPoints": [{
                        "timeUnixNano": timestamp,
                        "asDouble": float(gpu_info["temperature"])
                    }]
                }
            })
    
    # Add service health metric
    otlp_payload["resourceMetrics"][0]["scopeMetrics"][0]["metrics"].append({
        "name": "gpu.sidecar.health",
        "description": "GPU sidecar service health status",
        "unit": "1",
        "gauge": {
            "dataPoints": [{
                "timeUnixNano": timestamp,
                "asDouble": 1.0  # 1 = healthy, 0 = unhealthy
            }]
        }
    })
    
    # Send to OTel collector
    try:
        response = requests.post(
            OTEL_ENDPOINT,
            json=otlp_payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            logger.info(f"[SUCCESS] GPU metrics emitted for {service_name}")
            return True
        else:
            logger.error(f"[ERROR] Failed to emit GPU metrics for {service_name}: HTTP {response.status_code}")
            logger.error(f"Response: {response.text}")
            return False
            
    except Exception as e:
        logger.error(f"[ERROR] Error emitting GPU metrics for {service_name}: {e}")
        return False

def main():
    """Main function to collect and emit GPU metrics"""
    logger.info("[START] Starting GPU Metrics Emitter")
    logger.info(f"[CONFIG] OTel Endpoint: {OTEL_ENDPOINT}")
    
    success_count = 0
    total_count = 0
    
    for service_name, port in GPU_SIDECAR_PORTS.items():
        logger.info(f"[COLLECT] Collecting metrics from {service_name} sidecar (port {port})")
        
        # Get metrics from sidecar
        metrics_data = get_gpu_metrics_from_sidecar(service_name, port)
        
        if metrics_data:
            # Emit to OTel
            if emit_gpu_metrics_to_otel(metrics_data, service_name):
                success_count += 1
        else:
            logger.warning(f"⚠️ No metrics data from {service_name} sidecar")
        
        total_count += 1
        
        # Small delay between services
        time.sleep(0.5)
    
    logger.info(f"[SUMMARY] GPU Metrics Collection Complete: {success_count}/{total_count} services successful")
    
    if success_count == total_count:
        logger.info("[COMPLETE] All GPU sidecars successfully wired to OTel pipeline!")
    else:
        logger.warning(f"[WARNING] {total_count - success_count} GPU sidecars failed to emit metrics")

if __name__ == "__main__":
    main()
