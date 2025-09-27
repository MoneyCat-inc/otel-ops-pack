#!/usr/bin/env python3
import time
import subprocess
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

def run_gpu_monitoring():
    logger.info("🔄 Running GPU monitoring cycle...")
    
    # Emit GPU metrics
    try:
        result = subprocess.run(['python', 'scripts/gpu-metrics-emitter.py'], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            logger.info("✅ GPU metrics emitted successfully")
        else:
            logger.error(f"❌ GPU metrics failed: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Error: {e}")
    
    # Check sidecar health
    try:
        result = subprocess.run(['python', 'scripts/check-gpu-sidecars.py'], 
                              capture_output=True, text=True, timeout=15)
        if result.returncode == 0:
            logger.info("✅ GPU sidecars healthy")
        else:
            logger.warning(f"⚠️ Sidecar issues: {result.stderr}")
    except Exception as e:
        logger.error(f"❌ Health check error: {e}")

if __name__ == "__main__":
    run_gpu_monitoring()
