# 0) CUDA-base image
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ARG PORT=8000
ARG WORKERS=1
ENV PORT=${PORT} WORKERS=${WORKERS}

# 1) enable universe + core tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository universe && \
    apt-get install -y \
        build-essential git cmake ninja-build wget curl unzip \
        python3 python3-pip python3-dev \
        libopenblas-dev libssl-dev zlib1g-dev libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip setuptools wheel

# 2) Cloudflared
RUN wget -q \
      https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) clone llama-cpp-python
RUN git clone --recurse-submodules \
      https://github.com/abetlen/llama-cpp-python.git \
      /app/llama-cpp-python

# 3a) build & install llama_cpp_python with CUDA
WORKDIR /app/llama-cpp-python

# прокидываем единственный флаг для CUDA
ENV CMAKE_ARGS="-DGGML_CUDA=ON"

# FORCE_CMAKE=1 заставляет pip вызвать cmake даже если найдёт старую сборку
RUN FORCE_CMAKE=1 pip install . --no-cache-dir

# 4) остальные зависимости приложения
WORKDIR /app
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests

# 5) копируем сервер
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

# 6) папка под модели
RUN mkdir -p /models

# 7) порт и точка входа
EXPOSE ${PORT}
ENTRYPOINT ["./entrypoint.sh"]
