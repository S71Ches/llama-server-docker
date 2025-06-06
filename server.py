import os
import subprocess
import asyncio
from concurrent.futures import ThreadPoolExecutor
from fastapi import FastAPI
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI()

# ——————————————————————————————————————————————————
# 1) Получаем свободную VRAM и динамически выставляем n_gpu_layers
def get_free_vram_mb() -> int:
    try:
        out = subprocess.check_output([
            'nvidia-smi', '--query-gpu=memory.free', '--format=csv,noheader,nounits'
        ]).decode('utf-8').strip().split('\n')
        return int(out[0])  # берём первую карту
    except Exception:
        return 0

def calc_gpu_layers(free_vram_mb: int, model_size="13b", max_layers=45) -> int:
    # Примерно: 500 MB на слой для 13B Q6_K
    MB_PER_LAYER = 500
    RESERVED_MB = 3000  # запас для токенов, контекста, буферов и т.д.
    MIN_LAYERS = 8

    if free_vram_mb < RESERVED_MB:
        return 0  # GPU не трогаем

    usable = free_vram_mb - RESERVED_MB
    estimated = usable // MB_PER_LAYER
    return max(MIN_LAYERS, min(estimated, max_layers))

# Вычисляем
free_vram = get_free_vram_mb()
gpu_layers = calc_gpu_layers(free_vram)

print(f"[startup] free_vram={free_vram} MB, n_gpu_layers={gpu_layers}")

# 2) Инициализация Llama с оптимальными параметрами
llm = Llama(
    model_path="/models/model.gguf",
    n_gpu_layers=gpu_layers,
    n_ctx=4096,            # «длинная» контекстная память
    n_threads=os.cpu_count(),
    n_batch=512,
    f16_kv=True,
    use_mlock=True         # фиксируем модель в RAM
)

# В зависимости от задачи, можно сделать executor с 1 «потоком-воркером»
executor = ThreadPoolExecutor(max_workers=1)

# ——————————————————————————————————————————————————
# 3) Health-check (быстрый)
@app.get("/")
def root():
    return {"message": "Модель загружена и готова!"}

# 4) Структура запроса
class InstructionRequest(BaseModel):
    inputs: str
    
# 5) Обработчик чата (async, чтобы не блокировать event loop)
@app.post("/v1/completions")
async def instruct(req: InstructionRequest):
    prompt = req.inputs

    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(executor, lambda:
        llm(
            prompt=prompt,
            max_tokens=256,  # можно больше, если хочешь длиннее ответы
            temperature=0.7,
            top_p=0.9,
            top_k=50,
            repeat_penalty=1.1,
        )
    )

    return {
        "text": result["choices"][0]["text"]
    }
