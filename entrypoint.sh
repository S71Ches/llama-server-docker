#!/bin/bash
set -e

# Проверяем, что MODEL_URL задана
if [ -z "$MODEL_URL" ]; then
  echo "❌ Ошибка: переменная окружения MODEL_URL не задана."
  echo "   Пример: docker run -e MODEL_URL=https://huggingface.co/... image"
  exit 1
fi

MODEL_DIR="/models"
# 1) Скачиваем модель
echo "⬇️  Downloading model from $MODEL_URL..."
wget -qO "$MODEL_DIR/model.gguf" "$MODEL_URL"

# 2) Запускаем сервер llama.cpp
echo "🚀 Starting llama.cpp server on port 8000..."
exec /app/server \
     -m "$MODEL_DIR/model.gguf" \
     --port 8000
