#!/bin/bash
set -e

# Проверяем переменную
if [ -z "$MODEL_URL" ]; then
  echo "❌ ERROR: MODEL_URL is not set"
  exit 1
fi

MODEL_DIR="/models"
MODEL_PATH="$MODEL_DIR/model.gguf"

echo "⬇️  Downloading model from $MODEL_URL…"
wget -qO "$MODEL_PATH" "$MODEL_URL"

echo "🚀 Starting server on port 8000…"
exec /app/server \
  -m "$MODEL_PATH" \
  --port 8000
