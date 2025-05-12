import onnx
import sys

def convert_model_ir(input_path, output_path, target_ir_version=9):
    """
    Loads an ONNX model, changes its IR version, and saves it.
    Note: This changes the model.ir_version field. It does not automatically
    convert operators to be compatible with the target_ir_version if they
    are from a newer opset that requires a higher IR version.
    If the model contains operators from an opset that requires ir_version > target_ir_version,
    this might lead to an invalid model or runtime errors.
    A more robust solution would involve converting opsets if necessary, which is more complex.
    """
    try:
        # Load the ONNX model
        model = onnx.load(input_path)
        print(f"Original model IR version: {model.ir_version}")

        # Change the IR version
        # Check current opset version. If it's too high for IR version 9, this might be an issue.
        # For example, opset 15 requires IR version 7. Opset 9 requires IR version 4.
        # ONNX IR v3 -> opset 8
        # ONNX IR v4 -> opset 9
        # ONNX IR v5 -> opset 10
        # ONNX IR v6 -> opset 11
        # ONNX IR v7 -> opset 12-15
        # IR version 9 is not a standard mapping. The error says "max supported IR version: 9".
        # The highest standard IR version is 8 (for ONNX 1.13+).
        # Let's try setting it to 9 as the error suggests.

        original_ir_version = model.ir_version
        model.ir_version = target_ir_version
        print(f"Attempting to set model IR version to: {target_ir_version}")

        # Optional: You might want to also adjust opset imports if they are too high
        # for the target IR version, but this is more involved.
        # For now, we only change the IR version field as per the error message.
        # Example:
        # for opset_import in model.opset_import:
        #     if opset_import.version > 14: # Example: downgrade opset if it's > 14 for IR v7
        #         print(f"Warning: Model uses opset {opset_import.domain} version {opset_import.version}, which might be too high for IR version {target_ir_version}")
        #         # opset_import.version = 14 # Be careful with this, can break the model

        # Save the modified model
        onnx.save(model, output_path)
        print(f"Model saved to {output_path} with IR version set to {target_ir_version}")

        # Verify the new model (optional, but good practice)
        reloaded_model = onnx.load(output_path)
        print(f"Reloaded model IR version: {reloaded_model.ir_version}")
        onnx.checker.check_model(reloaded_model)
        print("Reloaded model is valid.")

    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    input_model_path = "assets/ml/model.onnx"
    output_model_path = "assets/ml/model_ir_converted.onnx"
    # The error stated "max supported IR version: 9"
    # Standard IR versions are typically lower (e.g., 3 through 8).
    # If setting to 9 doesn't work because it's not a "producer" standard,
    # we might need to try the highest known valid one like 8 or 7.
    # Let's try 9 first, directly addressing the error message.
    target_ir = 9
    convert_model_ir(input_model_path, output_model_path, target_ir_version=target_ir)
    print(f"--- Conversion script finished. Check {output_model_path} ---") 