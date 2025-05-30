# 0) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ARG PORT=8000
ARG WORKERS=1
ENV PORT=${PORT} WORKERS=${WORKERS}

# 1.0) Включаем репозиторий universe
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository universe && \
    rm -rf /var/lib/apt/lists/*

# 1) Системные зависимости + апгрейд pip
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential git cmake ninja-build wget curl unzip \
        python3 python3-pip python3-dev \
        libopenblas-dev libssl-dev zlib1g-dev libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip

# 2) Cloudflared для туннеля
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) Клонируем llama-cpp-python сразу из GitHub со всеми сабмодулями
RUN git clone --recurse-submodules https://github.com/abetlen/llama-cpp-python.git /app/llama-cpp-python

# 3a) Устанавливаем Python-модуль с поддержкой CUDA
WORKDIR /app/llama-cpp-python
RUN FORCE_CMAKE=1 \
    CMAKE_ARGS="-DLLAMA_CUBLAS=on -GUnix\ Makefiles -DPYTHON_EXECUTABLE=$(which python3)" \
    pip install . --no-cache-dir --no-build-isolation

# 4) Устанавливаем остальные зависимости приложения
WORKDIR /app
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests

# 5) Копируем код сервера и точку входа
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

# 6) Папка для модели
RUN mkdir -p /models

# 7) Экспорт порта и запуск
EXPOSE ${PORT}
ENTRYPOINT ["./entrypoint.sh"]
