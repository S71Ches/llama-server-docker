#!/usr/bin/env bash
set -euo pipefail

# 1) Проверяем переменную
if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL"
  exit 1
fi

# 2) Скачиваем модель
echo "[entrypoint] Downloading model from $MODEL_URL …"
wget -qO /models/model.gguf "$MODEL_URL"

# 3) Запускаем llama-server
echo "[entrypoint] Starting llama-server on port ${PORT:-8000} …"
exec /app/llama.cpp/build/bin/llama-server \
  --model /models/model.gguf \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --threads "${NUM_THREADS:-4}"
