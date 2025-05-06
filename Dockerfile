# базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 1) Устанавливаем все зависимости для сборки и скачивания модели
RUN apt-get update && apt-get install -y \
      build-essential \
      cmake \
      git \
      curl \
      libblas-dev \
      libssl-dev \
      zlib1g-dev \
      libcurl4-openssl-dev \
      python3 \
      python3-pip && \
    rm -rf /var/lib/apt/lists/*

# 2) Переключаемся в рабочую директорию и копируем всё содержимое репозитория
WORKDIR /app
COPY . /app

# 3) Собираем llama.cpp с CUDA и CURL (Release-сборка)
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGM_CUDA=on . && \
    cmake --build build -j$(nproc) --verbose && \
    cp build/main ./main

# 4) Готовим точку входа
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 5) Объявляем том для модели и открываем порт
VOLUME ["/models"]
EXPOSE 8000

# 6) По умолчанию запускаем наш скрипт
ENTRYPOINT ["/entrypoint.sh"]
