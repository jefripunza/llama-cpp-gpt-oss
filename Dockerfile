FROM ghcr.io/ggml-org/llama.cpp:server

RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /models

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 11444
ENTRYPOINT ["/entrypoint.sh"]
