from fastapi import FastAPI
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()
llm = Llama(model_path="/models/model.gguf")

class ChatRequest(BaseModel):
    messages: list[dict]

@app.post("/v1/chat/completions")
def chat(req: ChatRequest):
    # только пример, делайте по spec openai
    prompt = "\n".join([f"{m['role']}: {m['content']}" for m in req.messages])
    res = llm(prompt=prompt, max_tokens=128)
    return {"choices": [{"message": {"role": "assistant", "content": res["choices"][0]["text"]}}]}
