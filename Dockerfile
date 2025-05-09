FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# 1) Системные зависимости + Python headers
RUN apt-get update && \
    apt-get install -y \
      build-essential git wget curl \
      python3 python3-pip python3-dev cmake \
    && rm -rf /var/lib/apt/lists/*

# 2) Устанавливаем Python-зависимости
RUN pip3 install --no-cache-dir \
      llama-cpp-python \
      fastapi \
      'uvicorn[standard]'

# дальше ваши шаги по копированию entrypoint и пр.
WORKDIR /app
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
