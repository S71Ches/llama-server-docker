# 0) Базовый образ
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

# 2) Cloudflared
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) Собираем llama.cpp с поддержкой CUDA
WORKDIR /app/llama.cpp
# вся директория с исходниками llama.cpp
COPY llama.cpp ./  
RUN cmake -B build -DGGM_CUDA=ON -DLLAMA_CURL=ON . && \
    cmake --build build --parallel 2

# 3.1) Устанавливаем Python-обвязку из этой директории
RUN pip install --no-cache-dir /app/llama.cpp

# 4) Устанавливаем Python-обвязку llama-cpp из этой же папки
RUN pip3 install --no-cache-dir .

# 5) Установка Python-зависимостей
WORKDIR /app
COPY server.py /app/server.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN pip3 install --no-cache-dir fastapi uvicorn[standard] requests

# 5.1) Создаём директорию под модель
RUN mkdir -p /models

# 6) Экспортируем порт и запускаем
EXPOSE ${PORT}
ENTRYPOINT ["/entrypoint.sh"]
