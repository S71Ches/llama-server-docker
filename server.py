from fastapi import FastAPI
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()

# Загружаем модель
llm = Llama(model_path="/models/model.gguf")

# Возвращаем текущую ngrok-ссылку
@app.get("/ngrok-url")
def get_ngrok_url():
    try:
        with open("/workspace/api_url.txt", "r") as f:
            url = f.read().strip()
        return {"url": url}
    except FileNotFoundError:
        return {"error": "ngrok url not ready yet"}

# Основной чат-эндпоинт
class ChatRequest(BaseModel):
    messages: list[dict]

@app.post("/v1/chat/completions")
def chat(req: ChatRequest):
    prompt = "\n".join(f"{m['role']}: {m['content']}" for m in req.messages)
    res = llm(prompt=prompt, max_tokens=128)
    text = res["choices"][0]["text"]
    return {"choices":[{"message":{"role":"assistant","content":text}}]}
