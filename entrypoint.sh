#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Starting entrypoint script..."

# 1. Проверка переменной MODEL_URL
if [ -z "${MODEL_URL:-}" ]; then
  echo "❌ ERROR: MODEL_URL environment variable not set"
  exit 1
fi

echo "[entrypoint] Downloading model from: $MODEL_URL"

# 2. Создаём папку для модели
mkdir -p /models || { echo "❌ ERROR: Cannot create /models directory"; exit 1; }

# 3. Скачиваем с retry и таймаутами
wget --retry-connrefused --tries=5 --timeout=30 -nv -O /models/model.gguf "$MODEL_URL" \
  || { echo "❌ ERROR: wget failed to download model after retries"; exit 1; }

echo "✅ Model downloaded successfully"

# 4. Простейшая проверка целостности по размеру (>500 МБ)
MIN_SIZE=$((500 * 1024 * 1024))
FILE_SIZE=$(stat -c%s /models/model.gguf)
if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
  echo "❌ ERROR: Downloaded file too small ($FILE_SIZE bytes < $MIN_SIZE bytes)"
  exit 1
fi

echo "✅ Integrity check passed (file size: $FILE_SIZE bytes)"

# 5. Запускаем FastAPI-сервер
echo "[entrypoint] Launching FastAPI server..."
exec uvicorn server:app --host 0.0.0.0 --port 8000
