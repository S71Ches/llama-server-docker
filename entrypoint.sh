#!/usr/bin/env bash
set -euo pipefail

# 1) Проверяем, передали ли URL модели
if [ -z "${MODEL_URL:-}" ]; then
  echo "ERROR: you must set MODEL_URL environment variable"
  exit 1
fi

# 2) Скачиваем модель в /models/model.gguf
echo "[entrypoint] Downloading model from $MODEL_URL …"
wget -qO /models/model.gguf "$MODEL_URL"

# 3) Запускаем FastAPI-сервис
echo "[entrypoint] Starting FastAPI server on 0.0.0.0:${PORT:-8000} …"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --workers 1 \
     --threads "${NUM_THREADS:-4}"
