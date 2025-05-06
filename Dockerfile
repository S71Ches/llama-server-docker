FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    git cmake build-essential wget curl nano \
    libopenblas-dev libssl-dev zlib1g-dev python3 python3-pip

# Скачиваем llama.cpp
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git .
RUN git submodule update --init --recursive

# Компилируем с CUDA
RUN LLAMA_CUBLAS=1 make

# Открываем порт и задаём директорию с моделью
EXPOSE 8000
VOLUME ["/models"]

# Запуск сервера (при необходимости подправим позже)
CMD ["./server", "-m", "/models/model.gguf", "--port", "8000"]
