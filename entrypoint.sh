#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh…"

# 0) Проверяем обязательные переменные
: "${CF_TUNNEL_TOKEN:?ERROR: нужно задать CF_TUNNEL_TOKEN}"
: "${CF_HOSTNAME:?ERROR: нужно задать CF_HOSTNAME (например your.subdomain.chipillm.uk)}"
PORT="${PORT:-8000}"
WORKERS="${WORKERS:-1}"

# 1) Старт Cloudflare Tunnel (через токен, без явного --hostname)
echo "[entrypoint] Старт cloudflared Quick Tunnel"
nohup cloudflared tunnel run LLM_RUNPOD\
  --no-autoupdate \
  --url "http://localhost:${PORT}" \
  > /tmp/cloudflared.log 2>&1 &
# 1.1) Даем несколько секунд на инициализацию
sleep 2

# 1.2) Для отладки: выводим последние строки лога cloudflared
echo "[entrypoint] Последние строки лога cloudflared:"
tail -n 20 /tmp/cloudflared.log || true

# 1.3) Выводим help по команде tunnel run
echo "[entrypoint] Вывод cloudflared tunnel run --help:"
cloudflared tunnel run --help > /tmp/cloudflared-help.log 2>&1 || true
tail -n 30 /tmp/cloudflared-help.log || true

# 2) Собираем публичный URL
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

# 4) Запускаем FastAPI/Uvicorn
echo "[entrypoint] Запускаем uvicorn на порту ${PORT}…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT}" \
     --workers "${WORKERS}"
