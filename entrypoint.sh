#!/usr/bin/env bash
# entrypoint.sh

set -euo pipefail

# 1) Проверка MODEL_URL
if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL environment variable"
  exit 1
fi

echo "[entrypoint] Downloading model from $MODEL_URL …"
wget -qO /app/model.gguf "$MODEL_URL"

echo "[entrypoint] Starting Python API server on 0.0.0.0:${PORT:-8000} with 4 threads…"
exec uvicorn llama_cpp.server:app \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --workers 1 \
     --loop asyncio \
     --env MODEL_PATH=/app/model.gguf \
     --env LLAMA_THREADS=${NUM_THREADS:-4} \
     --env LLAMA_N_GPU_LAYERS=all
