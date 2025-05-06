#!/bin/bash
set -e

if [ -z "$MODEL_URL" ]; then
  echo "❌ ERROR: MODEL_URL is not set"
  exit 1
fi

MODEL_DIR="/models"
echo "⬇️  Download model from $MODEL_URL…"
wget -qO "$MODEL_DIR/model.gguf" "$MODEL_URL"

echo "🚀 Starting server on port 8000…"
exec /app/server \
     -m "$MODEL_DIR/model.gguf" \
     --port 8000
