# 0) CUDA-base image (используем нужную версию CUDA + devel-пакеты)
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Передаём порт и количество воркеров через ARG (можно переопределить при сборке)
ARG PORT=8000
ARG WORKERS=1

# Устанавливаем эти же значения в ENV для использования внутри контейнера
ENV PORT=${PORT} \
    WORKERS=${WORKERS}

# 0.1) Переключаем APT на HTTPS-репозитории (чтобы избежать 403 ошибок)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates && \
    sed -i \
      -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
      -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' \
      /etc/apt/sources.list && \
    rm -rf /var/lib/apt/lists/*

# 1.0) Подключаем репозиторий universe (если нужно дополнительное ПО)
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository universe && \
    rm -rf /var/lib/apt/lists/*

# 1) Системные зависимости + pip/setuptools/wheel + ccache + cuda-drivers
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential \
      git \
      cmake \
      ninja-build \
      wget \
      curl \
      unzip \
      python3 \
      python3-pip \
      python3-dev \
      libopenblas-dev \
      libssl-dev \
      zlib1g-dev \
      libcurl4-openssl-dev \
      ccache \
      cuda-drivers && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip setuptools wheel

# 2) Устанавливаем cloudflared для Cloudflare Tunnel
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3) Клонируем llama-cpp-python (внутри него подтягивается сабмодуль llama.cpp)
RUN git clone --recurse-submodules \
      https://github.com/abetlen/llama-cpp-python.git \
      /app/llama-cpp-python

# 3b) Сборка llama-cpp-python с поддержкой cuBLAS (GPU), ccache, параллелизм = 4
WORKDIR /app/llama-cpp-python

ENV CMAKE_ARGS="-DLLAMA_CUBLAS=on \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_CCACHE=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache" \
    CMAKE_BUILD_PARALLEL_LEVEL=4 \
    MAKEFLAGS="-j4" \
    FORCE_CMAKE=1

RUN pip3 install . --no-cache-dir --verbose

# 4) Возвращаемся в корень приложения и ставим остальные Python-зависимости
WORKDIR /app
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests

# 5) Копируем server.py и entrypoint.sh в контейнер
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

# 6) Создаём папку для моделей
RUN mkdir -p /models

# 7) Открываем порт и настраиваем точку входа
EXPOSE ${PORT}
ENTRYPOINT ["./entrypoint.sh"]
