# 0) CUDA-base image
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ARG PORT=8000
ARG WORKERS=1
ENV PORT=${PORT} WORKERS=${WORKERS}

# 0.1) Переключаем APT на HTTPS-репозитории (чтобы не было 403)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https ca-certificates && \
    sed -i \
      -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
      -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' \
      /etc/apt/sources.list && \
    rm -rf /var/lib/apt/lists/*

# 1.0) Репозиторий universe
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository universe && \
    rm -rf /var/lib/apt/lists/*

# 1) Системные зависимости + апгрейд pip/setuptools/wheel + ccache + cuda-drivers
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential git cmake ninja-build wget curl unzip \
      python3 python3-pip python3-dev \
      libopenblas-dev libssl-dev zlib1g-dev libcurl4-openssl-dev \
      ccache cuda-drivers && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip setuptools wheel

# 2) Cloudflared для туннеля
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) Клонируем llama-cpp-python со всеми сабмодулями
RUN git clone --recurse-submodules \
      https://github.com/abetlen/llama-cpp-python.git \
      /app/llama-cpp-python

# 3b) Сборка llama-cpp-python с CUDA, ccache, параллелизм = 4, и линковка -lcuda без правки CMakeLists
WORKDIR /app/llama-cpp-python
ENV CMAKE_ARGS="-DGGML_CUDA=ON \
    -DGGML_CCACHE=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_SHARED_LINKER_FLAGS=-lcuda" \
    CMAKE_BUILD_PARALLEL_LEVEL=4 \
    MAKEFLAGS="-j4" \
    FORCE_CMAKE=1
RUN pip3 install . --no-cache-dir --verbose

# 4) Остальные зависимости приложения
WORKDIR /app
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests

# 5) Копируем сервер и entrypoint
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

# 6) Папка для моделей
RUN mkdir -p /models

# 7) Порт и точка входа
EXPOSE ${PORT}
ENTRYPOINT ["./entrypoint.sh"]
