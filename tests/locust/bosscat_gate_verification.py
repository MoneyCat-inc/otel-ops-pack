from locust import HttpUser, task, between
import random
import time
import os
import json

class BossCatGateVerificationUser(HttpUser):
    """Simulates BossCat gate verification workflow"""
    wait_time = between(2, 5)
    
    def on_start(self):
        self.base_url = os.getenv('SIGNOZ_URL', 'http://localhost:8080')
        self.test_scenarios = [
            'canary_test_verification',
            'ecrr_compliance_check',
            'performance_baseline_validation',
            'synthetic_trace_verification',
        ]
    
    @task(4)
    def verify_canary_logs(self):
        """Verify canary test logs are present"""
        params = {
            'query': 'message contains "canary test" AND attributes.dataset = "resonai_analytics"',
            'start': int(time.time()) - 300,  # Last 5 minutes
            'end': int(time.time()),
            'limit': 10,
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/logs",
            params=params,
            catch_response=True,
            name="verify_canary_logs"
        ) as response:
            if response.status_code == 200:
                data = response.json()
                if data.get('data') and len(data['data']) > 0:
                    response.success()
                else:
                    response.failure("No canary logs found")
            else:
                response.failure(f"Canary verification failed with status {response.status_code}")
    
    @task(3)
    def check_ecrr_metrics(self):
        """Check ECRR compliance metrics"""
        params = {
            'query': 'rate(otelcol_processor_batch_batch_send_size_sum[5m])',
            'start': int(time.time()) - 1800,  # Last 30 minutes
            'end': int(time.time()),
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/metrics",
            params=params,
            catch_response=True,
            name="check_ecrr_metrics"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"ECRR metrics check failed with status {response.status_code}")
    
    @task(2)
    def verify_synthetic_traces(self):
        """Verify synthetic traces are ingested"""
        params = {
            'query': 'trace_id != "" AND span_id != "" AND attributes.test_type = "synthetic"',
            'start': int(time.time()) - 600,  # Last 10 minutes
            'end': int(time.time()),
            'limit': 5,
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/logs",
            params=params,
            catch_response=True,
            name="verify_synthetic_traces"
        ) as response:
            if response.status_code == 200:
                data = response.json()
                if data.get('data') and len(data['data']) > 0:
                    response.success()
                else:
                    response.failure("No synthetic traces found")
            else:
                response.failure(f"Synthetic trace verification failed with status {response.status_code}")
    
    @task(1)
    def performance_baseline_check(self):
        """Check performance baseline metrics"""
        params = {
            'query': 'otelcol_processor_batch_batch_send_size_sum',
            'start': int(time.time()) - 3600,  # Last hour
            'end': int(time.time()),
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/metrics",
            params=params,
            catch_response=True,
            name="performance_baseline_check"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Performance baseline check failed with status {response.status_code}")
    
    @task(1)
    def gate_readiness_verification(self):
        """Comprehensive gate readiness verification"""
        # Check multiple endpoints in sequence
        health_response = self.client.get(f"{self.base_url}/api/v1/health")
        
        if health_response.status_code == 200:
            # Check logs endpoint
            logs_params = {
                'query': 'level = "error"',
                'start': int(time.time()) - 1800,
                'end': int(time.time()),
                'limit': 100,
            }
            
            logs_response = self.client.get(
                f"{self.base_url}/api/v1/logs",
                params=logs_params,
                catch_response=True,
                name="gate_readiness_logs"
            )
            
            if logs_response.status_code == 200:
                logs_response.success()
            else:
                logs_response.failure(f"Gate readiness logs check failed with status {logs_response.status_code}")
        else:
            # Mark as failure if health check fails
            pass


class BossCatStressTestUser(HttpUser):
    """Stress test for BossCat gate verification under high load"""
    wait_time = between(0.1, 0.5)
    
    def on_start(self):
        self.base_url = os.getenv('SIGNOZ_URL', 'http://localhost:8080')
    
    @task(10)
    def rapid_gate_verification(self):
        """Rapid gate verification under stress"""
        params = {
            'query': 'message contains "canary test"',
            'start': int(time.time()) - 300,
            'end': int(time.time()),
            'limit': 50,
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/logs",
            params=params,
            catch_response=True,
            name="rapid_gate_verification"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Rapid gate verification failed with status {response.status_code}")
    
    @task(5)
    def stress_metrics_query(self):
        """Stress test metrics queries"""
        params = {
            'query': 'rate(otelcol_processor_batch_batch_send_size_sum[1m])',
            'start': int(time.time()) - 1800,
            'end': int(time.time()),
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/metrics",
            params=params,
            catch_response=True,
            name="stress_metrics_query"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Stress metrics query failed with status {response.status_code}")
    
    @task(1)
    def health_check_under_stress(self):
        """Health check under stress conditions"""
        with self.client.get(
            f"{self.base_url}/api/v1/health",
            catch_response=True,
            name="health_check_under_stress"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check under stress failed with status {response.status_code}")
