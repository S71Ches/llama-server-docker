FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    nano \
    cmake \
    gcc \
    g++ \
    libopenblas-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    python3-pip

# Клонируем llama.cpp
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git .
RUN git submodule update --init --recursive

# Сборка с поддержкой CUDA
RUN cmake -DGGML_CUDA=on . && cmake --build . --verbose

# Создаём том и открываем порт
VOLUME ["/models"]
EXPOSE 8000

# Команда запуска
CMD ["./server", "-m", "/models/model.gguf", "--port", "8000"]
