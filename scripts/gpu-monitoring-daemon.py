#!/usr/bin/env python3
"""
GPU Monitoring Daemon - Simplified Version
Automated GPU monitoring with progress indicators
"""

import time
import json
import logging
import subprocess
import requests
from datetime import datetime, timedelta
from pathlib import Path
import signal
import sys

# Configure logging
log_dir = Path("artifacts/gpu-monitoring")
log_dir.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(log_dir / f"gpu-daemon-{datetime.now().strftime('%Y%m%d')}.log", encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)

class GPUMonitoringDaemon:
    def __init__(self, interval=30):
        self.interval = interval
        self.running = True
        self.spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
        self.spinner_index = 0
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        logger.info("🔄 GPU Monitoring Daemon initialized")

    def signal_handler(self, signum, frame):
        logger.info(f"🛑 Received signal {signum}, shutting down...")
        self.running = False

    def animate_progress(self, message, progress=0):
        self.spinner_index = (self.spinner_index + 1) % len(self.spinner_chars)
        spinner = self.spinner_chars[self.spinner_index]
        
        if progress > 0:
            print(f"\r{spinner} {message} ({progress}%)", end="", flush=True)
        else:
            print(f"\r{spinner} {message}", end="", flush=True)

    def check_gpu_sidecars(self):
        """Check GPU sidecar health"""
        sidecars = {
            "compression": 8001,
            "aggregation": 8002,
            "inference": 8003
        }
        
        healthy_count = 0
        for service, port in sidecars.items():
            try:
                response = requests.get(f"http://localhost:{port}/health", timeout=5)
                if response.status_code == 200:
                    healthy_count += 1
                    logger.info(f"✅ {service} sidecar healthy")
                else:
                    logger.warning(f"⚠️ {service} sidecar unhealthy (HTTP {response.status_code})")
            except Exception as e:
                logger.error(f"❌ {service} sidecar error: {e}")
        
        return healthy_count, len(sidecars)

    def emit_gpu_metrics(self):
        """Emit GPU metrics to OTel pipeline"""
        try:
            result = subprocess.run(['python', 'scripts/gpu-metrics-emitter.py'], 
                                  capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                logger.info("✅ GPU metrics emitted successfully")
                return True
            else:
                logger.error(f"❌ GPU metrics failed: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"❌ Error emitting GPU metrics: {e}")
            return False

    def monitoring_cycle(self):
        """Single monitoring cycle"""
        cycle_start = datetime.now()
        
        # Check sidecar health
        self.animate_progress("Checking GPU sidecars", 25)
        healthy, total = self.check_gpu_sidecars()
        
        # Emit metrics
        self.animate_progress("Emitting GPU metrics", 50)
        metrics_success = self.emit_gpu_metrics()
        
        # Check SigNoz connectivity
        self.animate_progress("Checking SigNoz connectivity", 75)
        signoz_ok = False
        try:
            response = requests.get("http://localhost:8080/api/v1/health", timeout=5)
            signoz_ok = response.status_code == 200
        except:
            pass
        
        # Generate cycle report
        self.animate_progress("Generating cycle report", 100)
        cycle_duration = (datetime.now() - cycle_start).total_seconds()
        
        cycle_report = {
            "timestamp": datetime.now().isoformat(),
            "cycle_duration_seconds": cycle_duration,
            "healthy_sidecars": f"{healthy}/{total}",
            "metrics_success": metrics_success,
            "signoz_connectivity": signoz_ok,
            "overall_health": "healthy" if healthy == total and metrics_success else "degraded"
        }
        
        # Save cycle report
        report_file = log_dir / f"cycle-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(cycle_report, f, indent=2)
        
        print(f"\r✅ Cycle complete - {healthy}/{total} sidecars healthy, metrics: {'✅' if metrics_success else '❌'}")
        
        return cycle_report

    def run(self):
        """Run continuous monitoring"""
        logger.info(f"🚀 Starting GPU monitoring daemon (interval: {self.interval}s)")
        
        cycle_count = 0
        
        try:
            while self.running:
                cycle_count += 1
                logger.info(f"🔄 Starting monitoring cycle #{cycle_count}")
                
                cycle_report = self.monitoring_cycle()
                
                # Wait for next cycle
                if self.running:
                    logger.info(f"⏰ Waiting {self.interval} seconds until next cycle...")
                    for i in range(self.interval):
                        if not self.running:
                            break
                        time.sleep(1)
                        
        except KeyboardInterrupt:
            logger.info("🛑 Monitoring interrupted by user")
        except Exception as e:
            logger.error(f"❌ Monitoring error: {e}")
        finally:
            logger.info(f"🏁 GPU monitoring daemon completed ({cycle_count} cycles)")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="GPU Monitoring Daemon")
    parser.add_argument("--interval", type=int, default=30, help="Monitoring interval in seconds")
    parser.add_argument("--duration", type=int, default=0, help="Duration in minutes (0 = infinite)")
    
    args = parser.parse_args()
    
    daemon = GPUMonitoringDaemon(args.interval)
    
    if args.duration > 0:
        logger.info(f"🕐 Running for {args.duration} minutes")
        end_time = datetime.now() + timedelta(minutes=args.duration)
        
        while datetime.now() < end_time and daemon.running:
            daemon.monitoring_cycle()
            time.sleep(args.interval)
    else:
        daemon.run()

if __name__ == "__main__":
    main()