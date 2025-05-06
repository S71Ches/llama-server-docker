FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

RUN apt-get update && apt-get install -y \
    build-essential git curl wget cmake \
    libopenblas-dev libssl-dev zlib1g-dev \
    libcurl4-openssl-dev \
    python3 python3-pip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY llama.cpp ./llama.cpp

WORKDIR /app/llama.cpp
RUN cmake -B build -DGGM_CUDA=on . \
 && cmake --build build --parallel

WORKDIR /app
RUN mkdir -p /models
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
