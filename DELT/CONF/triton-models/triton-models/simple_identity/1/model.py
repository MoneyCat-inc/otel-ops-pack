import numpy as np
import triton_python_backend_utils as pb_utils

class TritonPythonModel:
    def initialize(self, args):
        pass

    def execute(self, requests):
        responses = []
        for request in requests:
            inp = pb_utils.get_input_tensor_by_name(request, "INPUT_0")
            out_tensor = pb_utils.Tensor("OUTPUT_0", inp.as_numpy())
            responses.append(pb_utils.InferenceResponse([out_tensor]))
        return responses
