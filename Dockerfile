# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Системные зависимости + dev-библиотеки для сборки wheel
RUN apt-get update && \
    apt-get install -y \
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

# 3) Копируем llama.cpp для сборки C++-модуля
WORKDIR /app
COPY llama.cpp ./llama.cpp

# 4) Собираем C++-модуль llama-cpp-python
WORKDIR /app/llama.cpp
RUN cmake -B build \
      -DLLAMA_CURL=ON \
      -DGGM_CUDA=ON \
      -DCMAKE_BUILD_TYPE=Release \
      . && \
    cmake --build build --parallel 2

# 5) Устанавливаем Python-зависимости и собранный модуль
WORKDIR /app
RUN pip3 install --no-cache-dir \
      ./llama.cpp/build/python/llama_cpp \
      fastapi \
      uvicorn[standard]

# 6) Копируем свой FastAPI-сервис (server.py) и entrypoint
COPY server.py /app/server.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
