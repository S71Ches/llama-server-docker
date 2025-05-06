#!/bin/bash
set -e

MODEL_PATH="/models/model.gguf"

# Если задана ссылка — качаем модель
if [ ! -f "$MODEL_PATH" ]; then
  if [ -n "$MODEL_URL" ]; then
    echo "📥 Скачиваем модель из $MODEL_URL"
    curl -L "$MODEL_URL" -o "$MODEL_PATH"
  else
    echo "❌ MODEL_URL не задан. Прекращаю запуск."
    exit 1
  fi
fi

echo "🚀 Запускаем сервер с моделью: $MODEL_PATH"
cd /app
./server -m "$MODEL_PATH" --port 8000
