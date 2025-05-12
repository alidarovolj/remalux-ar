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
            print(f"\nProcessing Unsqueeze node: {node.name}")
            print(f"  Initial attributes: {node.attrs}")
            print(f"  Initial inputs: {[(inp.name, inp.shape, inp.dtype) for inp in node.inputs]}")

            # Opsets 11 and 13 for Unsqueeze expect 'axes' as an attribute.
            # If 'axes' is already an attribute, we assume it's fine unless it causes issues later.
            if 'axes' in node.attrs:
                print(f"  Node '{node.name}' already has 'axes' attribute: {node.attrs['axes']}")
                continue # Assuming it's correctly formatted if it exists

            # If axes are provided as a second input (like in opset 1 style for Unsqueeze)
            elif len(node.inputs) > 1 and isinstance(node.inputs[1], gs.Constant):
                axes_tensor = node.inputs[1]
                # Ensure it's a constant tensor providing the axes
                if axes_tensor.values is not None:
                    axes_values = axes_tensor.values.tolist() # Convert numpy array to list of ints
                    print(f"  Found axes for '{node.name}' in input tensor '{axes_tensor.name}': {axes_values}")
                    
                    # Modify the node:
                    # 1. Add 'axes' attribute
                    node.attrs['axes'] = axes_values
                    print(f"    Set attribute 'axes' to: {node.attrs['axes']}")
                    
                    # 2. Mark the second input (axes tensor) for removal from node's inputs
                    # We cannot modify node.inputs directly while iterating.
                    # Instead, we will clear the original inputs and set the new one(s).
                    data_input_tensor = node.inputs[0]
                    node.inputs.clear()       # Clear all inputs
                    node.inputs.append(data_input_tensor) # Re-add only the data input
                    
                    print(f"    Updated inputs for node '{node.name}': {[(inp.name, inp.shape, inp.dtype) for inp in node.inputs]}")
                    modified_graph = True
                else:
                    print(f"  Warning: Second input Constant for '{node.name}' does not have .values.")
            else:
                print(f"  Warning: Unsqueeze node '{node.name}' does not have 'axes' attribute and second input is not a Constant tensor or has only one input.")
                print(f"    Inputs: {[(inp.name, inp.shape, inp.dtype) for inp in node.inputs]}")
                # This case might indicate a malformed node or an Unsqueeze version we don't expect.

    graph.cleanup().toposort() # Crucial after modifying inputs/outputs or a large number of nodes
    return modified_graph


if __name__ == "__main__":
    print(f"Loading ONNX model from: {input_onnx_path}")
    # Load the ONNX model using onnx library first to ensure it's valid
    onnx_model = onnx.load(input_onnx_path)
    graph = gs.import_onnx(onnx_model)
    print(f"Initial model opset: {graph.opset if graph.opset else 'Not Set (check individual nodes or model proto)'}")

    print("\n--- Modifying Unsqueeze nodes (converting input axes to attribute) ---")
    was_modified = try_modify_unsqueeze_nodes(graph)

    if was_modified:
        print(f"\nGraph was modified. Exporting modified model to: {output_onnx_path}")
        # Export the graph back to an ONNX model
        modified_onnx_model = gs.export_onnx(graph)
        onnx.save(modified_onnx_model, output_onnx_path)
        print(f"Modified model saved to {output_onnx_path}")
        
        # Optional: Verify the modified model
        print("Verifying modified model...")
        check_model = onnx.load(output_onnx_path)
        onnx.checker.check_model(check_model)
        print("Modified model is valid.")
    else:
        print("\nNo modifications were made to Unsqueeze nodes regarding axes input to attribute conversion.")

    print("\nScript finished.") 