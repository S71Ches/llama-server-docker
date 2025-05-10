#!/usr/bin/env bash
set -euo pipefail

# Проверяем MODEL_URL
if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL"
  exit 1
fi

echo "[entrypoint] Downloading model from $MODEL_URL …"
wget -qO /models/model.gguf "$MODEL_URL"

echo "[entrypoint] Starting llama-server on :${PORT:-8000} …"
exec /app/llama.cpp/build/bin/llama-server \
     --server \
     --model /models/model.gguf \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --threads "${NUM_THREADS:-4}" \
     --threads-http "${THREADS_HTTP:-2}" \
     --no-webui
