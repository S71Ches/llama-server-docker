# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    cmake \
    libopenblas-dev \
    libssl-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

# 3) Копируем «vendored» llama.cpp
WORKDIR /app
COPY llama.cpp ./llama.cpp

# 4) Собираем llama.cpp с CUDA, с параллелизмом 2
WORKDIR /app/llama.cpp
RUN cmake -B build -DGGM_CUDA=ON -DLLAMA_CURL=ON . \
 && cmake --build build --parallel 2 --target llama-server

# 5) Подготавливаем папку под модель и точку входа
WORKDIR /app
RUN mkdir -p /models

# 6) Копируем entrypoint и делаем его исполняемым
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 7) Экспонируем порт и указываем точку входа
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
