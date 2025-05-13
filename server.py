from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()

# загружаем GGUF-модель
llm = Llama(model_path="/models/model.gguf")

# возвращает динамическую ngrok-ссылку для GGUF-модели
@app.get("/ngrok-url-gguf")
def get_ngrok_url_gguf():
    try:
        with open("/workspace/api_url_gguf.txt", "r") as f:
            url = f.read().strip()
        return {"url": url}
    except FileNotFoundError:
        raise HTTPException(404, detail="Ngrok URL для GGUF-модели не найден")

# проверка, что сервер жив
@app.get("/")
def root():
    return {"message": "Модель загружена и готова!"}

# основной чат-эндпоинт
class ChatRequest(BaseModel):
    messages: list[dict]

@app.post("/v1/chat/completions")
def chat(req: ChatRequest):
    prompt = "\n".join(f"{m['role']}: {m['content']}" for m in req.messages)
    res = llm(prompt=prompt, max_tokens=128)
    return {
        "choices": [
            {"message": {"role": "assistant", "content": res["choices"][0]["text"]}}
        ]
    }
