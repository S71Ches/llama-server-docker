FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 1) Системные зависимости
RUN apt-get update && apt-get install -y \
      build-essential git curl wget cmake \
      libopenblas-dev libssl-dev zlib1g-dev \
      libcurl4-openssl-dev \
      python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2) Копируем в контейнер весь llama.cpp как «vendored» исходники
WORKDIR /app
COPY llama.cpp ./llama.cpp

# 3) Собираем с CUDA, отключая CURL
WORKDIR /app/llama.cpp
RUN cmake -B build \
      -DGGML_CUDA=ON \
      -DLLAMA_CURL=OFF \
      . && \
    cmake --build build --parallel

# 4) Готовим папку под модель и точку входа
WORKDIR /app
RUN mkdir -p /models

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
