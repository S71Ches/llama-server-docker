#!/usr/bin/env bash
set -euo pipefail

if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL environment variable"
  exit 1
fi

echo "[entrypoint] Starting llama-server on port ${PORT:-8000}…"
exec /app/llama.cpp/build/bin/llama-server \
  --model-url "$MODEL_URL" \
  --host "0.0.0.0" \
  --port "${PORT:-8000}" \
  --threads "${NUM_THREADS:-4}" \
  --threads-http "${THREADS_HTTP:-2}" \
  --no-webui
