FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    git cmake build-essential wget curl nano \
    libopenblas-dev libssl-dev zlib1g-dev python3 python3-pip

# Клонируем llama.cpp
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git .
RUN git submodule update --init --recursive

# Компиляция с поддержкой CUDA
RUN cmake -DLLAMA_CUBLAS=on . && make -j

# Открываем порт и задаём директорию с моделью
EXPOSE 8000
VOLUME ["/models"]

# Запуск сервера
CMD ["./server", "-m", "/models/model.gguf", "--port", "8000"]
