#!/usr/bin/env python3
"""
GPU Automated Monitoring Daemon
ECRR-Compliant automated GPU monitoring with progress indicators and alerting
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
import threading
from typing import Dict, List, Optional

# Configure logging with ECRR compliance
log_dir = Path("artifacts/gpu-monitoring")
log_dir.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(log_dir / f"gpu-monitoring-{datetime.now().strftime('%Y%m%d')}.log")
    ]
)
logger = logging.getLogger(__name__)

class GPUAutomatedMonitor:
    def __init__(self, config_file: str = "artifacts/gpu-monitoring-config.json"):
        self.config_file = Path(config_file)
        self.config = self.load_config()
        self.running = True
        self.metrics_buffer = []
        self.health_history = []
        self.alert_thresholds = {
            "gpu_utilization_critical": 95,
            "gpu_utilization_warning": 80,
            "gpu_memory_critical": 90,
            "gpu_memory_warning": 75,
            "gpu_temperature_critical": 85,
            "gpu_temperature_warning": 75,
            "sidecar_unhealthy_threshold": 3  # consecutive failures
        }
        
        # ECRR State tracking
        self.ecrr_state = {
            "examine_start": datetime.now(),
            "clean_actions": [],
            "report_artifacts": [],
            "role": "GPU-Automated-Monitor"
        }
        
        # Progress animation
        self.spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
        self.spinner_index = 0
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        logger.info("🔄 GPU Automated Monitor initialized with ECRR compliance")

    def load_config(self) -> Dict:
        """Load monitoring configuration with defaults"""
        default_config = {
            "monitoring_interval": 30,  # seconds
            "metrics_retention_hours": 24,
            "alert_cooldown_minutes": 5,
            "max_consecutive_failures": 5,
            "auto_recovery_enabled": True,
            "signoz_endpoint": "http://localhost:8080",
            "otel_endpoint": "http://localhost:5318/v1/metrics",
            "gpu_sidecar_ports": {
                "compression": 8001,
                "aggregation": 8002,
                "inference": 8003
            }
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    loaded_config = json.load(f)
                    default_config.update(loaded_config)
                    logger.info(f"✅ Loaded config from {self.config_file}")
            except Exception as e:
                logger.warning(f"⚠️ Failed to load config: {e}, using defaults")
        else:
            # Create default config file
            with open(self.config_file, 'w') as f:
                json.dump(default_config, f, indent=2)
                logger.info(f"📝 Created default config at {self.config_file}")
        
        return default_config

    def signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        logger.info(f"🛑 Received signal {signum}, initiating graceful shutdown...")
        self.running = False

    def animate_progress(self, message: str, progress: int = 0):
        """Display animated progress indicator"""
        self.spinner_index = (self.spinner_index + 1) % len(self.spinner_chars)
        spinner = self.spinner_chars[self.spinner_index]
        
        if progress > 0:
            print(f"\r{spinner} {message} ({progress}%)", end="", flush=True)
        else:
            print(f"\r{spinner} {message}", end="", flush=True)

    def examine_gpu_state(self) -> Dict:
        """ECRR Examine: Capture current GPU environment state"""
        logger.info("🔍 ECRR Examine: Capturing GPU environment state")
        
        state = {
            "timestamp": datetime.now().isoformat(),
            "docker_containers": {},
            "gpu_sidecars": {},
            "otel_pipeline": {},
            "signoz_connectivity": False
        }
        
        # Check Docker containers
        try:
            result = subprocess.run(['docker', 'ps', '--format', 'json'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                containers = [json.loads(line) for line in result.stdout.strip().split('\n') if line]
                gpu_containers = [c for c in containers if 'gpu' in c.get('Names', '').lower()]
                state["docker_containers"] = {c['Names']: c['Status'] for c in gpu_containers}
        except Exception as e:
            logger.error(f"❌ Failed to check Docker containers: {e}")
        
        # Check GPU sidecar health
        for service, port in self.config["gpu_sidecar_ports"].items():
            try:
                response = requests.get(f"http://localhost:{port}/health", timeout=5)
                state["gpu_sidecars"][service] = {
                    "healthy": response.status_code == 200,
                    "port": port,
                    "response_time_ms": response.elapsed.total_seconds() * 1000
                }
            except Exception as e:
                state["gpu_sidecars"][service] = {
                    "healthy": False,
                    "port": port,
                    "error": str(e)
                }
        
        # Check OTel pipeline
        try:
            response = requests.get(f"{self.config['otel_endpoint'].replace('/v1/metrics', '/health')}", timeout=5)
            state["otel_pipeline"] = {
                "healthy": response.status_code == 200,
                "endpoint": self.config['otel_endpoint']
            }
        except Exception as e:
            state["otel_pipeline"] = {
                "healthy": False,
                "endpoint": self.config['otel_endpoint'],
                "error": str(e)
            }
        
        # Check SigNoz connectivity
        try:
            response = requests.get(f"{self.config['signoz_endpoint']}/api/v1/health", timeout=5)
            state["signoz_connectivity"] = response.status_code == 200
        except Exception as e:
            logger.warning(f"⚠️ SigNoz connectivity check failed: {e}")
        
        # Save examine state
        examine_file = log_dir / f"examine-state-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(examine_file, 'w') as f:
            json.dump(state, f, indent=2)
        
        self.ecrr_state["report_artifacts"].append(str(examine_file))
        logger.info(f"📊 Examine state saved to {examine_file}")
        
        return state

    def clean_gpu_environment(self, state: Dict) -> List[str]:
        """ECRR Clean: Remove drift and enforce guardrails"""
        logger.info("🧹 ECRR Clean: Removing GPU environment drift")
        
        clean_actions = []
        
        # Restart unhealthy sidecars
        for service, health in state["gpu_sidecars"].items():
            if not health["healthy"]:
                logger.warning(f"⚠️ Unhealthy sidecar detected: {service}")
                try:
                    # Restart specific container
                    container_name = f"otel-gpu-{service}"
                    subprocess.run(['docker', 'restart', container_name], 
                                 capture_output=True, timeout=30)
                    clean_actions.append(f"restarted_unhealthy_sidecar_{service}")
                    logger.info(f"✅ Restarted {service} sidecar")
                except Exception as e:
                    logger.error(f"❌ Failed to restart {service}: {e}")
                    clean_actions.append(f"failed_restart_{service}")
        
        # Clean old metrics buffer
        cutoff_time = datetime.now() - timedelta(hours=self.config["metrics_retention_hours"])
        self.metrics_buffer = [m for m in self.metrics_buffer 
                              if datetime.fromisoformat(m["timestamp"]) > cutoff_time]
        
        if len(self.metrics_buffer) > 1000:  # Prevent memory bloat
            self.metrics_buffer = self.metrics_buffer[-500:]  # Keep last 500
            clean_actions.append("cleaned_metrics_buffer")
        
        # Clean old health history
        self.health_history = [h for h in self.health_history 
                              if datetime.fromisoformat(h["timestamp"]) > cutoff_time]
        
        self.ecrr_state["clean_actions"].extend(clean_actions)
        logger.info(f"🧹 Clean actions completed: {clean_actions}")
        
        return clean_actions

    def emit_gpu_metrics(self) -> bool:
        """Emit GPU metrics to OTel pipeline with progress tracking"""
        logger.info("📊 Emitting GPU metrics to OTel pipeline")
        
        try:
            # Run GPU metrics emitter
            result = subprocess.run(['python', 'scripts/gpu-metrics-emitter.py'], 
                                  capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                logger.info("✅ GPU metrics emitted successfully")
                
                # Parse metrics from output for buffering
                metrics_data = {
                    "timestamp": datetime.now().isoformat(),
                    "success": True,
                    "services": ["compression", "aggregation", "inference"],
                    "output": result.stdout
                }
                self.metrics_buffer.append(metrics_data)
                
                return True
            else:
                logger.error(f"❌ GPU metrics emission failed: {result.stderr}")
                metrics_data = {
                    "timestamp": datetime.now().isoformat(),
                    "success": False,
                    "error": result.stderr
                }
                self.metrics_buffer.append(metrics_data)
                return False
                
        except Exception as e:
            logger.error(f"❌ Error emitting GPU metrics: {e}")
            metrics_data = {
                "timestamp": datetime.now().isoformat(),
                "success": False,
                "error": str(e)
            }
            self.metrics_buffer.append(metrics_data)
            return False

    def check_alerts(self, state: Dict) -> List[Dict]:
        """Check for alert conditions and generate alerts"""
        alerts = []
        
        # Check sidecar health
        unhealthy_sidecars = [name for name, health in state["gpu_sidecars"].items() 
                             if not health["healthy"]]
        
        if unhealthy_sidecars:
            alert = {
                "type": "sidecar_unhealthy",
                "severity": "critical",
                "message": f"Unhealthy GPU sidecars: {', '.join(unhealthy_sidecars)}",
                "timestamp": datetime.now().isoformat(),
                "services": unhealthy_sidecars
            }
            alerts.append(alert)
            logger.warning(f"🚨 ALERT: {alert['message']}")
        
        # Check OTel pipeline
        if not state["otel_pipeline"]["healthy"]:
            alert = {
                "type": "otel_pipeline_down",
                "severity": "critical", 
                "message": "OTel pipeline is down",
                "timestamp": datetime.now().isoformat()
            }
            alerts.append(alert)
            logger.warning(f"🚨 ALERT: {alert['message']}")
        
        # Check SigNoz connectivity
        if not state["signoz_connectivity"]:
            alert = {
                "type": "signoz_unreachable",
                "severity": "warning",
                "message": "SigNoz UI is unreachable",
                "timestamp": datetime.now().isoformat()
            }
            alerts.append(alert)
            logger.warning(f"🚨 ALERT: {alert['message']}")
        
        return alerts

    def generate_report(self, state: Dict, clean_actions: List[str], alerts: List[Dict]) -> str:
        """ECRR Report: Generate monitoring report and artifacts"""
        logger.info("📝 ECRR Report: Generating monitoring report")
        
        report = {
            "ecrr_report": {
                "examine": {
                    "start_time": self.ecrr_state["examine_start"].isoformat(),
                    "end_time": datetime.now().isoformat(),
                    "duration_seconds": (datetime.now() - self.ecrr_state["examine_start"]).total_seconds()
                },
                "clean": {
                    "actions": clean_actions,
                    "count": len(clean_actions)
                },
                "report": {
                    "artifacts": self.ecrr_state["report_artifacts"],
                    "alerts_generated": len(alerts),
                    "metrics_collected": len(self.metrics_buffer),
                    "health_history_entries": len(self.health_history)
                },
                "role": self.ecrr_state["role"]
            },
            "monitoring_summary": {
                "timestamp": datetime.now().isoformat(),
                "gpu_sidecars_status": state["gpu_sidecars"],
                "docker_containers": state["docker_containers"],
                "otel_pipeline_status": state["otel_pipeline"],
                "signoz_connectivity": state["signoz_connectivity"],
                "alerts": alerts,
                "clean_actions": clean_actions,
                "metrics_buffer_size": len(self.metrics_buffer),
                "health_history_size": len(self.health_history)
            }
        }
        
        # Save report
        report_file = log_dir / f"monitoring-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.ecrr_state["report_artifacts"].append(str(report_file))
        
        # Save alerts separately
        if alerts:
            alerts_file = log_dir / f"alerts-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
            with open(alerts_file, 'w') as f:
                json.dump(alerts, f, indent=2)
            self.ecrr_state["report_artifacts"].append(str(alerts_file))
        
        logger.info(f"📊 Report saved to {report_file}")
        return str(report_file)

    def monitoring_cycle(self):
        """Single monitoring cycle with ECRR compliance"""
        cycle_start = datetime.now()
        
        # ECRR Examine
        self.animate_progress("Examining GPU state", 20)
        state = self.examine_gpu_state()
        
        # ECRR Clean
        self.animate_progress("Cleaning GPU environment", 40)
        clean_actions = self.clean_gpu_environment(state)
        
        # Emit metrics
        self.animate_progress("Emitting GPU metrics", 60)
        metrics_success = self.emit_gpu_metrics()
        
        # Check alerts
        self.animate_progress("Checking alerts", 80)
        alerts = self.check_alerts(state)
        
        # ECRR Report
        self.animate_progress("Generating report", 100)
        report_file = self.generate_report(state, clean_actions, alerts)
        
        # Update health history
        health_entry = {
            "timestamp": datetime.now().isoformat(),
            "cycle_duration_seconds": (datetime.now() - cycle_start).total_seconds(),
            "metrics_success": metrics_success,
            "alerts_count": len(alerts),
            "clean_actions_count": len(clean_actions),
            "overall_health": "healthy" if not alerts else "degraded"
        }
        self.health_history.append(health_entry)
        
        print(f"\r✅ Monitoring cycle complete - {len(alerts)} alerts, {len(clean_actions)} clean actions")
        
        return {
            "state": state,
            "clean_actions": clean_actions,
            "alerts": alerts,
            "report_file": report_file,
            "health_entry": health_entry
        }

    def run_continuous_monitoring(self):
        """Run continuous monitoring with ECRR compliance"""
        logger.info("🚀 Starting continuous GPU monitoring with ECRR compliance")
        logger.info(f"📋 Configuration: {self.config}")
        
        cycle_count = 0
        
        try:
            while self.running:
                cycle_count += 1
                logger.info(f"🔄 Starting monitoring cycle #{cycle_count}")
                
                # Run monitoring cycle
                cycle_result = self.monitoring_cycle()
                
                # Log cycle summary
                logger.info(f"📊 Cycle #{cycle_count} Summary:")
                logger.info(f"   - Alerts: {len(cycle_result['alerts'])}")
                logger.info(f"   - Clean actions: {len(cycle_result['clean_actions'])}")
                logger.info(f"   - Metrics success: {cycle_result['health_entry']['metrics_success']}")
                
                # Wait for next cycle
                if self.running:
                    logger.info(f"⏰ Waiting {self.config['monitoring_interval']} seconds until next cycle...")
                    for i in range(self.config['monitoring_interval']):
                        if not self.running:
                            break
                        time.sleep(1)
                        
        except KeyboardInterrupt:
            logger.info("🛑 Monitoring interrupted by user")
        except Exception as e:
            logger.error(f"❌ Monitoring error: {e}")
        finally:
            logger.info("🏁 GPU monitoring daemon shutting down")
            self.generate_final_report(cycle_count)

    def generate_final_report(self, total_cycles: int):
        """Generate final ECRR report"""
        final_report = {
            "final_ecrr_report": {
                "total_monitoring_cycles": total_cycles,
                "total_duration": (datetime.now() - self.ecrr_state["examine_start"]).total_seconds(),
                "total_clean_actions": len(self.ecrr_state["clean_actions"]),
                "total_artifacts": len(self.ecrr_state["report_artifacts"]),
                "final_metrics_buffer_size": len(self.metrics_buffer),
                "final_health_history_size": len(self.health_history),
                "role": self.ecrr_state["role"],
                "shutdown_time": datetime.now().isoformat()
            }
        }
        
        final_file = log_dir / f"final-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(final_file, 'w') as f:
            json.dump(final_report, f, indent=2)
        
        logger.info(f"📊 Final ECRR report saved to {final_file}")
        logger.info("🎯 GPU Automated Monitoring Complete - ECRR Compliant")

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="GPU Automated Monitoring Daemon")
    parser.add_argument("--config", default="artifacts/gpu-monitoring-config.json",
                       help="Configuration file path")
    parser.add_argument("--duration", type=int, default=0,
                       help="Duration in minutes (0 = infinite)")
    parser.add_argument("--interval", type=int, default=30,
                       help="Monitoring interval in seconds")
    
    args = parser.parse_args()
    
    # Create monitor instance
    monitor = GPUAutomatedMonitor(args.config)
    
    # Override interval if specified
    if args.interval != 30:
        monitor.config["monitoring_interval"] = args.interval
    
    # Run monitoring
    if args.duration > 0:
        logger.info(f"🕐 Running for {args.duration} minutes")
        end_time = datetime.now() + timedelta(minutes=args.duration)
        
        while datetime.now() < end_time and monitor.running:
            monitor.monitoring_cycle()
            time.sleep(monitor.config["monitoring_interval"])
    else:
        monitor.run_continuous_monitoring()

if __name__ == "__main__":
    main()