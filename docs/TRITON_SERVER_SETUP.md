# Triton Inference Server Setup Guide

## Overview
This guide helps you set up NVIDIA Triton Inference Server for advanced ML models in the GPU sidecar infrastructure.

## Prerequisites
- NVIDIA GPU with CUDA support
- Docker with NVIDIA runtime
- Triton Inference Server container

## Quick Start

### 1. Pull Triton Server Image
```bash
docker pull nvcr.io/nvidia/tritonserver:23.10-py3
```

### 2. Create Model Repository
```bash
mkdir -p triton-models/log_anomaly_detector/1
```

### 3. Add Model Files
Place your model files in the repository:
- `model.py` - Python model implementation
- `config.pbtxt` - Model configuration
- Model weights and artifacts

### 4. Start Triton Server
```bash
docker run --rm --gpus all -p 8000:8000 -p 8001:8001 -p 8002:8002 -v $(pwd)/triton-models:/models nvcr.io/nvidia/tritonserver:23.10-py3 tritonserver --model-repository=/models
```

### 5. Update Inference Sidecar
Update `sidecars/inference/inference_sidecar.py` to use Triton server:
- Set `TRITON_URL = "http://localhost:8000"`
- Update model names and configurations
- Test with real models

## Model Configuration Example

### config.pbtxt
```protobuf
name: "log_anomaly_detector"
platform: "pytorch_libtorch"
max_batch_size: 32
input [
  {
    name: "log_features"
    data_type: TYPE_FP32
    dims: [128]
  }
]
output [
  {
    name: "anomaly_score"
    data_type: TYPE_FP32
    dims: [1]
  }
]
```

### Python Model (model.py)
```python
import torch
import triton_python_backend_utils as pb_utils

class TritonPythonModel:
    def initialize(self, args):
        self.model = torch.load("model.pth")
        self.model.eval()
    
    def execute(self, requests):
        responses = []
        for request in requests:
            input_tensor = pb_utils.get_input_tensor_by_name(request, "log_features")
            with torch.no_grad():
                output = self.model(input_tensor.as_numpy())
            output_tensor = pb_utils.Tensor("anomaly_score", output.numpy())
            responses.append(pb_utils.InferenceResponse([output_tensor]))
        return responses
```

## Testing
1. Start Triton server
2. Update inference sidecar configuration
3. Run validation: `pwsh -File scripts/validate-production-gpu.ps1`
4. Check logs for Triton connectivity

## Troubleshooting
- Check Triton server logs: `docker logs <container_id>`
- Verify model repository structure
- Test model loading: `curl http://localhost:8000/v2/models/log_anomaly_detector`
- Check GPU memory usage: `nvidia-smi`
