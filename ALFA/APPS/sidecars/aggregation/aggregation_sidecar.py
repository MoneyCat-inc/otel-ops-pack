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

try:
    import cudf
    HAS_CUDF = True
except ImportError:
    cudf = None
    HAS_CUDF = False
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
    output_endpoint: str = "http://localhost:4318/v1/metrics"
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
        self.use_cudf = HAS_CUDF
        if not self.use_cudf:
            logger.warning("cuDF not available; falling back to pandas for aggregation")
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
                
                # Convert to DataFrame using available backend
                df = self._to_dataframe(request.data)
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
    
    def _to_dataframe(self, records: List[Dict[str, Any]]):
        """Return a DataFrame using cuDF when available, otherwise pandas"""
        if self.use_cudf and cudf is not None:
            return cudf.DataFrame(records)
        return pd.DataFrame(records)

    def _ensure_pandas(self, frame):
        """Convert a DataFrame-like object to pandas"""
        if hasattr(frame, 'to_pandas'):
            return frame.to_pandas()
        if isinstance(frame, pd.DataFrame):
            return frame
        return pd.DataFrame(frame)


    def _aggregate_summary(self, df, group_by: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Perform summary aggregation (count, sum, mean, min, max)"""
        try:
            if self.use_cudf and cudf is not None and isinstance(df, cudf.DataFrame):
                numeric_cols = df.select_dtypes(include=['int64', 'float64']).columns
                if group_by and all(col in df.columns for col in group_by):
                    grouped = df.groupby(group_by)
                    result = grouped.agg({
                        col: ['count', 'sum', 'mean', 'min', 'max']
                        for col in numeric_cols
                    }).reset_index()
                    result.columns = ['_'.join(col).strip('_') if isinstance(col, tuple) else col for col in result.columns]
                    return result.to_pandas().to_dict('records')
                else:
                    if len(numeric_cols) == 0:
                        return []
                    result = df[numeric_cols].agg(['count', 'sum', 'mean', 'min', 'max'])
                    result = result.transpose().reset_index()
                    result.columns = ['column', 'count', 'sum', 'mean', 'min', 'max']
                    return result.to_pandas().to_dict('records')
            else:
                df_pd = self._ensure_pandas(df)
                numeric_cols = df_pd.select_dtypes(include='number').columns
                if len(numeric_cols) == 0:
                    return []
                if group_by and all(col in df_pd.columns for col in group_by):
                    grouped = df_pd.groupby(group_by)
                    agg_map = {col: ['count', 'sum', 'mean', 'min', 'max'] for col in numeric_cols}
                    result = grouped.agg(agg_map).reset_index()
                    result.columns = ['_'.join(col).strip('_') if isinstance(col, tuple) else col for col in result.columns]
                    return result.to_dict('records')
                else:
                    result_rows = []
                    for col in numeric_cols:
                        stats = df_pd[col].agg(['count', 'sum', 'mean', 'min', 'max']).to_dict()
                        stats['column'] = col
                        result_rows.append(stats)
                    return result_rows
        except Exception as e:
            logger.error(f"Summary aggregation failed: {e}")
            return []


    def _aggregate_histogram(self, df, group_by: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Perform histogram aggregation"""
        try:
            df_pd = self._ensure_pandas(df)
            numeric_cols = df_pd.select_dtypes(include='number').columns
            histograms = []
            for col in numeric_cols:
                if group_by and all(gb_col in df_pd.columns for gb_col in group_by):
                    for group_values, group_df in df_pd.groupby(group_by):
                        series = group_df[col].dropna()
                        if series.empty:
                            continue
                        hist, bins = np.histogram(series.to_numpy(), bins=10)
                        histograms.append({
                            'column': col,
                            'group': dict(zip(group_by, group_values)) if isinstance(group_values, tuple) else {group_by[0]: group_values},
                            'histogram': hist.tolist(),
                            'bins': bins.tolist()
                        })
                else:
                    series = df_pd[col].dropna()
                    if series.empty:
                        continue
                    hist, bins = np.histogram(series.to_numpy(), bins=10)
                    histograms.append({
                        'column': col,
                        'histogram': hist.tolist(),
                        'bins': bins.tolist()
                    })
            return histograms
        except Exception as e:
            logger.error(f"Histogram aggregation failed: {e}")
            return []


    def _aggregate_percentiles(self, df, group_by: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Perform percentile aggregation (p50, p90, p95, p99)"""
        try:
            df_pd = self._ensure_pandas(df)
            numeric_cols = df_pd.select_dtypes(include='number').columns
            if len(numeric_cols) == 0:
                return []
            percentiles = [50, 90, 95, 99]
            results = []
            if group_by and all(col in df_pd.columns for col in group_by):
                for group_values, group_df in df_pd.groupby(group_by):
                    group_result = {
                        'group': dict(zip(group_by, group_values)) if isinstance(group_values, tuple) else {group_by[0]: group_values}
                    }
                    for col in numeric_cols:
                        series = group_df[col].dropna()
                        if series.empty:
                            continue
                        col_percentiles = {f'p{p}': float(series.quantile(p/100.0)) for p in percentiles}
                        group_result[col] = col_percentiles
                    results.append(group_result)
            else:
                result = {}
                for col in numeric_cols:
                    series = df_pd[col].dropna()
                    if series.empty:
                        continue
                    result[col] = {f'p{p}': float(series.quantile(p/100.0)) for p in percentiles}
                if result:
                    results.append(result)
            return results
        except Exception as e:
            logger.error(f"Percentile aggregation failed: {e}")
            return []

    def _check_gpu_availability(self) -> bool:
        """Check if GPU is available for aggregation"""
        if not self.use_cudf or cudf is None:
            return False
        try:
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
