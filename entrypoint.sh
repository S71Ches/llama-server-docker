#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Запуск entrypoint.sh …"

# 0) Настроим токен ngrok, если есть
if [[ -n "$NGROK_AUTHTOKEN" ]]; then
  echo "[entrypoint] Настраиваем ngrok authtoken…"
  ngrok authtoken "$NGROK_TOKEN"
fi

# 1) Старт ngrok в фоне
nohup ngrok http "${PORT:-8000}" --log=stdout > /tmp/ngrok.log 2>&1 &

# 2) Ждём появление туннеля…
echo "[entrypoint] Ожидание ngrok URL…"
NGROK_URL=""
for i in {1..10}; do
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
    | jq -r '.tunnels[] | select(.proto=="https") | .public_url')
  if [[ -n "$NGROK_URL" && "$NGROK_URL" != "null" ]]; then
    break
  fi
  echo "  attempt #$i…"
  sleep 1
done

if [[ -z "$NGROK_URL" || "$NGROK_URL" == "null" ]]; then
  echo "❌ ERROR: не удалось получить ngrok URL"
  exit 1
fi
echo "[entrypoint] Получен ngrok URL: $NGROK_URL"

# 3) Отправляем уведомление в Telegram
curl -s -X POST "https://api.telegram.org/bot7773349253:AAHEE_dzUiG7tzMwfBNHt2FesGEEqE2O7M0/sendMessage" \
  -d chat_id=1273988384 \
  -d text="🟢 Модель активна: $NGROK_URL%0A⏰ Обновлено: $(date +'%Y-%m-%d %H:%M:%S')" \
  >/dev/null

# 4) Стандартная логика копирования модели
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

# 5) Запускаем FastAPI-сервер
echo "[entrypoint] Запускаем сервер на $PORT…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --workers "${WORKERS:-1}"
