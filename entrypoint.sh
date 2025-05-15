#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh…"

# 0) Проверяем обязательные переменные
: "${CF_TUNNEL_TOKEN:?ERROR: нужно задать CF_TUNNEL_TOKEN}"
: "${CF_HOSTNAME:?ERROR: нужно задать CF_HOSTNAME (например domen.xyz)}"
PORT="${PORT:-8000}"
WORKERS="${WORKERS:-1}"

# 1) Старт Cloudflare Tunnel в фоне
echo "[entrypoint] Старт cloudflared на ${CF_HOSTNAME} → localhost:${PORT}"
nohup cloudflared tunnel run \
    --token "${CF_TUNNEL_TOKEN}" \
    --hostname "${CF_HOSTNAME}" \
    --url "http://localhost:${PORT}" \
    --no-autoupdate \
    > /tmp/cloudflared.log 2>&1 &

# Даем пару секунд на инициализацию
sleep 2

CF_URL="https://${CF_HOSTNAME}"
echo "[entrypoint] Tunnel URL: ${CF_URL}"
echo "[entrypoint] Модель будет доступна по: ${CF_URL}/v1/chat/completions"

# 2) Копируем .gguf-модель
echo "[entrypoint] Ищем модель в /workspace…"
MODEL_SRC=$(ls /workspace/*.gguf 2>/dev/null | head -n1)
if [ -z "$MODEL_SRC" ]; then
  echo "❌ ERROR: не найден *.gguf в /workspace"
  exit 1
fi
echo "[entrypoint] Модель найдена: $MODEL_SRC"
mkdir -p /models
cp "$MODEL_SRC" /models/model.gguf
echo "✅ Скопировали модель в /models/model.gguf"

# 3) Запускаем FastAPI
echo "[entrypoint] Запускаем сервер uvicorn на ${PORT}…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT}" \
     --workers "${WORKERS}"
