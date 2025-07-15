# Используем официальный образ Python 3.10
FROM python:3.10-slim

# Устанавливаем рабочую директорию в контейнере
WORKDIR /app

# Копируем локальный архив с моделью и скрипт
COPY model.tar.gz .
COPY scripts/convert_model.py .

# Распаковываем архив
RUN tar -xzf model.tar.gz

# Устанавливаем необходимые зависимости
RUN pip install --no-cache-dir tensorflow tensorflow_hub

# Запускаем скрипт конвертации
CMD ["python", "convert_model.py"] 