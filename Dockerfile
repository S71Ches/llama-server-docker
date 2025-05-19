# 0) Базовый образ и параметры сборки
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ARG PORT=8000
ARG WORKERS=1
ENV PORT=${PORT}
ENV WORKERS=${WORKERS}

# 1) Системные зависимости
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential git cmake ninja-build wget curl unzip \
      python3 python3-pip python3-dev \
      libopenblas-dev libssl-dev zlib1g-dev libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2) Установим cloudflared (Cloudflare Tunnel client)
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) Собираем llama-server (C++ сервер)
WORKDIR /app/llama.cpp
COPY llama.cpp ./
RUN cmake -B build -DGGM_CUDA=ON -DLLAMA_CURL=ON . \
 && cmake --build build --parallel 2 --target llama-server

# 4) Python-окружение
WORKDIR /app
RUN pip3 install --no-cache-dir \
      llama-cpp-python fastapi uvicorn[standard] requests

# 5) Копируем точку входа и заготовки для модели
RUN mkdir -p /models
COPY server.py /app/server.py
COPY entrypoint.sh /entrypoint.sh
COPY ./cloudflared/credentials.json  /etc/cloudflared/credentials.json
COPY ./cloudflared/config.yaml      /etc/cloudflared/config.yaml
RUN chmod +x /entrypoint.sh

# 6) Экспортируем порт из аргумента и стартуем entrypoint
EXPOSE ${PORT}
ENTRYPOINT ["/entrypoint.sh"]
