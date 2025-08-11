import onnx
from onnx import version_converter
from onnx_tf.backend import prepare
import tensorflow as tf
import os
import traceback

onnx_model_path = "assets/ml/model_modified.onnx" # MODIFIED INPUT
tf_model_dir = "assets/ml/tf_saved_model_modified"  # MODIFIED OUTPUT DIR
tflite_model_path = "assets/ml/segformer_modified.tflite" # MODIFIED TFLITE OUTPUT

# Target ONNX opset for conversion (e.g., 11 or 12, if original is higher)
# Let's try 11, as onnx-tf has good support for it.
TARGET_OPSET = 11

def convert_onnx_to_tflite():

    if not os.path.exists(onnx_model_path):
        return

    try:
        # 1. Load ONNX model
        original_onnx_model = onnx.load(onnx_model_path)
        
        current_opset_version = None
        for imp in original_onnx_model.opset_import:
            if imp.domain == "" or imp.domain == "ai.onnx": # Standard ONNX opset
                current_opset_version = imp.version
                break

        onnx_model_to_convert = original_onnx_model

        if current_opset_version and current_opset_version > TARGET_OPSET:
            try:
                converted_model = version_converter.convert_version(original_onnx_model, TARGET_OPSET)
                onnx.checker.check_model(converted_model)
                onnx_model_to_convert = converted_model
            except Exception as e:
                print(f"Failed to convert ONNX model opset to {TARGET_OPSET}. Error: {e}")


        # 2. Prepare TensorFlow backend (convert ONNX to TensorFlow representation)
        tf_rep = prepare(onnx_model_to_convert, device="CPU")

        # 3. Export TensorFlow representation to SavedModel format
        if not os.path.exists(tf_model_dir):
            os.makedirs(tf_model_dir)
        tf_rep.export_graph(tf_model_dir)

        # 4. Convert SavedModel to TFLite format
        converter = tf.lite.TFLiteConverter.from_saved_model(tf_model_dir)
        
        # Optional: Apply optimizations (e.g., quantization)
        # converter.optimizations = [tf.lite.Optimize.DEFAULT]
        # converter.target_spec.supported_ops = [
        #     tf.lite.OpsSet.TFLITE_BUILTINS,
        #     tf.lite.OpsSet.SELECT_TF_OPS # Enable TensorFlow ops if needed
        # ]

        tflite_model = converter.convert()

        # 5. Save TFLite model
        with open(tflite_model_path, 'wb') as f:
            f.write(tflite_model)
    
    except Exception as e:
        print(traceback.format_exc())

if __name__ == '__main__':
    convert_onnx_to_tflite() 