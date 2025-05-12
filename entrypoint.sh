#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Ищем модель в /workspace…"
MODEL_SRC=$(ls /workspace/*.gguf 2>/dev/null | head -n1)
if [ -z "$MODEL_SRC" ]; then
  echo "❌ ERROR: не найден .gguf в /workspace"
  exit 1
fi

echo "[entrypoint] Модель найдена: $MODEL_SRC"
mkdir -p /models
cp "$MODEL_SRC" /models/model.gguf
echo "✅ Скопировали модель в /models/model.gguf"

echo "[entrypoint] Запускаем сервер…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --workers "${WORKERS:-1}"
