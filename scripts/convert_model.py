import tensorflow.compat.v1 as tf
import os

tf.disable_v2_behavior()

# Определяем пути и имена
MODEL_DIR = "deeplabv3_mnv2_ade20k_train_2018_12_03"
FROZEN_GRAPH_PATH = os.path.join(MODEL_DIR, "frozen_inference_graph.pb")
SAVE_DIR = "assets/ml"
TFLITE_MODEL_NAME = "deeplabv3_ade20k_fp16.tflite"
TFLITE_MODEL_PATH = os.path.join(SAVE_DIR, TFLITE_MODEL_NAME)

# Имена входных и выходных тензоров для этой конкретной модели
# Их можно узнать, проанализировав модель инструментами вроде Netron
INPUT_TENSOR_NAME = "ImageTensor"
OUTPUT_TENSOR_NAME = "SemanticPredictions"

def main():
    """
    Основная функция для конвертации "замороженного графа" (.pb) в .tflite.
    """
    print(">>> Начало процесса конвертации модели (из frozen graph)...")

    if not os.path.exists(FROZEN_GRAPH_PATH):
        print(f"!!! Ошибка: Файл модели не найден по пути {FROZEN_GRAPH_PATH}")
        print("--- Убедитесь, что архив model.tar.gz был распакован.")
        return

    # Создаем директорию для сохранения, если она не существует
    if not os.path.exists(SAVE_DIR):
        os.makedirs(SAVE_DIR)
        print(f"--- Создана директория: {SAVE_DIR}")

    # Шаг 1: Конвертация модели из frozen graph
    print(f"--- Шаг 1/2: Конвертация из {FROZEN_GRAPH_PATH}...")
    try:
        converter = tf.lite.TFLiteConverter.from_frozen_graph(
            graph_def_file=FROZEN_GRAPH_PATH,
            input_arrays=[INPUT_TENSOR_NAME],
            output_arrays=[OUTPUT_TENSOR_NAME]
        )
        # Разрешаем использование операций из TensorFlow, которых нет в TFLite
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS, # Стандартные операции
            tf.lite.OpsSet.SELECT_TF_OPS # Дополнительные операции из TF
        ]
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        tflite_model = converter.convert()
        print("--- Модель успешно конвертирована.")
    except Exception as e:
        print(f"!!! Ошибка при конвертации модели: {e}")
        return

    # Шаг 2: Сохранение .tflite файла
    print(f"--- Шаг 2/2: Сохранение модели в {TFLITE_MODEL_PATH}")
    try:
        with open(TFLITE_MODEL_PATH, "wb") as f:
            f.write(tflite_model)
        print(f"--- Модель успешно сохранена. Размер: {len(tflite_model) / 1024 / 1024:.2f} MB")
        print(f"\n>>> Процесс завершен! Модель находится в: {TFLITE_MODEL_PATH}")
    except Exception as e:
        print(f"!!! Ошибка при сохранении файла модели: {e}")

if __name__ == "__main__":
    main() 