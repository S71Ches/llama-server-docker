# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Устанавливаем системные зависимости
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      git \
      wget \
      curl \
      cmake \
      python3 \
      python3-pip \
      python3-dev \
      libopenblas-dev \
      libssl-dev \
      zlib1g-dev \
      libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 3) Копируем llama.cpp (vendored) и собираем бинарник llama-server
WORKDIR /app
COPY llama.cpp ./llama.cpp

WORKDIR /app/llama.cpp
RUN cmake -B build \
      -DGGM_CUDA=ON \
      -DLLAMA_CURL=ON \
      . && \
    cmake --build build --parallel 2 --target llama-server

# 4) Ставим Python-зависимости из PyPI
#    (вместо локальной сборки binding-а с помощью CMake + ninja,
#     pip найдёт готовый пакет https://pypi.org/project/llama-cpp-python/)
WORKDIR /app
RUN pip3 install --no-cache-dir \
      llama-cpp-python \
      fastapi \
      uvicorn[standard]

# 5) Копируем ваше приложение и точку входа
COPY server.py /app/server.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 6) Экспонируем порт и запускаем
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
