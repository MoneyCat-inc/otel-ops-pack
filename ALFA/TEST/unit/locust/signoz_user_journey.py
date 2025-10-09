from locust import HttpUser, task, between
import random
import time
import os

class SigNozUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Initialize user session"""
        self.base_url = os.getenv('SIGNOZ_URL', 'http://localhost:8080')
        self.queries = [
            'message contains "canary test"',
            'attributes.dataset = "resonai_analytics"',
            'level = "error"',
            'service.name = "otelcol-contrib"',
            'otelcol_*',
        ]
    
    @task(3)
    def query_logs(self):
        """Query logs endpoint - most common operation"""
        query = random.choice(self.queries)
        params = {
            'query': query,
            'start': int(time.time()) - 3600,  # Last hour
            'end': int(time.time()),
            'limit': 100,
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/logs",
            params=params,
            catch_response=True,
            name="logs_query"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Logs query failed with status {response.status_code}")
    
    @task(2)
    def query_metrics(self):
        """Query metrics endpoint"""
        metrics_queries = [
            'rate(otelcol_processor_batch_batch_send_size_sum[5m])',
            'otelcol_processor_batch_batch_send_size_count',
            'rate(otelcol_processor_batch_batch_send_size_sum[1m]) / rate(otelcol_processor_batch_batch_send_size_count[1m])',
        ]
        
        query = random.choice(metrics_queries)
        params = {
            'query': query,
            'start': int(time.time()) - 3600,
            'end': int(time.time()),
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/metrics",
            params=params,
            catch_response=True,
            name="metrics_query"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Metrics query failed with status {response.status_code}")
    
    @task(1)
    def check_health(self):
        """Check health endpoint"""
        with self.client.get(
            f"{self.base_url}/api/v1/health",
            catch_response=True,
            name="health_check"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed with status {response.status_code}")
    
    @task(1)
    def complex_query(self):
        """Execute complex query to simulate power users"""
        complex_queries = [
            'message contains "canary test" AND level = "info" AND attributes.dataset = "resonai_analytics"',
            'otelcol_processor_batch_batch_send_size_sum > 1000 AND otelcol_processor_batch_batch_send_size_count > 10',
            'service.name = "otelcol-contrib" AND resource.attributes.host.name contains "windows"',
        ]
        
        query = random.choice(complex_queries)
        params = {
            'query': query,
            'start': int(time.time()) - 7200,  # Last 2 hours
            'end': int(time.time()),
            'limit': 1000,
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/logs",
            params=params,
            catch_response=True,
            name="complex_query"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Complex query failed with status {response.status_code}")


class SigNozLoadTest(HttpUser):
    """Load test configuration for sustained high load"""
    wait_time = between(0.5, 1.5)
    
    def on_start(self):
        self.base_url = os.getenv('SIGNOZ_URL', 'http://localhost:8080')
    
    @task(5)
    def rapid_logs_query(self):
        """Rapid logs queries for load testing"""
        params = {
            'query': 'message contains "canary test"',
            'start': int(time.time()) - 1800,  # Last 30 minutes
            'end': int(time.time()),
            'limit': 50,
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/logs",
            params=params,
            catch_response=True,
            name="rapid_logs_query"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Rapid logs query failed with status {response.status_code}")
    
    @task(3)
    def rapid_metrics_query(self):
        """Rapid metrics queries for load testing"""
        params = {
            'query': 'rate(otelcol_processor_batch_batch_send_size_sum[1m])',
            'start': int(time.time()) - 1800,
            'end': int(time.time()),
        }
        
        with self.client.get(
            f"{self.base_url}/api/v1/metrics",
            params=params,
            catch_response=True,
            name="rapid_metrics_query"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Rapid metrics query failed with status {response.status_code}")
    
    @task(1)
    def health_check(self):
        """Health checks during load test"""
        with self.client.get(
            f"{self.base_url}/api/v1/health",
            catch_response=True,
            name="load_health_check"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Load health check failed with status {response.status_code}")
