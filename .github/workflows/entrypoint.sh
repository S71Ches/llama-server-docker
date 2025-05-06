#!/bin/bash

set -e

if [[ -n "$MODEL_URL" ]]; then
  echo "⬇️ Скачиваем модель из: $MODEL_URL"
  curl -L "$MODEL_URL" -o /models/model.gguf
else
  echo "⚠️ MODEL_URL не задан. Ожидаем модель в /models/model.gguf"
fi

echo "🚀 Запускаем llama.cpp сервер..."
exec ./server -m /models/model.gguf --port 8000
