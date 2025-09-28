#!/usr/bin/env python3
"""
GPU Metrics Emitter for SigNoz Integration
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

class GPUMetricsEmitter:
    def __init__(self, otlp_endpoint="http://localhost:14317", service_name="gpu-monitor"):
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
            
            # Create metrics
            self._create_metrics()
            
            print(f"OpenTelemetry metrics configured for {self.otlp_endpoint}")
            
        except Exception as e:
            print(f"Failed to setup telemetry: {e}")
            raise
    
    def _create_metrics(self):
        """Create GPU metrics"""
        # GPU Utilization
        self.gpu_util_gauge = self.meter.create_observable_gauge(
            name="gpu.utilization.percent",
            description="GPU utilization percentage",
            unit="percent",
            callbacks=[self._get_gpu_utilization]
        )
        
        # Memory Utilization
        self.memory_used_gauge = self.meter.create_observable_gauge(
            name="gpu.memory.used.bytes",
            description="GPU memory used in bytes",
            unit="bytes",
            callbacks=[self._get_memory_used]
        )
        
        self.memory_total_gauge = self.meter.create_observable_gauge(
            name="gpu.memory.total.bytes",
            description="GPU total memory in bytes",
            unit="bytes",
            callbacks=[self._get_memory_total]
        )
        
        self.memory_util_gauge = self.meter.create_observable_gauge(
            name="gpu.memory.utilization.percent",
            description="GPU memory utilization percentage",
            unit="percent",
            callbacks=[self._get_memory_utilization]
        )
        
        # Temperature
        self.temperature_gauge = self.meter.create_observable_gauge(
            name="gpu.temperature.celsius",
            description="GPU temperature in Celsius",
            unit="celsius",
            callbacks=[self._get_temperature]
        )
        
        # Power
        self.power_draw_gauge = self.meter.create_observable_gauge(
            name="gpu.power.draw.watts",
            description="GPU power draw in watts",
            unit="watts",
            callbacks=[self._get_power_draw]
        )
        
        # Clock speeds
        self.graphics_clock_gauge = self.meter.create_observable_gauge(
            name="gpu.clock.graphics.mhz",
            description="GPU graphics clock in MHz",
            unit="mhz",
            callbacks=[self._get_graphics_clock]
        )
        
        self.memory_clock_gauge = self.meter.create_observable_gauge(
            name="gpu.clock.memory.mhz",
            description="GPU memory clock in MHz",
            unit="mhz",
            callbacks=[self._get_memory_clock]
        )
        
        # Fan speed
        self.fan_speed_gauge = self.meter.create_observable_gauge(
            name="gpu.fan.speed.percent",
            description="GPU fan speed percentage",
            unit="percent",
            callbacks=[self._get_fan_speed]
        )
    
    def _get_gpu_utilization(self, callback_options=None):
        """Callback for GPU utilization metric"""
        util = pynvml.nvmlDeviceGetUtilizationRates(self.device_handle)
        return util.gpu
    
    def _get_memory_used(self, callback_options=None):
        """Callback for GPU memory used metric"""
        memory_info = pynvml.nvmlDeviceGetMemoryInfo(self.device_handle)
        return memory_info.used
    
    def _get_memory_total(self, callback_options=None):
        """Callback for GPU memory total metric"""
        memory_info = pynvml.nvmlDeviceGetMemoryInfo(self.device_handle)
        return memory_info.total
    
    def _get_memory_utilization(self, callback_options=None):
        """Callback for GPU memory utilization metric"""
        memory_info = pynvml.nvmlDeviceGetMemoryInfo(self.device_handle)
        return (memory_info.used / memory_info.total) * 100
    
    def _get_temperature(self, callback_options=None):
        """Callback for GPU temperature metric"""
        return pynvml.nvmlDeviceGetTemperature(self.device_handle, pynvml.NVML_TEMPERATURE_GPU)
    
    def _get_power_draw(self, callback_options=None):
        """Callback for GPU power draw metric"""
        return pynvml.nvmlDeviceGetPowerUsage(self.device_handle) / 1000.0  # Convert to watts
    
    def _get_graphics_clock(self, callback_options=None):
        """Callback for GPU graphics clock metric"""
        return pynvml.nvmlDeviceGetClockInfo(self.device_handle, pynvml.NVML_CLOCK_GRAPHICS)
    
    def _get_memory_clock(self, callback_options=None):
        """Callback for GPU memory clock metric"""
        return pynvml.nvmlDeviceGetClockInfo(self.device_handle, pynvml.NVML_CLOCK_MEM)
    
    def _get_fan_speed(self, callback_options=None):
        """Callback for GPU fan speed metric"""
        try:
            return pynvml.nvmlDeviceGetFanSpeed(self.device_handle, 0)
        except:
            return 0  # Some GPUs don't support fan speed reading
    
    def get_gpu_metrics(self):
        """Get current GPU metrics"""
        try:
            # Utilization rates
            util = pynvml.nvmlDeviceGetUtilizationRates(self.device_handle)
            gpu_util = util.gpu
            memory_util = util.memory
            
            # Memory info
            memory_info = pynvml.nvmlDeviceGetMemoryInfo(self.device_handle)
            memory_used = memory_info.used
            memory_total = memory_info.total
            memory_util_percent = (memory_used / memory_total) * 100
            
            # Temperature
            temperature = pynvml.nvmlDeviceGetTemperature(self.device_handle, pynvml.NVML_TEMPERATURE_GPU)
            
            # Power
            power_draw = pynvml.nvmlDeviceGetPowerUsage(self.device_handle) / 1000.0  # Convert to watts
            
            # Clock speeds
            graphics_clock = pynvml.nvmlDeviceGetClockInfo(self.device_handle, pynvml.NVML_CLOCK_GRAPHICS)
            memory_clock = pynvml.nvmlDeviceGetClockInfo(self.device_handle, pynvml.NVML_CLOCK_MEM)
            
            # Fan speed
            try:
                fan_speed = pynvml.nvmlDeviceGetFanSpeed(self.device_handle)
            except:
                fan_speed = 0  # Some GPUs don't report fan speed
            
            return {
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
            print(f"Error getting GPU metrics: {e}")
            return None
    
    def emit_metrics(self):
        """Emit current GPU metrics"""
        try:
            # Force export - callbacks are automatically called
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
    
    parser = argparse.ArgumentParser(description="GPU Metrics Emitter for SigNoz")
    parser.add_argument("--endpoint", default="http://localhost:14317", 
                       help="OTLP endpoint (default: http://localhost:14317)")
    parser.add_argument("--duration", type=int, default=300,
                       help="Duration in seconds (default: 300)")
    parser.add_argument("--interval", type=int, default=15,
                       help="Interval in seconds (default: 15)")
    parser.add_argument("--no-file", action="store_true",
                       help="Don't save metrics to file")
    
    args = parser.parse_args()
    
    try:
        emitter = GPUMetricsEmitter(otlp_endpoint=args.endpoint)
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
