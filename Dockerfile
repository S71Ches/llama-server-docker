# 0) Базовый образ RunPod (CUDA-библиотеки уже согласованы с хостом)
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# ------------------------------------------------------------
# 1) Аргументы и переменные окружения
# ------------------------------------------------------------
ARG PORT=8000
ARG WORKERS=1
ENV PORT=${PORT} \
    WORKERS=${WORKERS}

# ------------------------------------------------------------
# 2) Настройка APT: переключаем репозитории на HTTPS + подключаем universe
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      software-properties-common && \
    \
    # Заменяем http на https в списках репозиториев, чтобы не было 403
    sed -i \
      -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
      -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' \
      /etc/apt/sources.list && \
    \
    # Добавляем репозиторий universe для дополнительного ПО
    add-apt-repository universe && \
    \
    # Очищаем кеш apt, чтобы уменьшить размер слоя
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 3) Системные зависимости + ccache + Python (без cuda-drivers!)
# ------------------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
      ccache && \
    \
    # Очищаем кеш apt снова
    rm -rf /var/lib/apt/lists/* && \
    \
    # Обновляем pip, setuptools и wheel
    python3 -m pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------
# 4) Установка cloudflared для Cloudflare Tunnel (оставляем без изменений)
# ------------------------------------------------------------
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# ------------------------------------------------------------
# 5) Клонируем llama-cpp-python со всеми сабмодулями и собираем с поддержкой CUDA
# ------------------------------------------------------------
RUN git clone --recurse-submodules \
      https://github.com/abetlen/llama-cpp-python.git \
      /app/llama-cpp-python

WORKDIR /app/llama-cpp-python

# Сборка llama-cpp-python с флагом GGML_CUDA=ON и ccache, параллелизм = 4
# Обязательно оставляем линковку -lcuda, чтобы CUDA-вызовы работали
ENV CMAKE_ARGS="-DGGML_CUDA=ON \
    -DGGML_CCACHE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_SHARED_LINKER_FLAGS=-lcuda" \
    CMAKE_BUILD_PARALLEL_LEVEL=4 \
    MAKEFLAGS="-j4" \
    FORCE_CMAKE=1

RUN pip3 install . --no-cache-dir --verbose

# ------------------------------------------------------------
# 6) Установка дополнительных Python-зависимостей и копирование приложения
# ------------------------------------------------------------
WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn[standard] requests

# Копируем server.py и entrypoint.sh, даём права на выполнение
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

# ------------------------------------------------------------
# 7) Папка для моделей
# ------------------------------------------------------------
RUN mkdir -p /models

# ------------------------------------------------------------
# 8) Открываем порт и задаём точку входа
# ------------------------------------------------------------
EXPOSE ${PORT}
ENTRYPOINT ["./entrypoint.sh"]
