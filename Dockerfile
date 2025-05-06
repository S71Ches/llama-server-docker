# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential git curl wget cmake \
    gcc g++ libopenblas-dev libssl-dev \
    zlib1g-dev libcurl4-openssl-dev \
    python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# 3) Клонируем llama.cpp и собираем с поддержкой CUDA (без CURL)
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    git submodule update --init --recursive && \
    cmake -DGGML_CUDA=on . && \
    make -j1

# 4) Готовим папку под модели и порт
RUN mkdir -p /models
VOLUME ["/models"]
EXPOSE 8000

# 5) Копируем скрипт entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 6) Точка входа
ENTRYPOINT ["/entrypoint.sh"]
