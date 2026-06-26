#!/usr/bin/env python3
"""
GPU ML Inference Sidecar for OpenTelemetry Workloads
Processes telemetry batches using NVIDIA Triton for ML inference and anomaly detection
"""

import os
import json
import time
import asyncio
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime

import numpy as np
import tritonclient.http as tritonhttp
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class InferenceConfig:
    """Configuration for GPU inference sidecar"""
    input_dir: str = "/app/gpu-buffers/inference"
    output_endpoint: str = "http://localhost:4318/v1/logs"
    triton_url: str = os.getenv("TRITON_URL", "triton:8000")
    batch_size: int = 1000  # records
    batch_timeout: float = 30.0  # seconds
    poll_interval: float = 2.0  # seconds
    model_name: str = "log_anomaly_detector"
    model_version: str = "1"

class InferenceRequest(BaseModel):
    """Request model for inference API"""
    data: List[Dict[str, Any]]
    model_name: str = "log_anomaly_detector"
    features: Optional[List[str]] = None

class InferenceResponse(BaseModel):
    """Response model for inference API"""
    predictions: List[Dict[str, Any]]
    original_count: int
    processed_count: int
    processing_time_ms: float
    model_name: str
    anomaly_count: int

class GPUInferenceSidecar:
    """Main ML inference sidecar service"""
    
    def __init__(self, config: InferenceConfig):
        self.config = config
        self.app = FastAPI(title="GPU ML Inference Sidecar", version="1.0.0")
        self.setup_routes()
        self.setup_directories()
        self.triton_client = None
        self.available_models = []
        
    def setup_directories(self):
        """Create necessary directories"""
        Path(self.config.input_dir).mkdir(parents=True, exist_ok=True)
        
    def setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.post("/infer", response_model=InferenceResponse)
        async def infer_data(request: InferenceRequest):
            """Run ML inference on a batch of telemetry data"""
            try:
                start_time = time.time()
                
                if not request.data:
                    return InferenceResponse(
                        predictions=[],
                        original_count=0,
                        processed_count=0,
                        processing_time_ms=0.0,
                        model_name=request.model_name,
                        anomaly_count=0
                    )
                
                # Extract features for inference
                features = self._extract_features(request.data, request.features)
                
                # Run inference
                predictions = await self._run_inference(features, request.model_name)
                
                processed_count = len(predictions)
                anomaly_count = sum(1 for p in predictions if p.get('is_anomaly', False))
                processing_time = (time.time() - start_time) * 1000
                
                logger.info(f"Inferred {len(request.data)} records, found {anomaly_count} anomalies "
                          f"in {processing_time:.2f}ms")
                
                return InferenceResponse(
                    predictions=predictions,
                    original_count=len(request.data),
                    processed_count=processed_count,
                    processing_time_ms=processing_time,
                    model_name=request.model_name,
                    anomaly_count=anomaly_count
                )
                
            except Exception as e:
                logger.error(f"Inference failed: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            return {
                "status": "healthy", 
                "triton_available": self._check_triton_availability(),
                "available_models": self.available_models
            }

        @self.app.get("/health/deep")
        async def deep_health_check():
            """Deep health with Triton repository status"""
            triton_ok = self._check_triton_availability()
            details = {"triton_url": self.config.triton_url, "available_models": self.available_models}
            try:
                if self.triton_client:
                    # Try fetching the metadata for each model to ensure they are queryable
                    meta = []
                    for model_name in self.available_models:
                        try:
                            info = self.triton_client.get_model_metadata(model_name=model_name)
                            meta.append({"name": model_name, "ok": True, "metadata": info})
                        except Exception as e:
                            meta.append({"name": model_name, "ok": False, "error": str(e)})
                    details["model_metadata"] = meta
            except Exception as e:
                details["error"] = str(e)
            return {"status": "healthy" if triton_ok else "degraded", "triton_available": triton_ok, "details": details}
        
        @self.app.get("/models")
        async def list_models():
            """List available models"""
            return {
                "models": self.available_models,
                "triton_url": self.config.triton_url
            }
        
        @self.app.get("/metrics")
        async def get_metrics():
            """Get inference metrics"""
            return {
                "total_inferences": 0,  # TODO: implement counter
                "average_processing_time_ms": 0.0,  # TODO: implement metrics
                "anomaly_detection_rate": 0.0,  # TODO: implement metrics
                "gpu_memory_usage": self._get_gpu_memory_usage()
            }
    
    def _extract_features(self, data: List[Dict[str, Any]], features: Optional[List[str]] = None) -> np.ndarray:
        """Extract features from telemetry data for ML inference"""
        try:
            if features is None:
                # Default features for log anomaly detection
                features = ['message_length', 'log_level', 'has_error', 'has_warning', 'timestamp_hour']
            
            feature_matrix = []
            for record in data:
                features_row = []
                
                # Extract basic features
                message = record.get('body', record.get('message', ''))
                features_row.append(len(str(message)))  # message_length
                
                # Log level encoding
                level = record.get('level', 'INFO').upper()
                level_encoding = {'ERROR': 4, 'WARN': 3, 'INFO': 2, 'DEBUG': 1}.get(level, 2)
                features_row.append(level_encoding)
                
                # Error/warning indicators
                features_row.append(1 if 'error' in str(message).lower() else 0)
                features_row.append(1 if 'warn' in str(message).lower() else 0)
                
                # Time-based features
                timestamp = record.get('timestamp', datetime.utcnow().isoformat())
                try:
                    hour = datetime.fromisoformat(timestamp.replace('Z', '+00:00')).hour
                    features_row.append(hour)
                except:
                    features_row.append(12)  # Default to noon
                
                feature_matrix.append(features_row)
            
            return np.array(feature_matrix, dtype=np.float32)
            
        except Exception as e:
            logger.error(f"Feature extraction failed: {e}")
            return np.array([])
    
    async def _run_inference(self, features: np.ndarray, model_name: str) -> List[Dict[str, Any]]:
        """Run ML inference using Triton"""
        try:
            if self.triton_client is None:
                self.triton_client = tritonhttp.InferenceServerClient(url=self.config.triton_url)
            
            # For now, implement a simple rule-based anomaly detector
            # In production, this would call the actual Triton model
            predictions = []
            
            for i, feature_row in enumerate(features):
                # Simple anomaly detection rules
                is_anomaly = False
                anomaly_score = 0.0
                
                # Rule 1: Very long messages
                if feature_row[0] > 1000:  # message_length
                    is_anomaly = True
                    anomaly_score += 0.3
                
                # Rule 2: High error rate
                if feature_row[2] == 1:  # has_error
                    is_anomaly = True
                    anomaly_score += 0.4
                
                # Rule 3: Unusual time patterns
                if feature_row[4] < 6 or feature_row[4] > 22:  # timestamp_hour
                    anomaly_score += 0.2
                
                # Rule 4: Multiple warning indicators
                if feature_row[3] == 1 and feature_row[2] == 1:  # has_warning and has_error
                    is_anomaly = True
                    anomaly_score += 0.5
                
                predictions.append({
                    'is_anomaly': is_anomaly,
                    'anomaly_score': min(anomaly_score, 1.0),
                    'features': feature_row.tolist(),
                    'model_name': model_name,
                    'timestamp': datetime.utcnow().isoformat()
                })
            
            return predictions
            
        except Exception as e:
            logger.error(f"Triton inference failed: {e}")
            # Fallback to simple rule-based detection
            return self._fallback_inference(features, model_name)
    
    def _fallback_inference(self, features: np.ndarray, model_name: str) -> List[Dict[str, Any]]:
        """Fallback inference when Triton is unavailable"""
        predictions = []
        
        for feature_row in features:
            # Simple fallback rules
            is_anomaly = feature_row[2] == 1 or feature_row[0] > 500  # has_error or long message
            anomaly_score = 0.5 if is_anomaly else 0.0
            
            predictions.append({
                'is_anomaly': is_anomaly,
                'anomaly_score': anomaly_score,
                'features': feature_row.tolist(),
                'model_name': f"{model_name}_fallback",
                'timestamp': datetime.utcnow().isoformat()
            })
        
        return predictions
    
    def _check_triton_availability(self) -> bool:
        """Check if Triton server is available"""
        try:
            if self.triton_client is None:
                self.triton_client = tritonhttp.InferenceServerClient(url=self.config.triton_url)
            
            # Check if server is ready
            is_ready = self.triton_client.is_server_ready()
            if is_ready:
                # Get available models; tritonclient returns a list of entries (dicts or objects)
                repo_index = self.triton_client.get_model_repository_index()
                names = []
                for entry in (repo_index or []):
                    if isinstance(entry, dict):
                        name = entry.get('name')
                    else:
                        name = getattr(entry, 'name', None)
                    if name:
                        names.append(name)
                self.available_models = names
            else:
                self.available_models = []
            
            return is_ready
            
        except Exception as e:
            logger.warning(f"Triton server not available: {e}")
            self.available_models = []
            return False
    
    def _get_gpu_memory_usage(self) -> Dict[str, Any]:
        """Get GPU memory usage information"""
        try:
            # This would typically use nvidia-ml-py or similar
            return {"total": 8192, "used": 0, "free": 8192}  # Placeholder
        except Exception:
            return {"error": "GPU memory info unavailable"}
    
    async def batch_processor(self):
        """Background task to process file batches"""
        logger.info("Starting batch processor")
        
        while True:
            try:
                # Look for batch files in input directory
                input_path = Path(self.config.input_dir)
                batch_files = list(input_path.glob("batch_*.jsonl"))
                
                for batch_file in batch_files:
                    await self._process_batch_file(batch_file)
                
                await asyncio.sleep(self.config.poll_interval)
                
            except Exception as e:
                logger.error(f"Batch processor error: {e}")
                await asyncio.sleep(self.config.poll_interval)
    
    async def _process_batch_file(self, batch_file: Path):
        """Process a single batch file"""
        try:
            logger.info(f"Processing batch file: {batch_file}")
            
            # Read batch data
            data = []
            with open(batch_file, 'r', encoding='utf-8') as f:
                for line in f:
                    try:
                        data.append(json.loads(line.strip()))
                    except json.JSONDecodeError:
                        continue
            
            if len(data) < 10:  # Skip small batches
                logger.debug(f"Batch too small ({len(data)} records), skipping")
                return
            
            # Create inference request
            request = InferenceRequest(
                data=data,
                model_name=self.config.model_name
            )
            
            # Run inference
            response = await self._run_inference_batch(request)
            
            # Send enriched logs back to collector
            await self._send_enriched_logs(data, response.predictions)
            
            # Remove processed batch file
            batch_file.unlink()
            
            logger.info(f"Processed batch with {response.original_count} records, "
                      f"found {response.anomaly_count} anomalies")
            
        except Exception as e:
            logger.error(f"Failed to process batch file {batch_file}: {e}")
    
    async def _run_inference_batch(self, request: InferenceRequest) -> InferenceResponse:
        """Run inference on a batch of data"""
        start_time = time.time()
        
        # Extract features
        features = self._extract_features(request.data, request.features)
        
        # Run inference
        predictions = await self._run_inference(features, request.model_name)
        
        processing_time = (time.time() - start_time) * 1000
        
        return InferenceResponse(
            predictions=predictions,
            original_count=len(request.data),
            processed_count=len(predictions),
            processing_time_ms=processing_time,
            model_name=request.model_name,
            anomaly_count=sum(1 for p in predictions if p.get('is_anomaly', False))
        )
    
    async def _send_enriched_logs(self, original_data: List[Dict[str, Any]], predictions: List[Dict[str, Any]]):
        """Send enriched logs back to collector via OTLP"""
        try:
            enriched_logs = []
            
            for i, (original, prediction) in enumerate(zip(original_data, predictions)):
                enriched_log = original.copy()
                enriched_log['gpu_sidecar'] = 'inference'
                enriched_log['inference_result'] = {
                    'is_anomaly': prediction['is_anomaly'],
                    'anomaly_score': prediction['anomaly_score'],
                    'model_name': prediction['model_name'],
                    'timestamp': prediction['timestamp']
                }
                enriched_logs.append(enriched_log)
            
            # Send to OTLP endpoint
            otlp_payload = {
                "resourceLogs": [{
                    "resource": {
                        "attributes": [{
                            "key": "service.name",
                            "value": {"stringValue": "gpu-inference-sidecar"}
                        }]
                    },
                    "scopeLogs": [{
                        "scope": {
                            "name": "gpu-inference-sidecar",
                            "version": "1.0.0"
                        },
                        "logRecords": [{
                            "timeUnixNano": str(int(time.time() * 1000000000)),
                            "severityText": "INFO",
                            "body": {"stringValue": json.dumps(log)},
                            "attributes": [
                                {"key": "gpu_sidecar", "value": {"stringValue": "inference"}},
                                {"key": "is_anomaly", "value": {"boolValue": log.get('inference_result', {}).get('is_anomaly', False)}}
                            ]
                        } for log in enriched_logs]
                    }]
                }]
            }
            
            response = requests.post(
                self.config.output_endpoint,
                json=otlp_payload,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"Sent {len(enriched_logs)} enriched logs to OTLP")
            else:
                logger.warning(f"Failed to send enriched logs: HTTP {response.status_code}")
                
        except Exception as e:
            logger.error(f"Failed to send enriched logs: {e}")

def main():
    """Main entry point"""
    config = InferenceConfig()
    sidecar = GPUInferenceSidecar(config)
    
    # Start the FastAPI server
    import uvicorn
    uvicorn.run(
        sidecar.app,
        host="0.0.0.0",
        port=8003,
        log_level="info"
    )

if __name__ == "__main__":
    main()
