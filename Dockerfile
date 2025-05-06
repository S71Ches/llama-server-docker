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

# Сборка с CUDA (в 2 этапа с логами)
RUN cmake -DGGML_CUDA=on . > /tmp/configure.log 2>&1 && \
    cmake --build . --verbose > /tmp/build.log 2>&1 || \
    (cat /tmp/configure.log && cat /tmp/build.log && exit 1)

# Открываем порт и создаём том
VOLUME ["/models"]
EXPOSE 8000

# Команда запуска
CMD ["./server", "-m", "/models/model.gguf", "--port", "8000"]
