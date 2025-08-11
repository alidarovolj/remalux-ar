import onnx
import onnx_graphsurgeon as gs
import numpy as np

input_onnx_path = "assets/ml/model.onnx"
output_onnx_path = "assets/ml/model_modified.onnx"

def try_modify_unsqueeze_nodes(graph: gs.Graph) -> bool:
    modified_graph = False
    nodes_to_remove_inputs_for = [] # Store (node, input_tensor_to_remove)

    for i, node in enumerate(graph.nodes):
        if node.op == "Unsqueeze":
            # Opsets 11 and 13 for Unsqueeze expect 'axes' as an attribute.
            # If 'axes' is already an attribute, we assume it's fine unless it causes issues later.
            if 'axes' in node.attrs:
                continue # Assuming it's correctly formatted if it exists

            # If axes are provided as a second input (like in opset 1 style for Unsqueeze)
            elif len(node.inputs) > 1 and isinstance(node.inputs[1], gs.Constant):
                axes_tensor = node.inputs[1]
                # Ensure it's a constant tensor providing the axes
                if axes_tensor.values is not None:
                    axes_values = axes_tensor.values.tolist() # Convert numpy array to list of ints
                    
                    # Modify the node:
                    # 1. Add 'axes' attribute
                    node.attrs['axes'] = axes_values
                    
                    # 2. Mark the second input (axes tensor) for removal from node's inputs
                    # We cannot modify node.inputs directly while iterating.
                    # Instead, we will clear the original inputs and set the new one(s).
                    data_input_tensor = node.inputs[0]
                    node.inputs.clear()       # Clear all inputs
                    node.inputs.append(data_input_tensor) # Re-add only the data input
                    
                    modified_graph = True
                else:
                    pass
            else:
                pass

    graph.cleanup().toposort() # Crucial after modifying inputs/outputs or a large number of nodes
    return modified_graph


if __name__ == "__main__":
    # Load the ONNX model using onnx library first to ensure it's valid
    onnx_model = onnx.load(input_onnx_path)
    graph = gs.import_onnx(onnx_model)

    was_modified = try_modify_unsqueeze_nodes(graph)

    if was_modified:
        # Export the graph back to an ONNX model
        modified_onnx_model = gs.export_onnx(graph)
        onnx.save(modified_onnx_model, output_onnx_path)
        
        # Optional: Verify the modified model
        check_model = onnx.load(output_onnx_path)
        onnx.checker.check_model(check_model)
    else:
        pass