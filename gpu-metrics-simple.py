#!/usr/bin/env python3
"""
Simple GPU Metrics Emitter for SigNoz Integration
Sends RTX 2080 Super metrics to OpenTelemetry Collector via OTLP
"""

import time
import json
import os
from datetime import datetime
from pathlib import Path

try:
    import pynvml
    from opentelemetry import metrics
    from opentelemetry.sdk.metrics import MeterProvider
    from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
    from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
    from opentelemetry.sdk.resources import Resource
except ImportError as e:
    print(f"Missing dependencies: {e}")
    print("Please install: pip install opentelemetry-sdk opentelemetry-exporter-otlp nvidia-ml-py")
    exit(1)

class SimpleGPUMetricsEmitter:
    def __init__(self, otlp_endpoint="http://localhost:4317", service_name="gpu-monitor"):
        self.otlp_endpoint = otlp_endpoint
        self.service_name = service_name
        
        # Initialize NVML
        try:
            pynvml.nvmlInit()
            self.device_count = pynvml.nvmlDeviceGetCount()
            print(f"Found {self.device_count} NVIDIA GPU(s)")
            
            if self.device_count == 0:
                raise RuntimeError("No NVIDIA GPUs found")
                
            self.device_handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            device_name_bytes = pynvml.nvmlDeviceGetName(self.device_handle)
            self.device_name = device_name_bytes.decode('utf-8') if isinstance(device_name_bytes, bytes) else device_name_bytes
            print(f"Monitoring GPU: {self.device_name}")
            
        except Exception as e:
            print(f"Failed to initialize NVML: {e}")
            raise
        
        # Setup OpenTelemetry
        self._setup_telemetry()
        
    def _setup_telemetry(self):
        """Setup OpenTelemetry metrics pipeline"""
        try:
            # Create resource
            resource = Resource.create({
                "service.name": self.service_name,
                "service.version": "1.0.0",
                "gpu.name": self.device_name,
                "gpu.index": "0"
            })
            
            # Create OTLP exporter
            exporter = OTLPMetricExporter(
                endpoint=self.otlp_endpoint,
                insecure=True
            )
            
            # Create metric reader
            reader = PeriodicExportingMetricReader(
                exporter=exporter,
                export_interval_millis=15000  # Export every 15 seconds
            )
            
            # Create meter provider
            self.meter_provider = MeterProvider(
                resource=resource,
                metric_readers=[reader]
            )
            
            # Set global meter provider
            metrics.set_meter_provider(self.meter_provider)
            
            # Create meter
            self.meter = self.meter_provider.get_meter("gpu-metrics")
            
            print(f"OpenTelemetry metrics configured for {self.otlp_endpoint}")
            
        except Exception as e:
            print(f"Failed to setup telemetry: {e}")
            raise
    
    def get_gpu_metrics(self, device_index=0):
        """Get current GPU metrics for a specific device"""
        try:
            device_handle = pynvml.nvmlDeviceGetHandleByIndex(device_index)
            
            # Utilization rates
            util = pynvml.nvmlDeviceGetUtilizationRates(device_handle)
            gpu_util = util.gpu
            memory_util = util.memory
            
            # Memory info
            memory_info = pynvml.nvmlDeviceGetMemoryInfo(device_handle)
            memory_used = memory_info.used
            memory_total = memory_info.total
            memory_util_percent = (memory_used / memory_total) * 100
            
            # Temperature
            temperature = pynvml.nvmlDeviceGetTemperature(device_handle, pynvml.NVML_TEMPERATURE_GPU)
            
            # Power
            power_draw = pynvml.nvmlDeviceGetPowerUsage(device_handle) / 1000.0  # Convert to watts
            
            # Clock speeds
            graphics_clock = pynvml.nvmlDeviceGetClockInfo(device_handle, pynvml.NVML_CLOCK_GRAPHICS)
            memory_clock = pynvml.nvmlDeviceGetClockInfo(device_handle, pynvml.NVML_CLOCK_MEM)
            
            # Fan speed
            try:
                fan_speed = pynvml.nvmlDeviceGetFanSpeed(device_handle)
            except:
                fan_speed = 0  # Some GPUs don't report fan speed
            
            # Get device name
            device_name_bytes = pynvml.nvmlDeviceGetName(device_handle)
            device_name = device_name_bytes.decode('utf-8') if isinstance(device_name_bytes, bytes) else device_name_bytes
            
            return {
                'device_index': device_index,
                'device_name': device_name,
                'gpu_util': gpu_util,
                'memory_used': memory_used,
                'memory_total': memory_total,
                'memory_util': memory_util_percent,
                'temperature': temperature,
                'power_draw': power_draw,
                'graphics_clock': graphics_clock,
                'memory_clock': memory_clock,
                'fan_speed': fan_speed
            }
            
        except Exception as e:
            print(f"Error getting GPU metrics for device {device_index}: {e}")
            return None
    
    def get_all_gpu_metrics(self):
        """Get metrics for all available GPUs"""
        all_metrics = []
        for i in range(self.device_count):
            metrics = self.get_gpu_metrics(i)
            if metrics:
                all_metrics.append(metrics)
        return all_metrics
    
    def emit_metrics(self):
        """Emit current GPU metrics using simple gauge updates"""
        metrics_data = self.get_gpu_metrics()
        if not metrics_data:
            return False
        
        try:
            # Create gauges for each metric
            gpu_util_gauge = self.meter.create_gauge(
                name="gpu.utilization.percent",
                description="GPU utilization percentage",
                unit="percent"
            )
            
            memory_used_gauge = self.meter.create_gauge(
                name="gpu.memory.used.bytes",
                description="GPU memory used in bytes",
                unit="bytes"
            )
            
            memory_total_gauge = self.meter.create_gauge(
                name="gpu.memory.total.bytes",
                description="GPU total memory in bytes",
                unit="bytes"
            )
            
            memory_util_gauge = self.meter.create_gauge(
                name="gpu.memory.utilization.percent",
                description="GPU memory utilization percentage",
                unit="percent"
            )
            
            temperature_gauge = self.meter.create_gauge(
                name="gpu.temperature.celsius",
                description="GPU temperature in Celsius",
                unit="celsius"
            )
            
            power_draw_gauge = self.meter.create_gauge(
                name="gpu.power.draw.watts",
                description="GPU power draw in watts",
                unit="watts"
            )
            
            graphics_clock_gauge = self.meter.create_gauge(
                name="gpu.clock.graphics.mhz",
                description="GPU graphics clock in MHz",
                unit="mhz"
            )
            
            memory_clock_gauge = self.meter.create_gauge(
                name="gpu.clock.memory.mhz",
                description="GPU memory clock in MHz",
                unit="mhz"
            )
            
            fan_speed_gauge = self.meter.create_gauge(
                name="gpu.fan.speed.percent",
                description="GPU fan speed percentage",
                unit="percent"
            )
            
            # Update gauges with current values
            gpu_util_gauge.set(metrics_data['gpu_util'])
            memory_used_gauge.set(metrics_data['memory_used'])
            memory_total_gauge.set(metrics_data['memory_total'])
            memory_util_gauge.set(metrics_data['memory_util'])
            temperature_gauge.set(metrics_data['temperature'])
            power_draw_gauge.set(metrics_data['power_draw'])
            graphics_clock_gauge.set(metrics_data['graphics_clock'])
            memory_clock_gauge.set(metrics_data['memory_clock'])
            fan_speed_gauge.set(metrics_data['fan_speed'])
            
            # Force export
            self.meter_provider.force_flush()
            
            return True
            
        except Exception as e:
            print(f"Error emitting metrics: {e}")
            return False
    
    def save_metrics_to_file(self, metrics_data, output_dir="C:/otel/.agent/reports"):
        """Save metrics to JSON file for backup/debugging"""
        try:
            os.makedirs(output_dir, exist_ok=True)
            
            timestamp = datetime.now().isoformat()
            metrics_data['timestamp'] = timestamp
            metrics_data['gpu_name'] = self.device_name
            
            output_file = Path(output_dir) / f"gpu_metrics_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            
            with open(output_file, 'w') as f:
                json.dump(metrics_data, f, indent=2)
            
            print(f"Metrics saved to: {output_file}")
            
        except Exception as e:
            print(f"Error saving metrics to file: {e}")
    
    def run(self, duration=300, interval=15, save_to_file=True):
        """Run metrics emission for specified duration"""
        print(f"Starting GPU metrics emission for {duration} seconds (every {interval} seconds)")
        print(f"OTLP endpoint: {self.otlp_endpoint}")
        print(f"GPU: {self.device_name}")
        print("Press Ctrl+C to stop early")
        
        start_time = time.time()
        end_time = start_time + duration
        
        try:
            while time.time() < end_time:
                metrics_data = self.get_gpu_metrics()
                if metrics_data:
                    success = self.emit_metrics()
                    if success:
                        print(f"[{datetime.now().strftime('%H:%M:%S')}] GPU: {metrics_data['gpu_util']}% | "
                              f"Memory: {metrics_data['memory_util']:.1f}% | "
                              f"Temp: {metrics_data['temperature']}°C | "
                              f"Power: {metrics_data['power_draw']:.1f}W")
                    
                    if save_to_file:
                        self.save_metrics_to_file(metrics_data)
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\nStopping metrics emission...")
        
        print("GPU metrics emission completed")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Simple GPU Metrics Emitter for SigNoz")
    parser.add_argument("--endpoint", default="http://localhost:4317", 
                       help="OTLP endpoint (default: http://localhost:4317)")
    parser.add_argument("--duration", type=int, default=300,
                       help="Duration in seconds (default: 300)")
    parser.add_argument("--interval", type=int, default=15,
                       help="Interval in seconds (default: 15)")
    parser.add_argument("--no-file", action="store_true",
                       help="Don't save metrics to file")
    
    args = parser.parse_args()
    
    try:
        emitter = SimpleGPUMetricsEmitter(otlp_endpoint=args.endpoint)
        emitter.run(
            duration=args.duration,
            interval=args.interval,
            save_to_file=not args.no_file
        )
    except Exception as e:
        print(f"Fatal error: {e}")
        exit(1)

if __name__ == "__main__":
    main()
