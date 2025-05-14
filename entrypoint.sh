#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh …"

# ——————————————————————————————————————
# 0) Проверяем обязательные переменные
: "${NGROK_AUTHTOKEN:?ERROR: нужно задать NGROK_AUTHTOKEN}"
: "${NGROK_HOSTNAME:?ERROR: нужно задать NGROK_HOSTNAME (например mymodel.ngrok.io)}"
PORT="${PORT:-8000}"

# ——————————————————————————————————————
# 1) Сохраняем токен (ngrok автоматически читает ~/.config/ngrok/ngrok.yml)
echo "[entrypoint] Настраиваем ngrok authtoken…"
ngrok authtoken "${NGROK_AUTHTOKEN}" >/dev/null 2>&1

# ——————————————————————————————————————
# 2) Запускаем ngrok с зарезервированным доменом в фоне
echo "[entrypoint] Стартуем ngrok на ${NGROK_HOSTNAME} → localhost:${PORT}"
nohup ngrok http --hostname="${NGROK_HOSTNAME}" "${PORT}" \
     --log=stdout > /tmp/ngrok.log 2>&1 &

# Небольшая пауза, чтобы ngrok успел подняться
sleep 2

NGROK_URL="https://${NGROK_HOSTNAME}"
echo "[entrypoint] ngrok URL: ${NGROK_URL}"

# ——————————————————————————————————————
# 3) (Опционально) выводим URL в логах для вашего приложения
echo "[entrypoint] Модель будет доступна по: ${NGROK_URL}/v1/chat/completions"

# ——————————————————————————————————————
# 4) Копируем вашу модель в /models
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

# ——————————————————————————————————————
# 5) Запускаем FastAPI-сервер
echo "[entrypoint] Запускаем сервер на ${PORT}…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT}" \
     --workers "${WORKERS:-1}"
