# Dockerfile

# 1) Базовый образ с CUDA
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 2) Системные штуки + Python server
RUN apt-get update && apt-get install -y \
      build-essential git wget curl python3 python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir \
        llama-cpp-python  \
        fastapi uvicorn[standard]

WORKDIR /app

# 3) Копируем точку входа
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4) Открываем порт
EXPOSE 8000

# 5) Запускаем наш скрипт
ENTRYPOINT ["/entrypoint.sh"]
