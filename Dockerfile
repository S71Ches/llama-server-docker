# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Системные зависимости (включая CURL)
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      git \
      wget \
      curl \
      cmake \
      ninja-build \
      libopenblas-dev \
      libssl-dev \
      zlib1g-dev \
      libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 3) Копируем «vendored» llama.cpp
WORKDIR /app
COPY llama.cpp ./llama.cpp

# 4) Собираем только llama-server с CUDA и CURL
WORKDIR /app/llama.cpp
RUN cmake -B build \
      -DGGM_CUDA=ON \
      -DLLAMA_CURL=ON \
      . && \
    cmake --build build \
      --parallel 2 \
      --target llama-server

# 5) Копируем entrypoint и делаем его исполняемым
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 6) Открываем порт и задаём точку входа
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
