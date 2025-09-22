#!/usr/bin/env python3
"""
GPU Aggregation Sidecar for OpenTelemetry Workloads
Processes telemetry batches using RAPIDS cuDF for high-throughput data aggregation
"""

import os
import json
import time
import asyncio
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta

import cudf
import pandas as pd
import numpy as np
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
class AggregationConfig:
    """Configuration for GPU aggregation sidecar"""
    input_dir: str = "/app/gpu-buffers/analytics"
    output_endpoint: str = "http://localhost:14318/v1/metrics"
    batch_size: int = 10000  # records
    batch_timeout: float = 30.0  # seconds
    poll_interval: float = 2.0  # seconds
    aggregation_window: int = 60  # seconds

class AggregationRequest(BaseModel):
    """Request model for aggregation API"""
    data: List[Dict[str, Any]]
    aggregation_type: str = "summary"  # summary, histogram, percentiles
    group_by: Optional[List[str]] = None
    time_window: Optional[int] = None

class AggregationResponse(BaseModel):
    """Response model for aggregation API"""
    aggregated_data: List[Dict[str, Any]]
    original_count: int
    aggregated_count: int
    processing_time_ms: float
    aggregation_type: str

class GPUAggregationSidecar:
    """Main aggregation sidecar service"""
    
    def __init__(self, config: AggregationConfig):
        self.config = config
        self.app = FastAPI(title="GPU Aggregation Sidecar", version="1.0.0")
        self.setup_routes()
        self.setup_directories()
        self.metrics_buffer = []
        
    def setup_directories(self):
        """Create necessary directories"""
        Path(self.config.input_dir).mkdir(parents=True, exist_ok=True)
        
    def setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.post("/aggregate", response_model=AggregationResponse)
        async def aggregate_data(request: AggregationRequest):
            """Aggregate a batch of telemetry data"""
            try:
                start_time = time.time()
                
                if not request.data:
                    return AggregationResponse(
                        aggregated_data=[],
                        original_count=0,
                        aggregated_count=0,
                        processing_time_ms=0.0,
                        aggregation_type=request.aggregation_type
                    )
                
                # Convert to cuDF DataFrame
                df = cudf.DataFrame(request.data)
                original_count = len(df)
                
                # Perform aggregation based on type
                if request.aggregation_type == "summary":
                    aggregated_data = self._aggregate_summary(df, request.group_by)
                elif request.aggregation_type == "histogram":
                    aggregated_data = self._aggregate_histogram(df, request.group_by)
                elif request.aggregation_type == "percentiles":
                    aggregated_data = self._aggregate_percentiles(df, request.group_by)
                else:
                    raise ValueError(f"Unsupported aggregation type: {request.aggregation_type}")
                
                aggregated_count = len(aggregated_data)
                processing_time = (time.time() - start_time) * 1000
                
                logger.info(f"Aggregated {original_count} records to {aggregated_count} "
                          f"({request.aggregation_type}) in {processing_time:.2f}ms")
                
                return AggregationResponse(
                    aggregated_data=aggregated_data,
                    original_count=original_count,
                    aggregated_count=aggregated_count,
                    processing_time_ms=processing_time,
                    aggregation_type=request.aggregation_type
                )
                
            except Exception as e:
                logger.error(f"Aggregation failed: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            return {
                "status": "healthy", 
                "gpu_available": self._check_gpu_availability(),
                "buffer_size": len(self.metrics_buffer)
            }
        
        @self.app.get("/metrics")
        async def get_metrics():
            """Get aggregation metrics"""
            return {
                "total_aggregations": 0,  # TODO: implement counter
                "average_processing_time_ms": 0.0,  # TODO: implement metrics
                "gpu_memory_usage": self._get_gpu_memory_usage(),
                "buffer_size": len(self.metrics_buffer)
            }
    
    def _aggregate_summary(self, df: cudf.DataFrame, group_by: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Perform summary aggregation (count, sum, mean, min, max)"""
        try:
            if group_by and all(col in df.columns for col in group_by):
                # Group by specified columns
                grouped = df.groupby(group_by)
                result = grouped.agg({
                    col: ['count', 'sum', 'mean', 'min', 'max'] 
                    for col in df.select_dtypes(include=['int64', 'float64']).columns
                }).reset_index()
                
                # Flatten multi-level column names
                result.columns = ['_'.join(col).strip() if isinstance(col, tuple) else col for col in result.columns]
            else:
                # Global aggregation
                numeric_cols = df.select_dtypes(include=['int64', 'float64']).columns
                result = df[numeric_cols].agg(['count', 'sum', 'mean', 'min', 'max'])
                
                # Flatten multi-level column names
                result.columns = ['_'.join(col).strip() if isinstance(col, tuple) else col for col in result.columns]
                result = result.reset_index()
            
            # Convert to list of dictionaries
            return result.to_pandas().to_dict('records')
            
        except Exception as e:
            logger.error(f"Summary aggregation failed: {e}")
            return []
    
    def _aggregate_histogram(self, df: cudf.DataFrame, group_by: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Perform histogram aggregation"""
        try:
            # For now, create simple histograms for numeric columns
            numeric_cols = df.select_dtypes(include=['int64', 'float64']).columns
            histograms = []
            
            for col in numeric_cols:
                if group_by and all(gb_col in df.columns for gb_col in group_by):
                    # Grouped histograms
                    for group_values, group_df in df.groupby(group_by):
                        hist, bins = np.histogram(group_df[col].to_pandas(), bins=10)
                        histograms.append({
                            "column": col,
                            "group": dict(zip(group_by, group_values)) if isinstance(group_values, tuple) else {group_by[0]: group_values},
                            "histogram": hist.tolist(),
                            "bins": bins.tolist()
                        })
                else:
                    # Global histogram
                    hist, bins = np.histogram(df[col].to_pandas(), bins=10)
                    histograms.append({
                        "column": col,
                        "histogram": hist.tolist(),
                        "bins": bins.tolist()
                    })
            
            return histograms
            
        except Exception as e:
            logger.error(f"Histogram aggregation failed: {e}")
            return []
    
    def _aggregate_percentiles(self, df: cudf.DataFrame, group_by: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Perform percentile aggregation (p50, p90, p95, p99)"""
        try:
            numeric_cols = df.select_dtypes(include=['int64', 'float64']).columns
            percentiles = [50, 90, 95, 99]
            results = []
            
            if group_by and all(col in df.columns for col in group_by):
                # Grouped percentiles
                for group_values, group_df in df.groupby(group_by):
                    group_result = {
                        "group": dict(zip(group_by, group_values)) if isinstance(group_values, tuple) else {group_by[0]: group_values}
                    }
                    
                    for col in numeric_cols:
                        col_percentiles = {}
                        for p in percentiles:
                            col_percentiles[f"p{p}"] = group_df[col].quantile(p/100.0)
                        group_result[col] = col_percentiles
                    
                    results.append(group_result)
            else:
                # Global percentiles
                result = {}
                for col in numeric_cols:
                    col_percentiles = {}
                    for p in percentiles:
                        col_percentiles[f"p{p}"] = df[col].quantile(p/100.0)
                    result[col] = col_percentiles
                results.append(result)
            
            return results
            
        except Exception as e:
            logger.error(f"Percentile aggregation failed: {e}")
            return []
    
    def _check_gpu_availability(self) -> bool:
        """Check if GPU is available for aggregation"""
        try:
            # Test cuDF functionality
            test_df = cudf.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})
            test_df.groupby('a').sum()
            return True
        except Exception:
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
                
                # Process metrics buffer
                if self.metrics_buffer:
                    await self._flush_metrics_buffer()
                
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
            
            if len(data) < 100:  # Skip small batches
                logger.debug(f"Batch too small ({len(data)} records), skipping")
                return
            
            # Create aggregation request
            request = AggregationRequest(
                data=data,
                aggregation_type="summary",
                group_by=["service.name"] if any("service.name" in record for record in data) else None
            )
            
            # Aggregate the data
            response = await self._aggregate_batch(request)
            
            # Add to metrics buffer for OTLP export
            self.metrics_buffer.extend(response.aggregated_data)
            
            # Remove processed batch file
            batch_file.unlink()
            
            logger.info(f"Aggregated batch with {response.original_count} records")
            
        except Exception as e:
            logger.error(f"Failed to process batch file {batch_file}: {e}")
    
    async def _aggregate_batch(self, request: AggregationRequest) -> AggregationResponse:
        """Aggregate a batch of data"""
        start_time = time.time()
        
        # Convert to cuDF DataFrame
        df = cudf.DataFrame(request.data)
        original_count = len(df)
        
        # Perform aggregation
        if request.aggregation_type == "summary":
            aggregated_data = self._aggregate_summary(df, request.group_by)
        elif request.aggregation_type == "histogram":
            aggregated_data = self._aggregate_histogram(df, request.group_by)
        elif request.aggregation_type == "percentiles":
            aggregated_data = self._aggregate_percentiles(df, request.group_by)
        else:
            aggregated_data = []
        
        processing_time = (time.time() - start_time) * 1000
        
        return AggregationResponse(
            aggregated_data=aggregated_data,
            original_count=original_count,
            aggregated_count=len(aggregated_data),
            processing_time_ms=processing_time,
            aggregation_type=request.aggregation_type
        )
    
    async def _flush_metrics_buffer(self):
        """Flush metrics buffer to OTLP endpoint"""
        if not self.metrics_buffer:
            return
        
        try:
            # Convert to OTLP metrics format
            otlp_metrics = self._convert_to_otlp_metrics(self.metrics_buffer)
            
            # Send to OTLP endpoint
            response = requests.post(
                self.config.output_endpoint,
                json=otlp_metrics,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"Flushed {len(self.metrics_buffer)} metrics to OTLP")
                self.metrics_buffer.clear()
            else:
                logger.warning(f"Failed to flush metrics: HTTP {response.status_code}")
                
        except Exception as e:
            logger.error(f"Failed to flush metrics buffer: {e}")
    
    def _convert_to_otlp_metrics(self, metrics_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Convert aggregated data to OTLP metrics format"""
        # Simple OTLP metrics conversion
        return {
            "resourceMetrics": [{
                "resource": {
                    "attributes": [{
                        "key": "service.name",
                        "value": {"stringValue": "gpu-aggregation-sidecar"}
                    }]
                },
                "scopeMetrics": [{
                    "scope": {
                        "name": "gpu-aggregation-sidecar",
                        "version": "1.0.0"
                    },
                    "metrics": [{
                        "name": "gpu.aggregation.records_processed",
                        "description": "Number of records processed by GPU aggregation",
                        "unit": "1",
                        "sum": {
                            "dataPoints": [{
                                "timeUnixNano": str(int(time.time() * 1000000000)),
                                "asInt": len(metrics_data)
                            }],
                            "aggregationTemporality": "AGGREGATION_TEMPORALITY_CUMULATIVE"
                        }
                    }]
                }]
            }]
        }

def main():
    """Main entry point"""
    config = AggregationConfig()
    sidecar = GPUAggregationSidecar(config)
    
    # Start the FastAPI server
    import uvicorn
    uvicorn.run(
        sidecar.app,
        host="0.0.0.0",
        port=8002,
        log_level="info"
    )

if __name__ == "__main__":
    main()
