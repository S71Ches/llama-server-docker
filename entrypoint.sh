#!/usr/bin/env bash
# entrypoint.sh
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh…"

# 0) Проверяем обязательные переменные (передаются на уровне Pod)
: "${CF_TUNNEL_TOKEN:?ERROR: нужно задать CF_TUNNEL_TOKEN}"
: "${CF_HOSTNAME:?ERROR: нужно задать CF_HOSTNAME (например your.subdomain.chipillm.uk)}"
PORT="${PORT:-8000}"
WORKERS="${WORKERS:-1}"

# 1) Старт Cloudflare Tunnel
echo "[entrypoint] Старт cloudflared для ${CF_HOSTNAME} → localhost:${PORT}"
nohup cloudflared tunnel run \
    --no-autoupdate \
    --token "${CF_TUNNEL_TOKEN}" \
    --hostname "${CF_HOSTNAME}" \
    --url "http://localhost:${PORT}" \
    > /tmp/cloudflared.log 2>&1 &

# Даём ему пару секунд прогреться
sleep 2

CF_URL="https://${CF_HOSTNAME}"
echo "[entrypoint] Tunnel URL: ${CF_URL}"
echo "[entrypoint] Модель доступна по: ${CF_URL}/v1/chat/completions"

# 2) Копируем .gguf-модель
echo "[entrypoint] Ищем модель в /workspace…"
MODEL_SRC=$(ls /workspace/*.gguf 2>/dev/null | head -n1)
if [ -z "$MODEL_SRC" ]; then
  echo "❌ ERROR: не найден *.gguf в /workspace"
  exit 1
fi
echo "[entrypoint] Модель найдена: $MODEL_SRC"
cp "$MODEL_SRC" /models/model.gguf
echo "✅ Модель скопирована в /models/model.gguf"

# 3) Запускаем FastAPI
echo "[entrypoint] Запускаем uvicorn на порту ${PORT}…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT}" \
     --workers "${WORKERS}"
