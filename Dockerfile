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
    libcurl4-openssl-dev \
    python3 \
    python3-pip

# Скачиваем и собираем llama.cpp с поддержкой CUDA
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    git submodule update --init --recursive && \
    cmake -DGGML_CUDA=on . && make -j

# Создаём том и открываем порт
VOLUME ["/models"]
EXPOSE 8000

# Команда запуска
CMD ["./server", "-m", "/models/model.gguf", "--port", "8000"]
