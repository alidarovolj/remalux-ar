#!/usr/bin/env python3
"""
Скрипт для нативного бенчмаркинга TFLite моделей на Android устройствах
Использует официальный TensorFlow Lite benchmark tool через adb
"""

import os
import subprocess
import json
import time
from typing import Dict, List, Optional
from pathlib import Path

class TFLiteBenchmark:
    def __init__(self, device_id: Optional[str] = None):
        self.device_id = device_id
        self.adb_prefix = ['adb'] + (['-s', device_id] if device_id else [])
        self.device_tmp_dir = '/data/local/tmp'
        self.benchmark_binary = 'benchmark_model'
        
    def check_device_connected(self) -> bool:
        """Проверить подключение Android устройства"""
        try:
            result = subprocess.run(
                self.adb_prefix + ['shell', 'echo', 'test'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except subprocess.TimeoutExpired:
            return False
    
    def get_device_info(self) -> Dict[str, str]:
        """Получить информацию об устройстве"""
        if not self.check_device_connected():
            raise RuntimeError("Устройство не подключено")
        
        info = {}
        
        # Модель устройства
        result = subprocess.run(
            self.adb_prefix + ['shell', 'getprop', 'ro.product.model'],
            capture_output=True, text=True
        )
        info['model'] = result.stdout.strip()
        
        # Процессор
        result = subprocess.run(
            self.adb_prefix + ['shell', 'getprop', 'ro.product.board'],
            capture_output=True, text=True
        )
        info['board'] = result.stdout.strip()
        
        # Версия Android
        result = subprocess.run(
            self.adb_prefix + ['shell', 'getprop', 'ro.build.version.release'],
            capture_output=True, text=True
        )
        info['android_version'] = result.stdout.strip()
        
        # GPU информация (пытаемся получить через OpenGL)
        result = subprocess.run(
            self.adb_prefix + ['shell', 'dumpsys', 'SurfaceFlinger', '|', 'grep', 'GLES'],
            capture_output=True, text=True, shell=True
        )
        info['gpu_info'] = result.stdout.strip()
        
        return info
    
    def download_benchmark_tool(self) -> bool:
        """Скачать официальный benchmark tool для TensorFlow Lite"""
        # URL для скачивания предкомпилированного бинарника
        # В реальном проекте нужно будет скачать с официального репозитория
        print("⚠️  Для полноценного бенчмаркинга требуется скачать benchmark_model binary")
        print("   Инструкции: https://www.tensorflow.org/lite/performance/measurement")
        print("   Или соберите из исходников: https://github.com/tensorflow/tensorflow")
        return False
    
    def upload_model(self, model_path: str) -> str:
        """Загрузить модель на устройство"""
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Модель не найдена: {model_path}")
        
        model_name = os.path.basename(model_path)
        device_model_path = f"{self.device_tmp_dir}/{model_name}"
        
        print(f"📤 Загружаем модель {model_name} на устройство...")
        result = subprocess.run(
            self.adb_prefix + ['push', model_path, device_model_path],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            raise RuntimeError(f"Ошибка загрузки модели: {result.stderr}")
        
        return device_model_path
    
    def run_benchmark(self, device_model_path: str, num_runs: int = 50, 
                     num_threads: int = 4, use_gpu: bool = False) -> Dict:
        """Запустить бенчмарк модели"""
        print(f"🔧 Запускаем бенчмарк для {os.path.basename(device_model_path)}...")
        
        # Формируем команду для бенчмарка
        cmd = [
            'shell',
            f'{self.device_tmp_dir}/{self.benchmark_binary}',
            f'--graph={device_model_path}',
            f'--num_runs={num_runs}',
            f'--num_threads={num_threads}',
            '--enable_op_profiling=true',
            '--verbose'
        ]
        
        if use_gpu:
            cmd.append('--use_gpu=true')
        
        # Пытаемся запустить (скорее всего не сработает без бинарника)
        try:
            result = subprocess.run(
                self.adb_prefix + cmd,
                capture_output=True, text=True, timeout=120
            )
            
            if result.returncode != 0:
                print(f"❌ Ошибка выполнения бенчмарка: {result.stderr}")
                return self._create_fallback_metrics(device_model_path)
            
            return self._parse_benchmark_output(result.stdout)
            
        except subprocess.TimeoutExpired:
            print("⏱️  Бенчмарк прерван по таймауту")
            return self._create_fallback_metrics(device_model_path)
        except Exception as e:
            print(f"❌ Ошибка: {e}")
            return self._create_fallback_metrics(device_model_path)
    
    def _create_fallback_metrics(self, model_path: str) -> Dict:
        """Создать заглушку метрик когда нативный бенчмарк недоступен"""
        model_name = os.path.basename(model_path)
        
        # Получаем размер файла модели
        try:
            result = subprocess.run(
                self.adb_prefix + ['shell', 'stat', '-c', '%s', model_path],
                capture_output=True, text=True
            )
            model_size_bytes = int(result.stdout.strip()) if result.returncode == 0 else 0
            model_size_mb = model_size_bytes / (1024 * 1024)
        except:
            model_size_mb = 0
        
        return {
            'model_name': model_name,
            'model_size_mb': round(model_size_mb, 1),
            'inference_latency_ms': 'N/A (требуется benchmark binary)',
            'min_latency_ms': 'N/A',
            'max_latency_ms': 'N/A',
            'avg_latency_ms': 'N/A',
            'num_runs': 'N/A',
            'delegate': 'CPU',
            'operator_profiling': 'N/A',
            'note': 'Для точных метрик установите TensorFlow Lite benchmark tool'
        }
    
    def _parse_benchmark_output(self, output: str) -> Dict:
        """Парсить вывод benchmark tool"""
        lines = output.split('\n')
        metrics = {}
        
        for line in lines:
            line = line.strip()
            
            # Ищем основные метрики
            if 'Average inference timings in us' in line:
                # Парсим среднее время
                pass
            elif 'Min:' in line and 'Max:' in line:
                # Парсим мин/макс время
                pass
            # Добавить больше парсинга по мере необходимости
        
        # Заглушка для демонстрации структуры
        return {
            'inference_latency_ms': 'parsed_value',
            'min_latency_ms': 'parsed_min',
            'max_latency_ms': 'parsed_max',
            'operator_profiling': 'parsed_operators'
        }
    
    def benchmark_models(self, model_paths: List[str], output_file: str = 'benchmark_results.json'):
        """Запустить бенчмарк для нескольких моделей"""
        if not self.check_device_connected():
            raise RuntimeError("Устройство не подключено")
        
        device_info = self.get_device_info()
        print(f"📱 Устройство: {device_info['model']} (Android {device_info['android_version']})")
        
        results = {
            'timestamp': time.time(),
            'device_info': device_info,
            'models': []
        }
        
        for model_path in model_paths:
            if not os.path.exists(model_path):
                print(f"⚠️  Модель не найдена: {model_path}")
                continue
            
            try:
                # Загружаем модель на устройство
                device_model_path = self.upload_model(model_path)
                
                # CPU бенчмарк
                cpu_metrics = self.run_benchmark(device_model_path, use_gpu=False)
                cpu_metrics['delegate'] = 'CPU'
                
                # GPU бенчмарк (если поддерживается)
                gpu_metrics = self.run_benchmark(device_model_path, use_gpu=True)
                gpu_metrics['delegate'] = 'GPU'
                
                results['models'].append({
                    'model_path': model_path,
                    'cpu_metrics': cpu_metrics,
                    'gpu_metrics': gpu_metrics
                })
                
            except Exception as e:
                print(f"❌ Ошибка бенчмарка для {model_path}: {e}")
                continue
        
        # Сохраняем результаты
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Результаты сохранены в {output_file}")
        return results

def main():
    """Основная функция для запуска бенчмарков"""
    import argparse
    
    parser = argparse.ArgumentParser(description='TFLite Model Benchmark Tool')
    parser.add_argument('--models', nargs='+', required=True, 
                       help='Пути к TFLite моделям для бенчмарка')
    parser.add_argument('--device', help='ID Android устройства (опционально)')
    parser.add_argument('--output', default='benchmark_results.json',
                       help='Файл для сохранения результатов')
    
    args = parser.parse_args()
    
    # Создаем бенчмаркер
    benchmark = TFLiteBenchmark(device_id=args.device)
    
    try:
        # Запускаем бенчмарки
        results = benchmark.benchmark_models(args.models, args.output)
        
        # Выводим краткую сводку
        print("\n📊 Краткая сводка:")
        for model_result in results['models']:
            model_name = os.path.basename(model_result['model_path'])
            cpu_latency = model_result['cpu_metrics'].get('avg_latency_ms', 'N/A')
            gpu_latency = model_result['gpu_metrics'].get('avg_latency_ms', 'N/A')
            print(f"  {model_name}: CPU={cpu_latency}ms, GPU={gpu_latency}ms")
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main()) 