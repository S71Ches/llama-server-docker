FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Зависимости
RUN apt-get update && apt-get install -y \
    git curl nano wget build-essential cmake gcc g++ \
    libopenblas-dev libssl-dev zlib1g-dev libcurl4-openssl-dev \
    python3 python3-pip

# llama.cpp + сборка с CUDA
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    git submodule update --init --recursive && \
    cmake -DLLAMA_CUDA=on . && make -j2

# Папка и порт
RUN mkdir -p /models
EXPOSE 8000
VOLUME ["/models"]

# Копируем entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
