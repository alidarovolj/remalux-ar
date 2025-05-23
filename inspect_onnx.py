import onnx
import os

model_path = "assets/ml/model.onnx"

def inspect_model(path):
    if not os.path.exists(path):
        print(f"Error: Model file not found at {path}")
        return

    try:
        # Load the ONNX model
        model = onnx.load(path)
        print(f"Successfully loaded ONNX model from: {path}")

        # Get the input tensor information
        print("\nInputs:")
        for input_tensor in model.graph.input:
            name = input_tensor.name
            # Get shape and type
            tensor_type = input_tensor.type.tensor_type
            shape = [d.dim_value if d.dim_value > 0 else d.dim_param if d.dim_param else '?' for d in tensor_type.shape.dim]
            elem_type = onnx.TensorProto.DataType.Name(tensor_type.elem_type)
            print(f"  Name: {name}, Shape: {shape}, Type: {elem_type}")

        # Get the output tensor information
        print("\nOutputs:")
        for output_tensor in model.graph.output:
            name = output_tensor.name
            # Get shape and type
            tensor_type = output_tensor.type.tensor_type
            shape = [d.dim_value if d.dim_value > 0 else d.dim_param if d.dim_param else '?' for d in tensor_type.shape.dim]
            elem_type = onnx.TensorProto.DataType.Name(tensor_type.elem_type)
            print(f"  Name: {name}, Shape: {shape}, Type: {elem_type}")

    except Exception as e:
        print(f"Error inspecting ONNX model: {e}")

if __name__ == "__main__":
    inspect_model(model_path) 