#!/usr/bin/env python3
"""
Create a minimal ONNX model for testing GPU inference harness
"""

import numpy as np
import onnx
from onnx import helper, TensorProto

def create_simple_model():
    """Create a simple ONNX model that adds 1 to input"""
    
    # Create input tensor
    input_tensor = helper.make_tensor_value_info(
        'input', TensorProto.FLOAT, [4]
    )
    
    # Create output tensor
    output_tensor = helper.make_tensor_value_info(
        'output', TensorProto.FLOAT, [4]
    )
    
    # Create a simple add node (add 1 to each element)
    one_tensor = helper.make_tensor('one', TensorProto.FLOAT, [1], [1.0])
    
    add_node = helper.make_node(
        'Add',
        inputs=['input', 'one'],
        outputs=['output'],
        name='add_one'
    )
    
    # Create the graph
    graph = helper.make_graph(
        [add_node],
        'simple_add_model',
        [input_tensor],
        [output_tensor],
        [one_tensor]
    )
    
    # Create the model
    model = helper.make_model(graph)
    model.opset_import[0].version = 11
    model.ir_version = 7  # Use older IR version for compatibility
    
    # Verify and save
    onnx.checker.check_model(model)
    return model

if __name__ == "__main__":
    model = create_simple_model()
    onnx.save(model, "models/demo.onnx")
    print("Created models/demo.onnx")
