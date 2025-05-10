#!/usr/bin/env bash
set -euo pipefail

if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL environment variable"
  exit 1
fi

echo "[entrypoint] Downloading model from $MODEL_URL …"
wget -qO /models/model.gguf "$MODEL_URL"

echo "[entrypoint] Starting FastAPI server on 0.0.0.0:${PORT:-8000} …"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --workers "${WORKERS:-1}" \
     --reload
