import os
import time
import threading
import requests
from fastapi import FastAPI, Request
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()

# 1) Загружаем модель
llm = Llama(model_path="/models/model.gguf")

# 2) Порог простоя (в минутах) и перевод в секунды
INACTIVITY_MIN = int(os.getenv("INACTIVITY_MIN", "5"))
INACTIVITY_THRESHOLD = INACTIVITY_MIN * 60

# 3) Переменные окружения для управления Pod’ом
RUNPOD_POD_ID = os.getenv("RUNPOD_POD_ID")
RUNPOD_API_KEY = os.getenv("RUNPOD_API_KEY")

if not RUNPOD_POD_ID or not RUNPOD_API_KEY:
    raise RuntimeError("Не заданы RUNPOD_POD_ID или RUNPOD_API_KEY")

# 4) Время последней активности
last_activity = time.time()

# 5) Middleware для обновления времени активности при каждом запросе
@app.middleware("http")
async def update_last_activity(request: Request, call_next):
    global last_activity
    last_activity = time.time()
    return await call_next(request)

# 6) Фоновый воркер для отключения Pod’а по таймауту
def inactivity_watcher():
    headers = {"Authorization": f"Bearer {RUNPOD_API_KEY}"}
    while True:
        elapsed = time.time() - last_activity
        if elapsed > INACTIVITY_THRESHOLD:
            # Останавливаем свой Pod
            requests.post(f"https://api.runpod.io/v2/pods/{RUNPOD_POD_ID}/stop", headers=headers)
            break
        time.sleep(60)

threading.Thread(target=inactivity_watcher, daemon=True).start()

# 7) Проверочный эндпоинт
@app.get("/")
def root():
    return {"message": "Модель загружена и готова!"}

# 8) Схема запроса и основной чат-эндпоинт
class ChatRequest(BaseModel):
    messages: list[dict]

@app.post("/v1/chat/completions")
def chat(req: ChatRequest):
    prompt = "\n".join(f"{m['role']}: {m['content']}" for m in req.messages)
    res = llm(prompt=prompt, max_tokens=128)
    return {
        "choices": [
            {
                "message": {
                    "role": "assistant",
                    "content": res["choices"][0]["text"]
                }
            }
        ]
    }
