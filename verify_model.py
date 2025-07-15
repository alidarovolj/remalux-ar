import tensorflow as tf
import os

# --- Настройки ---
# Укажите путь к вашей tflite модели относительно корня проекта
MODEL_PATH = "assets/ml/deeplabv3_ade20k_fp16.tflite"
# -----------------

def verify_model(model_path):
    """
    Проверяет TFLite модель на валидность.
    """
    print(f"--- Проверка модели по пути: {model_path} ---")

    if not os.path.exists(model_path):
        print(f"❌ Ошибка: Файл не найден по пути '{model_path}'.")
        print("Пожалуйста, убедитесь, что путь указан верно от корня проекта.")
        return

    try:
        # Попытка загрузить модель и выделить тензоры
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()

        # Получение информации о входах и выходах
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        print("✅ Модель успешно загружена и верифицирована.")
        print("\n--- Детали входа ---")
        print(input_details)
        print("\n--- Детали выхода ---")
        print(output_details)
        print("\n--- Вывод ---")
        print("Файл модели в порядке. Проблема не в его целостности.")

    except Exception as e:
        print(f"❌ КРИТИЧЕСКАЯ ОШИВКА: Не удалось загрузить модель.")
        print("Это подтверждает, что файл модели поврежден или имеет неверный формат (ошибка 'Flatbuffer').")
        print(f"Детали ошибки: {e}")

if __name__ == "__main__":
    verify_model(MODEL_PATH) 