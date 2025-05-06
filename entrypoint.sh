#!/usr/bin/env bash
set -euo pipefail

# 1) Проверяем, передали ли URL модели
if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL environment variable"
  exit 1
fi

# 2) Скачиваем модель в /models/model.gguf
echo "[entrypoint] Downloading model from $MODEL_URL ..."
wget -qO /models/model.gguf "$MODEL_URL"

# 3) Запускаем собранный бинарник llama.cpp
#    В CMake llama.cpp мейн-исполняемый файл называется 'main'
echo "[entrypoint] Starting server on port ${PORT:-8000} ..."
exec /app/llama.cpp/build/main \
  --server \
  -m /models/model.gguf \
  --port "${PORT:-8000}"
