# 0) Базовый образ
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ARG PORT=8000 WORKERS=1
ENV PORT=${PORT} WORKERS=${WORKERS}

# 1) Системные зависимости + апгрейд pip
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential git cmake ninja-build wget curl unzip \
      python3 python3-pip python3-dev \
      libopenblas-dev libssl-dev zlib1g-dev libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip

# 2) Cloudflared
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) Сборка и установка llama-cpp-python с поддержкой CUDA
WORKDIR /app
COPY llama-cpp-python-main ./llama-cpp-python

# 3a) Собираем C++-движок с CUDA
WORKDIR /app/llama-cpp-python/vendor/llama.cpp
RUN cmake -B build -DGGML_CUDA=on . && \
    cmake --build build --parallel 2

# 3b) Устанавливаем Python-модуль, связанный с уже собранным C++
WORKDIR /app/llama-cpp-python
RUN FORCE_CMAKE=1 pip install . --no-cache-dir

# 4) Устанавливаем остальные зависимости
WORKDIR /app
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests

# 5) Копируем код приложения и точку входа
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

# 6) Папка для модели
RUN mkdir -p /models

# 7) Порт и запуск
EXPOSE ${PORT}
ENTRYPOINT ["./entrypoint.sh"]
