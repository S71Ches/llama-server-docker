# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# --------------------------------------------------
# 2) Системные зависимости + dev-библиотеки + ninja для сборки Python-extensions
RUN apt-get update && apt-get install -y \
      build-essential \
      git \
      wget \
      curl \
      cmake \
      ninja-build \
      python3 \
      python3-pip \
      python3-dev \
      libopenblas-dev \
      libssl-dev \
      zlib1g-dev \
      libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# 3) Копируем llama.cpp (vendored) и собираем бинарник llama-server
WORKDIR /app
COPY llama.cpp ./llama.cpp

WORKDIR /app/llama.cpp
RUN cmake -B build \
      -DGGM_CUDA=ON \
      -DLLAMA_CURL=ON \
      . && \
    cmake --build build --parallel 2 --target llama-server

# --------------------------------------------------
# 4) Устанавливаем Python-зависимости (сборка wheel для llama-cpp-python благодаря ninja)
WORKDIR /app
RUN pip3 install --no-cache-dir \
      llama-cpp-python \
      fastapi \
      uvicorn[standard]

# --------------------------------------------------
# 5) Создаём папку для модели (чтобы wget в entrypoint не падал)
RUN mkdir -p /models

# --------------------------------------------------
# 6) Копируем ваше приложение и точку входа
COPY server.py     /app/server.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --------------------------------------------------
# 7) Экспонируем порт и запускаем entrypoint
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
