FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 1) Системные инструменты + Python / pip
RUN apt-get update && \
    apt-get install -y \
      build-essential git wget curl \
      python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# 2) Устанавливаем Python-зависимости в кавычках
RUN pip3 install --no-cache-dir \
      llama-cpp-python \
      fastapi \
      "uvicorn[standard]"

WORKDIR /app
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
