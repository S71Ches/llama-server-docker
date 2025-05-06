# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Устанавливаем все нужные зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    cmake \
    libopenblas-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

# 3) Рабочая папка для сборки llama.cpp
WORKDIR /app/llama.cpp

# 4) Собираем llama.cpp с CUDA
RUN cmake -B build -DGGM_CUDA=on . \
 && cmake --build build --parallel

# 5) Возвращаемся в корень и готовим модель и точку входа
WORKDIR /app
RUN mkdir -p /models

# 6) Копируем entrypoint и делаем его исполняемым
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 7) Открываем порт и задаём точку входа
EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
