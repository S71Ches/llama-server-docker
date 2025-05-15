FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

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

# 3) Собираем llama-server
WORKDIR /app/llama.cpp
COPY llama.cpp ./
RUN cmake -B build -DGGM_CUDA=ON -DLLAMA_CURL=ON . \
 && cmake --build build --parallel 2 --target llama-server

# 4) Python-зависимости и рабочая директория
WORKDIR /app
RUN pip3 install --no-cache-dir llama-cpp-python fastapi uvicorn[standard]

# 5) Папка для модели и скрипт старта
RUN mkdir -p /models
COPY server.py /app/server.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
