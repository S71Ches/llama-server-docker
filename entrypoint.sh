#!/usr/bin/env bash
set -euo pipefail

# 1) Проверяем, что MODEL_URL передан
if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: environment variable MODEL_URL is not set."
  exit 1
fi

# 2) Путь, куда будет скачана модель
MODEL_PATH=/models/model.gguf

echo ">> Downloading model from: $MODEL_URL"
mkdir -p /models
curl -L --fail --retry 3 "$MODEL_URL" -o "$MODEL_PATH"

# 3) Запускаем встроенный сервер llama.cpp
#    -s: server mode
#    -m: модель
#    --threads: число потоков (по умолчанию 4)
#    --port: порт (по умолчанию 8000)
exec /app/main \
     -s \
     -m "$MODEL_PATH" \
     --threads "${NUM_THREADS:-4}" \
     --port "${PORT:-8000}"
