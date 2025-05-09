# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Системные зависимости, в том числе dev-пакет для CURL
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      git \
      wget \
      curl \
      cmake \
      ninja-build \
      python3 \
      python3-pip \
      python3-dev \
      libopenblas-dev \
      libssl-dev \
      zlib1g-dev \
      libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 3) Копируем «vendored» llama.cpp для сборки сервера (если он нужен)
WORKDIR /app
COPY llama.cpp ./llama.cpp

# 4) Собираем бинарник llama-server с CUDA
WORKDIR /app/llama.cpp
RUN cmake -B build \
      -DGGM_CUDA=ON \
      -DLLAMA_CURL=ON \
      . && \
    cmake --build build --parallel 2 --target llama-server

# 5) Устанавливаем Python-зависимости (сборка llama-cpp-python через CMake+Ninja)
WORKDIR /app
RUN pip3 install --no-cache-dir \
      llama-cpp-python \
      fastapi \
      "uvicorn[standard]"

# 6) Копируем и делаем исполняемым entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 7) Экспонируем порт и запускаем entrypoint
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
