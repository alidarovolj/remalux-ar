#!/usr/bin/env python3
"""
Скрипт для исследования SegFormer ONNX модели и прямой конвертации в TFLite
"""

import onnx
import numpy as np
import tensorflow as tf
from onnx import numpy_helper
import os

def inspect_onnx_model():
    """
    Исследует структуру ONNX модели
    """
    model_path = "assets/ml/segformer-model-new.onnx"
    
    print("🔍 Исследуем ONNX модель SegFormer...")
    
    try:
        # Загружаем модель
        model = onnx.load(model_path)
        
        # Базовая информация
        print(f"\n📊 Базовая информация:")
        print(f"  IR версия: {model.ir_version}")
        print(f"  Producer: {model.producer_name} {model.producer_version}")
        print(f"  Domain: {model.domain}")
        
        # Входы модели
        print(f"\n📥 Входные тензоры:")
        for input_tensor in model.graph.input:
            print(f"  Имя: {input_tensor.name}")
            shape = []
            for dim in input_tensor.type.tensor_type.shape.dim:
                if dim.dim_value:
                    shape.append(dim.dim_value)
                elif dim.dim_param:
                    shape.append(f"'{dim.dim_param}'")
                else:
                    shape.append("?")
            print(f"  Форма: {shape}")
            print(f"  Тип: {input_tensor.type.tensor_type.elem_type}")
        
        # Выходы модели
        print(f"\n📤 Выходные тензоры:")
        for output_tensor in model.graph.output:
            print(f"  Имя: {output_tensor.name}")
            shape = []
            for dim in output_tensor.type.tensor_type.shape.dim:
                if dim.dim_value:
                    shape.append(dim.dim_value)
                elif dim.dim_param:
                    shape.append(f"'{dim.dim_param}'")
                else:
                    shape.append("?")
            print(f"  Форма: {shape}")
            print(f"  Тип: {output_tensor.type.tensor_type.elem_type}")
        
        # Узлы модели
        print(f"\n🧠 Узлы модели: {len(model.graph.node)}")
        op_types = {}
        for node in model.graph.node:
            op_type = node.op_type
            if op_type in op_types:
                op_types[op_type] += 1
            else:
                op_types[op_type] = 1
        
        print(f"  Типы операций:")
        for op_type, count in sorted(op_types.items()):
            print(f"    {op_type}: {count}")
        
        # Инициализаторы (веса)
        print(f"\n⚖️ Параметры модели: {len(model.graph.initializer)}")
        total_params = 0
        for init in model.graph.initializer:
            tensor = numpy_helper.to_array(init)
            params = np.prod(tensor.shape)
            total_params += params
            print(f"  {init.name}: {tensor.shape} ({params:,} параметров)")
        
        print(f"\n📊 Общее количество параметров: {total_params:,}")
        
        return model
        
    except Exception as e:
        print(f"❌ Ошибка при исследовании модели: {e}")
        return None

def try_alternative_conversion():
    """
    Пробуем альтернативные способы конвертации
    """
    print("\n🔄 Пробуем альтернативные способы конвертации...")
    
    model_path = "assets/ml/segformer-model-new.onnx"
    
    # Способ 1: Прямая загрузка через tf2onnx (обратная конвертация)
    try:
        print("\n🔄 Способ 1: Используем onnxruntime для тестирования...")
        
        # Устанавливаем onnxruntime если нужно
        try:
            import onnxruntime as ort
        except ImportError:
            print("⚠️ onnxruntime не установлен. Устанавливаем...")
            os.system("python3 -m pip install onnxruntime")
            import onnxruntime as ort
        
        # Создаем сессию ONNX Runtime
        session = ort.InferenceSession(model_path)
        
        # Получаем информацию о входах/выходах
        input_info = session.get_inputs()[0]
        output_info = session.get_outputs()[0]
        
        print(f"✅ ONNX Runtime загрузка успешна!")
        print(f"  Вход: {input_info.name}, форма: {input_info.shape}, тип: {input_info.type}")
        print(f"  Выход: {output_info.name}, форма: {output_info.shape}, тип: {output_info.type}")
        
        # Определяем форму входа
        input_shape = input_info.shape
        if input_shape[0] == 'batch_size' or input_shape[0] is None:
            input_shape = [1] + list(input_shape[1:])
        
        # Тестовый инференс
        test_input = np.random.randn(*input_shape).astype(np.float32)
        output = session.run([output_info.name], {input_info.name: test_input})
        
        print(f"🧪 Тестовый инференс:")
        print(f"  Форма входа: {test_input.shape}")
        print(f"  Форма выхода: {output[0].shape}")
        print(f"  Диапазон выхода: [{output[0].min():.4f}, {output[0].max():.4f}]")
        
        return True, input_shape, output[0].shape
        
    except Exception as e:
        print(f"❌ Ошибка в способе 1: {e}")
    
    return False, None, None

def create_wrapper_tflite_model(input_shape, output_shape):
    """
    Создает wrapper TFLite модель, которая может использовать ONNX через onnxruntime
    """
    print(f"\n🎯 Создаем обертку для использования ONNX модели...")
    
    # Поскольку прямая конвертация не работает, создадим документацию
    # о том, как интегрировать ONNX модель во Flutter
    
    model_info = {
        "name": "segformer-model-new.onnx",
        "type": "ONNX",
        "source": "leftattention/segformer-b4-wall",
        "input_shape": input_shape,
        "output_shape": output_shape,
        "classes": 4,
        "class_mapping": {
            0: "background",
            1: "wall", 
            2: "floor",
            3: "ceiling"
        },
        "metrics": {
            "mean_iou": 0.8993,
            "overall_accuracy": 0.9558
        },
        "usage_note": "Для использования в Flutter потребуется onnxruntime_flutter плагин"
    }
    
    print(f"📝 Информация о модели:")
    for key, value in model_info.items():
        print(f"  {key}: {value}")
    
    return model_info

def suggest_flutter_integration():
    """
    Предлагает варианты интеграции ONNX модели во Flutter
    """
    print(f"\n💡 Варианты интеграции во Flutter:")
    
    print(f"\n1. 📱 Использование onnxruntime_flutter:")
    print(f"   • Добавить в pubspec.yaml: onnxruntime: ^1.14.1")
    print(f"   • Прямое использование ONNX модели без конвертации")
    print(f"   • Лучшая производительность для сложных моделей")
    
    print(f"\n2. 🔧 Использование готовой TFLite модели:")
    print(f"   • В assets/ml/ уже есть segformer.tflite (197KB)")
    print(f"   • Меньший размер, может быть уже оптимизирована")
    print(f"   • Проверить совместимость с нашими классами")
    
    print(f"\n3. ☁️ Серверная обработка:")
    print(f"   • Развернуть SegFormer на сервере")
    print(f"   • Отправлять изображения через API")
    print(f"   • Получать маски сегментации")
    
    print(f"\n4. 🎯 Упрощенная модель:")
    print(f"   • Использовать более простую модель (DeepLab v3+)")
    print(f"   • Меньший размер и проще в конвертации")
    print(f"   • assets/ml/deeplabv3_mnv2_ade20k_1.tflite уже работает")

if __name__ == "__main__":
    print("=" * 60)
    print("🔍 Исследование SegFormer ONNX модели")
    print("=" * 60)
    
    # Исследуем модель
    model = inspect_onnx_model()
    
    if model:
        # Пробуем альтернативную конвертацию
        success, input_shape, output_shape = try_alternative_conversion()
        
        if success:
            # Создаем информацию о модели
            model_info = create_wrapper_tflite_model(input_shape, output_shape)
        
        # Предлагаем варианты интеграции
        suggest_flutter_integration()
    
    print(f"\n" + "=" * 60)
    print(f"🏁 Исследование завершено")
    print("=" * 60) 