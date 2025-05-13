#!/usr/bin/env bash
set -eo pipefail

echo "[entrypoint] Ищем модель в /workspace…"
MODEL_SRC=$(ls /workspace/*.gguf 2>/dev/null | head -n1)
if [ -z "$MODEL_SRC" ]; then
  echo "❌ ERROR: не найден .gguf в /workspace"
  exit 1
fi

echo "[entrypoint] Модель найдена: $MODEL_SRC"
mkdir -p /models
cp "$MODEL_SRC" /models/model.gguf
echo "✅ Скопировали модель в /models/model.gguf"

echo "[entrypoint] Запускаем ngrok…"
# Скачиваем ngrok v3, если нужно
if [ ! -f ./ngrok ]; then
  wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
  tar -xzf ngrok-v3-stable-linux-amd64.tgz
  chmod +x ngrok
fi

# Авторизуем ngrok (замени на свой токен)
./ngrok config add-authtoken 2wxXM6TVDdWUnybXFTHHjM6bE8J_aqJtZ2iL1yXyTJTc4GWB

# Пробрасываем порт 8000 и пишем лог
./ngrok http 8000 > ngrok.log 2>&1 &

# Ждём, пока появится public_url
echo "[entrypoint] Ждём ngrok…"
until grep -q '"public_url"' ngrok.log; do sleep 1; done

# Достаём ссылку из API
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
  | grep -oP '"public_url":"\Khttps://[^"]+')
echo "🔗 Ngrok URL: $NGROK_URL"

# Сохраняем в файл для приложения
echo "$NGROK_URL" > /workspace/api_url_gguf.txt

echo "[entrypoint] Запускаем FastAPI-сервер…"
exec uvicorn server:app \
     --host 0.0.0.0 \
     --port "${PORT:-8000}" \
     --workers "${WORKERS:-1}"
