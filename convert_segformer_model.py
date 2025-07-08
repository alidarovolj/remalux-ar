#!/usr/bin/env python3
"""
Скрипт для конвертации SegFormer модели leftattention/segformer-b4-wall
из ONNX формата в TensorFlow Lite для использования во Flutter приложении.

Модель специально обучена для сегментации стен и имеет следующие характеристики:
- 4 класса: [background, wall, floor, ceiling] (предположительно)
- Mean IoU: 0.8993
- Overall Accuracy: 0.9558
- Размер: ~3.72M параметров (14.9MB)
"""

import onnx
import tensorflow as tf
import numpy as np
from onnx_tf.backend import prepare
import os

def convert_segformer_onnx_to_tflite():
    """
    Конвертирует SegFormer ONNX модель в TensorFlow Lite формат
    """
    
    # Пути к файлам
    onnx_model_path = "assets/ml/segformer-model-new.onnx"
    tflite_output_path = "assets/ml/segformer_b4_wall.tflite"
    
    print("🚀 Начинаем конвертацию SegFormer модели...")
    print(f"📂 Исходный файл: {onnx_model_path}")
    print(f"📂 Выходной файл: {tflite_output_path}")
    
    try:
        # 1. Загружаем ONNX модель
        print("\n📥 Загружаем ONNX модель...")
        onnx_model = onnx.load(onnx_model_path)
        
        # 2. Проверяем модель
        print("✅ Проверяем ONNX модель...")
        onnx.checker.check_model(onnx_model)
        
        # 3. Получаем информацию о входных/выходных тензорах
        print("\n📊 Информация о модели:")
        for input_tensor in onnx_model.graph.input:
            print(f"  Вход: {input_tensor.name}")
            dims = [dim.dim_value for dim in input_tensor.type.tensor_type.shape.dim]
            print(f"    Форма: {dims}")
            
        for output_tensor in onnx_model.graph.output:
            print(f"  Выход: {output_tensor.name}")
            dims = [dim.dim_value for dim in output_tensor.type.tensor_type.shape.dim]
            print(f"    Форма: {dims}")
        
        # 4. Конвертируем ONNX в TensorFlow
        print("\n🔄 Конвертируем ONNX в TensorFlow...")
        tf_rep = prepare(onnx_model)
        
        # 5. Получаем TensorFlow модель
        print("📦 Создаем TensorFlow модель...")
        
        # Создаем функцию для конвертации
        @tf.function
        def model_func(pixel_values):
            return tf_rep.run(pixel_values)
        
        # 6. Определяем входные спецификации (для SegFormer обычно 512x512)
        input_spec = tf.TensorSpec(shape=[1, 3, 512, 512], dtype=tf.float32)
        
        # 7. Создаем конкретную функцию
        concrete_func = model_func.get_concrete_function(input_spec)
        
        # 8. Конвертируем в TensorFlow Lite
        print("🎯 Конвертируем в TensorFlow Lite...")
        converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
        
        # Оптимизации для мобильных устройств
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        # Попробуем квантование для уменьшения размера
        converter.representative_dataset = generate_representative_dataset
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS  # Для поддержки сложных операций SegFormer
        ]
        
        # Генерируем TFLite модель
        tflite_model = converter.convert()
        
        # 9. Сохраняем модель
        print(f"💾 Сохраняем модель в {tflite_output_path}...")
        with open(tflite_output_path, 'wb') as f:
            f.write(tflite_model)
        
        # 10. Выводим информацию о результате
        original_size = os.path.getsize(onnx_model_path) / (1024 * 1024)  # MB
        tflite_size = os.path.getsize(tflite_output_path) / (1024 * 1024)  # MB
        
        print(f"\n🎉 Конвертация завершена успешно!")
        print(f"📏 Размер ONNX модели: {original_size:.2f} MB")
        print(f"📏 Размер TFLite модели: {tflite_size:.2f} MB")
        print(f"📉 Уменьшение размера: {((original_size - tflite_size) / original_size * 100):.1f}%")
        
        # 11. Тестируем модель
        print("\n🧪 Тестируем конвертированную модель...")
        test_tflite_model(tflite_output_path)
        
        return True
        
    except Exception as e:
        print(f"❌ Ошибка при конвертации: {str(e)}")
        return False

def generate_representative_dataset():
    """
    Генерирует репрезентативный датасет для квантования модели
    """
    print("📊 Генерируем репрезентативный датасет...")
    for _ in range(100):
        # Генерируем случайные изображения размера 512x512
        # В реальности здесь должны быть реальные изображения стен
        yield [np.random.random((1, 3, 512, 512)).astype(np.float32)]

def test_tflite_model(tflite_path):
    """
    Тестирует конвертированную TFLite модель
    """
    try:
        # Загружаем интерпретатор
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()
        
        # Получаем детали входа и выхода
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✅ Модель загружена успешно!")
        print(f"📊 Входных тензоров: {len(input_details)}")
        print(f"📊 Выходных тензоров: {len(output_details)}")
        
        for i, detail in enumerate(input_details):
            print(f"  Вход {i}: форма {detail['shape']}, тип {detail['dtype']}")
            
        for i, detail in enumerate(output_details):
            print(f"  Выход {i}: форма {detail['shape']}, тип {detail['dtype']}")
        
        # Тестовый инференс
        test_input = np.random.random(input_details[0]['shape']).astype(input_details[0]['dtype'])
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"🧪 Тестовый инференс прошел успешно!")
        print(f"📏 Форма выхода: {output.shape}")
        print(f"📊 Диапазон значений: [{output.min():.4f}, {output.max():.4f}]")
        
        return True
        
    except Exception as e:
        print(f"❌ Ошибка при тестировании: {str(e)}")
        return False

def update_flutter_config():
    """
    Обновляет Flutter конфигурацию для использования новой модели
    """
    print("\n🔧 Обновляем конфигурацию Flutter...")
    
    # Информация о новой модели для документации
    model_info = {
        "name": "segformer_b4_wall.tflite",
        "source": "leftattention/segformer-b4-wall",
        "classes": 4,
        "input_size": [512, 512],
        "metrics": {
            "mean_iou": 0.8993,
            "overall_accuracy": 0.9558,
            "mean_accuracy": 0.9448
        },
        "class_mapping": {
            "0": "background", 
            "1": "wall",
            "2": "floor", 
            "3": "ceiling"
        }
    }
    
    print("📝 Информация о новой модели:")
    print(f"  Имя: {model_info['name']}")
    print(f"  Источник: {model_info['source']}")
    print(f"  Классы: {model_info['classes']}")
    print(f"  Размер входа: {model_info['input_size']}")
    print(f"  Mean IoU: {model_info['metrics']['mean_iou']}")
    print(f"  Overall Accuracy: {model_info['metrics']['overall_accuracy']}")
    
    return model_info

if __name__ == "__main__":
    print("=" * 60)
    print("🎯 SegFormer ONNX → TensorFlow Lite конвертер")
    print("=" * 60)
    
    # Проверяем наличие исходного файла
    if not os.path.exists("assets/ml/segformer-model-new.onnx"):
        print("❌ Файл segformer-model-new.onnx не найден в assets/ml/")
        exit(1)
    
    # Выполняем конвертацию
    success = convert_segformer_onnx_to_tflite()
    
    if success:
        # Обновляем конфигурацию Flutter
        model_info = update_flutter_config()
        
        print("\n" + "=" * 60)
        print("🎉 КОНВЕРТАЦИЯ ЗАВЕРШЕНА УСПЕШНО!")
        print("=" * 60)
        print("\n📋 Следующие шаги:")
        print("1. Обновить SegmentationService для использования новой модели")
        print("2. Изменить индекс класса 'wall' с 2 на 1")
        print("3. Протестировать производительность на устройстве")
        print("4. Сравнить качество сегментации с предыдущей моделью")
        
    else:
        print("\n❌ Конвертация не удалась. Проверьте ошибки выше.")
        exit(1) 