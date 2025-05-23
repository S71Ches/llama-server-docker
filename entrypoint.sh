#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh…"

# 0) Проверяем обязательные переменные
: "${CF_HOSTNAME:?ERROR: нужно задать CF_HOSTNAME (например uncensoredone.chipillm.uk)}"
PORT="${PORT:-8001}"
WORKERS="${WORKERS:-1}"

# 1) Старт cloudflared в фоне (config-mode)
echo "[entrypoint] Старт cloudflared (config-mode)…"
cloudflared tunnel --cred-file /workspace/.cloudflared/credentials.json run LLM_RUNPOD \
  > /tmp/cloudflared.log 2>&1 &

sleep 3

# 1.1) Показываем последние 100 строк логов cloudflared
echo "[entrypoint] логи cloudflared:"
tail -n 100 /tmp/cloudflared.log || true

# 2) Публикуем URL из панели Cloudflare
CF_URL="https://${CF_HOSTNAME}"
echo "[entrypoint] Tunnel URL: ${CF_URL}"
echo "[entrypoint] Модель доступна по: ${CF_URL}/v1/chat/completions"

# 3) Копируем .gguf-модель из монтированного volume
echo "[entrypoint] Ищем модель в /workspace…"
MODEL_SRC=$(ls /workspace/*.gguf 2>/dev/null | head -n1)
if [ -z "$MODEL_SRC" ]; then
  echo "❌ ERROR: не найден файл *.gguf в /workspace"
  exit 1
fi
echo "[entrypoint] Модель найдена: $MODEL_SRC"
cp "$MODEL_SRC" /models/model.gguf
echo "✅ Модель скопирована в /models/model.gguf"

# 4) Запускаем FastAPI/Uvicorn как основной процесс
echo "[entrypoint] Запускаем uvicorn на порту ${PORT}…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT}" \
     --workers "${WORKERS}"
