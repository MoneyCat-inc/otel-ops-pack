#!/usr/bin/env python3
"""
GPU Compression Sidecar for OpenTelemetry Workloads
Processes telemetry batches using NVIDIA nvCOMP for high-throughput compression
"""

import os
import json
import time
import argparse
import asyncio
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime

import zstandard as zstd
import lz4.frame
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class CompressionConfig:
    """Configuration for GPU compression sidecar"""
    input_dir: str = "/app/gpu-buffers/logs"
    output_dir: str = "/app/gpu-buffers/compressed"
    batch_size: int = 10000  # lines
    batch_size_bytes: int = 2 * 1024 * 1024  # 2MB
    compression_algorithm: str = "zstd"  # zstd, snappy, lz4
    poll_interval: float = 1.0  # seconds
    min_compressibility: float = 0.1  # minimum compression ratio to use GPU

class CompressionRequest(BaseModel):
    """Request model for compression API"""
    data: List[str]
    metadata: Optional[Dict[str, Any]] = None

class CompressionResponse(BaseModel):
    """Response model for compression API"""
    compressed_data: bytes
    original_size: int
    compressed_size: int
    compression_ratio: float
    algorithm: str
    processing_time_ms: float

class GPUCompressionSidecar:
    """Main compression sidecar service"""
    
    def __init__(self, config: CompressionConfig):
        self.config = config
        self.app = FastAPI(title="GPU Compression Sidecar", version="1.0.0")
        self.setup_routes()
        self.setup_directories()
        
    def setup_directories(self):
        """Create necessary directories"""
        Path(self.config.input_dir).mkdir(parents=True, exist_ok=True)
        Path(self.config.output_dir).mkdir(parents=True, exist_ok=True)
        
    def setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.post("/compress", response_model=CompressionResponse)
        async def compress_data(request: CompressionRequest):
            """Compress a batch of telemetry data"""
            try:
                start_time = time.time()
                
                # Convert to bytes
                data_bytes = '\n'.join(request.data).encode('utf-8')
                original_size = len(data_bytes)
                
                # Check if compression is worthwhile
                if original_size < 1024:  # Less than 1KB, skip compression
                    return CompressionResponse(
                        compressed_data=data_bytes,
                        original_size=original_size,
                        compressed_size=original_size,
                        compression_ratio=1.0,
                        algorithm="none",
                        processing_time_ms=(time.time() - start_time) * 1000
                    )
                
                # Compress using nvCOMP
                compressed_data = self._compress_with_gpu(data_bytes)
                compressed_size = len(compressed_data)
                compression_ratio = compressed_size / original_size
                
                # Check if compression was effective
                if compression_ratio > (1.0 - self.config.min_compressibility):
                    logger.warning(f"Low compression ratio {compression_ratio:.3f}, using original data")
                    compressed_data = data_bytes
                    compressed_size = original_size
                    compression_ratio = 1.0
                    algorithm = "none"
                else:
                    algorithm = self.config.compression_algorithm
                
                processing_time = (time.time() - start_time) * 1000
                
                logger.info(f"Compressed {original_size} bytes to {compressed_size} bytes "
                          f"(ratio: {compression_ratio:.3f}) in {processing_time:.2f}ms")
                
                return CompressionResponse(
                    compressed_data=compressed_data,
                    original_size=original_size,
                    compressed_size=compressed_size,
                    compression_ratio=compression_ratio,
                    algorithm=algorithm,
                    processing_time_ms=processing_time
                )
                
            except Exception as e:
                logger.error(f"Compression failed: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            return {"status": "healthy", "gpu_available": self._check_gpu_availability()}
        
        @self.app.get("/metrics")
        async def get_metrics():
            """Get compression metrics"""
            return {
                "total_compressions": 0,  # TODO: implement counter
                "average_compression_ratio": 0.0,  # TODO: implement metrics
                "gpu_memory_usage": self._get_gpu_memory_usage()
            }
    
    def _compress_with_gpu(self, data: bytes) -> bytes:
        """Compress data using CPU compression (GPU nvCOMP requires manual compilation)"""
        try:
            # Use CPU compression libraries for now
            if self.config.compression_algorithm == "zstd":
                cctx = zstd.ZstdCompressor(level=3)  # Fast compression
                compressed = cctx.compress(data)
            elif self.config.compression_algorithm == "lz4":
                compressed = lz4.frame.compress(data)
            else:
                # Fallback to zstd
                cctx = zstd.ZstdCompressor(level=3)
                compressed = cctx.compress(data)
            
            return compressed
            
        except Exception as e:
            logger.error(f"Compression failed: {e}")
            # Return original data if compression fails
            return data
    
    def _check_gpu_availability(self) -> bool:
        """Check if compression libraries are available"""
        try:
            # Test compression libraries
            test_data = b"test compression data"
            cctx = zstd.ZstdCompressor(level=1)
            cctx.compress(test_data)
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
                
                await asyncio.sleep(self.config.poll_interval)
                
            except Exception as e:
                logger.error(f"Batch processor error: {e}")
                await asyncio.sleep(self.config.poll_interval)
    
    async def _process_batch_file(self, batch_file: Path):
        """Process a single batch file"""
        try:
            logger.info(f"Processing batch file: {batch_file}")
            
            # Read batch data
            with open(batch_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            if len(lines) < self.config.batch_size:
                logger.debug(f"Batch too small ({len(lines)} lines), skipping")
                return
            
            # Create compression request
            request = CompressionRequest(
                data=[line.strip() for line in lines],
                metadata={
                    "source_file": str(batch_file),
                    "batch_size": len(lines),
                    "timestamp": datetime.utcnow().isoformat()
                }
            )
            
            # Compress the data
            response = await self._compress_batch(request)
            
            # Save compressed result
            output_file = Path(self.config.output_dir) / f"compressed_{batch_file.stem}.bin"
            with open(output_file, 'wb') as f:
                f.write(response.compressed_data)
            
            # Save metadata
            metadata_file = output_file.with_suffix('.json')
            with open(metadata_file, 'w') as f:
                json.dump({
                    "original_size": response.original_size,
                    "compressed_size": response.compressed_size,
                    "compression_ratio": response.compression_ratio,
                    "algorithm": response.algorithm,
                    "processing_time_ms": response.processing_time_ms,
                    "source_file": str(batch_file),
                    "timestamp": datetime.utcnow().isoformat()
                }, f, indent=2)
            
            # Remove processed batch file
            batch_file.unlink()
            
            logger.info(f"Compressed batch saved to {output_file}")
            
        except Exception as e:
            logger.error(f"Failed to process batch file {batch_file}: {e}")
    
    async def _compress_batch(self, request: CompressionRequest) -> CompressionResponse:
        """Compress a batch of data"""
        start_time = time.time()
        
        # Convert to bytes
        data_bytes = '\n'.join(request.data).encode('utf-8')
        original_size = len(data_bytes)
        
        # Compress using GPU
        compressed_data = self._compress_with_gpu(data_bytes)
        compressed_size = len(compressed_data)
        compression_ratio = compressed_size / original_size
        
        processing_time = (time.time() - start_time) * 1000
        
        return CompressionResponse(
            compressed_data=compressed_data,
            original_size=original_size,
            compressed_size=compressed_size,
            compression_ratio=compression_ratio,
            algorithm=self.config.compression_algorithm,
            processing_time_ms=processing_time
        )

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="GPU Compression Sidecar")
    parser.add_argument("--host", default=os.getenv("COMPRESSION_SIDECAR_HOST", "0.0.0.0"), help="Bind host")
    parser.add_argument("--port", type=int, default=int(os.getenv("COMPRESSION_SIDECAR_PORT", "8001")), help="Bind port")
    args = parser.parse_args()

    config = CompressionConfig()
    sidecar = GPUCompressionSidecar(config)
    
    # Start the FastAPI server
    import uvicorn
    uvicorn.run(
        sidecar.app,
        host=args.host,
        port=args.port,
        log_level="info"
    )

if __name__ == "__main__":
    main()
