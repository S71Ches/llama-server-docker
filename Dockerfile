FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    nano \
    cmake \
    gcc \
    g++ \
    libopenblas-dev \
    libssl-dev \
    zlib1g-dev \
    python3 \
    python3-pip

# Клонируем llama.cpp
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git . \
 && git submodule update --init --recursive

# Сборка с поддержкой CUDA
RUN cmake -DLLAMA_CUBLAS=on . && cmake --build . --verbose

# Создаем том и открываем порт
VOLUME ["/models"]
EXPOSE 8000

# Пока не запускаем сервер, чтобы можно было залезть в контейнер
CMD ["tail", "-f", "/dev/null"]
