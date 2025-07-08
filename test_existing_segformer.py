#!/usr/bin/env python3
"""
Скрипт для тестирования готовой segformer.tflite модели
"""

import tensorflow as tf
import numpy as np
import os

def test_existing_segformer():
    """
    Тестирует готовую segformer.tflite модель
    """
    model_path = "assets/ml/segformer.tflite"
    
    if not os.path.exists(model_path):
        print("❌ Файл segformer.tflite не найден")
        return False
    
    print("🔍 Тестируем готовую segformer.tflite модель...")
    
    try:
        # Загружаем интерпретатор
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Получаем детали входа и выхода
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"\n✅ Модель загружена успешно!")
        print(f"📊 Входных тензоров: {len(input_details)}")
        print(f"📊 Выходных тензоров: {len(output_details)}")
        
        print(f"\n📥 Входные тензоры:")
        for i, detail in enumerate(input_details):
            print(f"  {i}: имя='{detail['name']}', форма={detail['shape']}, тип={detail['dtype']}")
            
        print(f"\n📤 Выходные тензоры:")
        for i, detail in enumerate(output_details):
            print(f"  {i}: имя='{detail['name']}', форма={detail['shape']}, тип={detail['dtype']}")
        
        # Тестовый инференс
        input_shape = input_details[0]['shape']
        input_dtype = input_details[0]['dtype']
        
        print(f"\n🧪 Тестовый инференс:")
        print(f"  Создаем тестовое изображение {input_shape}...")
        
        # Создаем тестовое изображение
        test_input = np.random.random(input_shape).astype(input_dtype)
        
        # Нормализуем в диапазон [0, 1] если нужно
        if input_dtype == np.float32:
            test_input = (test_input * 255.0).astype(np.uint8).astype(np.float32) / 255.0
        
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        
        output = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"  ✅ Инференс успешен!")
        print(f"  📏 Форма выхода: {output.shape}")
        print(f"  📊 Диапазон значений: [{output.min():.4f}, {output.max():.4f}]")
        print(f"  📊 Уникальные значения (классы): {np.unique(output.argmax(axis=-1))}")
        
        # Анализируем количество классов
        if len(output.shape) == 4:  # [batch, height, width, classes]
            num_classes = output.shape[-1]
        elif len(output.shape) == 3:  # [batch, height, width] - уже argmax
            num_classes = len(np.unique(output))
        else:
            num_classes = "неизвестно"
        
        print(f"  🏷️ Количество классов: {num_classes}")
        
        # Размер файла
        file_size = os.path.getsize(model_path) / 1024  # KB
        print(f"  📦 Размер файла: {file_size:.1f} KB")
        
        model_info = {
            "path": model_path,
            "input_shape": input_shape.tolist(),
            "output_shape": output.shape,
            "num_classes": num_classes,
            "file_size_kb": file_size,
            "dtype": str(input_dtype)
        }
        
        return True, model_info
        
    except Exception as e:
        print(f"❌ Ошибка при тестировании: {e}")
        return False, None

def compare_models():
    """
    Сравнивает доступные модели
    """
    print("\n📊 Сравнение доступных моделей:")
    
    models = [
        ("segformer.tflite", "assets/ml/segformer.tflite"),
        ("deeplabv3_mnv2_ade20k_1.tflite", "assets/ml/deeplabv3_mnv2_ade20k_1.tflite"),
        ("segformer-model-new.onnx", "assets/ml/segformer-model-new.onnx")
    ]
    
    print(f"\n{'Модель':<30} {'Размер':<10} {'Формат':<8} {'Статус':<10}")
    print("-" * 60)
    
    available_models = []
    
    for name, path in models:
        if os.path.exists(path):
            size = os.path.getsize(path) / (1024 * 1024)  # MB
            format_type = path.split('.')[-1].upper()
            status = "✅ Есть"
            available_models.append((name, path, size, format_type))
        else:
            size = 0
            format_type = "N/A"
            status = "❌ Нет"
        
        print(f"{name:<30} {size:>7.1f}MB {format_type:<8} {status:<10}")
    
    return available_models

def recommend_best_model():
    """
    Рекомендует лучшую модель для использования
    """
    print("\n💡 Рекомендации по выбору модели:")
    
    print("\n1. 🏆 segformer.tflite (197KB) - РЕКОМЕНДУЕТСЯ")
    print("   ✅ Очень маленький размер")
    print("   ✅ Готов к использованию в TensorFlow Lite")
    print("   ✅ Быстрая загрузка и инференс")
    print("   ⚠️  Нужно проверить качество сегментации")
    
    print("\n2. 🥈 deeplabv3_mnv2_ade20k_1.tflite (5.2KB)")
    print("   ✅ Уже проверен и работает")
    print("   ✅ Поддерживает индекс 'wall' = 2")
    print("   ✅ Совместим с текущим кодом")
    print("   ⚠️  Может быть менее точным чем SegFormer")
    
    print("\n3. 🥉 segformer-model-new.onnx (14MB)")
    print("   ✅ Наилучшее качество (Mean IoU: 0.8993)")
    print("   ✅ Специально обучен для стен")
    print("   ❌ Большой размер")
    print("   ❌ Требует ONNX Runtime")
    print("   ❌ Сложнее интеграция во Flutter")
    
    print("\n🎯 ВЫВОД: Рекомендуется использовать segformer.tflite")
    print("   Если качество не устроит - можно вернуться к deeplabv3_mnv2_ade20k_1.tflite")

if __name__ == "__main__":
    print("=" * 60)
    print("🧪 Тестирование готовых моделей сегментации")
    print("=" * 60)
    
    # Сравниваем доступные модели
    available_models = compare_models()
    
    # Тестируем segformer.tflite если есть
    success, model_info = test_existing_segformer()
    
    if success:
        print(f"\n📋 Информация о segformer.tflite:")
        for key, value in model_info.items():
            print(f"  {key}: {value}")
    
    # Выдаем рекомендации
    recommend_best_model()
    
    print(f"\n" + "=" * 60)
    print(f"🏁 Тестирование завершено")
    print("=" * 60) 