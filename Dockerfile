# 1. Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2. Установка зависимостей (curl, cmake и т.д.)
RUN apt-get update && apt-get install -y \
    build-essential git curl wget cmake \
    gcc g++ libopenblas-dev libssl-dev \
    zlib1g-dev libcurl4-openssl-dev \
    python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# 3. Скачиваем и компилируем llama.cpp с поддержкой CUDA + CURL
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    git submodule update --init --recursive && \
    cmake -DGGML_CUDA=on -DGGML_CURL=on . && \
    make -j$(nproc)

# 4. Папка для моделей и expose-порт
RUN mkdir -p /models
VOLUME ["/models"]
EXPOSE 8000

# 5. Копируем скрипт старта и делаем его исполняемым
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 6. Точка входа
ENTRYPOINT ["/entrypoint.sh"]
