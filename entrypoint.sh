#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh…"

# 0) Проверяем обязательные переменные
: "${CF_TUNNEL_TOKEN:?ERROR: нужно задать CF_TUNNEL_TOKEN}"
: "${CF_HOSTNAME:?ERROR: нужно задать CF_HOSTNAME (например your.subdomain.chipillm.uk)}"
PORT="${PORT:-8000}"
WORKERS="${WORKERS:-1}"

# 1) Старт Cloudflare Tunnel (через токен, без явного --hostname)
echo "[entrypoint] Старт cloudflared с токеном туннеля"
nohup cloudflared tunnel run \
    --no-autoupdate \
    --token "${CF_TUNNEL_TOKEN}" \
    --url "http://localhost:${PORT}" \
    > /tmp/cloudflared.log 2>&1 &

# даём пару секунд, чтобы cloudflared успел инициализироваться
sleep 2

# 1.1) Для отладки сразу смотрим, что внутри лога:
echo "[entrypoint] Последние строки лога cloudflared:"
tail -n 20 /tmp/cloudflared.log || true

# 2) Логический URL (из панели Cloudflare)
CF_URL="https://${CF_HOSTNAME}"
echo "[entrypoint] Tunnel URL (как в панели): ${CF_URL}"
echo "[entrypoint] Модель доступна по: ${CF_URL}/v1/chat/completions"

# 3) Копируем .gguf-модель из примонтированного volume
echo "[entrypoint] Ищем модель в /workspace…"
MODEL_SRC=$(ls /workspace/*.gguf 2>/dev/null | head -n1)
if [ -z "$MODEL_SRC" ]; then
  echo "❌ ERROR: не найден *.gguf в /workspace"
  exit 1
fi
echo "[entrypoint] Модель найдена: $MODEL_SRC"
cp "$MODEL_SRC" /models/model.gguf
echo "✅ Модель скопирована в /models/model.gguf"

# 4) Запускаем FastAPI
echo "[entrypoint] Запускаем uvicorn на порту ${PORT}…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT}" \
     --workers "${WORKERS}"
