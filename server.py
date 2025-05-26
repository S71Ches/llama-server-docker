import os
from fastapi import FastAPI
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()

# 1) Загружаем модель с GPU
llm = Llama(
    model_path="/models/model.gguf",
    n_gpu_layers=64,
    f16_kv=True
)

# 2) Health-check
@app.get("/")
def root():
    return {"message": "Модель загружена и готова!"}

# 3) Чат
class ChatRequest(BaseModel):
    messages: list[dict]

@app.post("/v1/chat/completions")
def chat(req: ChatRequest):
    prompt = "\n".join(f"{m['role']}: {m['content']}" for m in req.messages)
    res = llm(prompt=prompt, max_tokens=128)
    return {"choices": [{"message": {"role": "assistant", "content": res["choices"][0]["text"]}}]}
