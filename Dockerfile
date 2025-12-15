FROM ghcr.io/ggml-org/llama.cpp:server-cuda

# Install runtime deps
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update
RUN apt-get install -y ca-certificates curl tar unzip gzip
RUN apt-get install -y vulkan-tools mesa-vulkan-drivers libvulkan1
RUN rm -rf /var/lib/apt/lists/*

# Create models folder
RUN mkdir -p /models

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 11444
ENTRYPOINT ["/entrypoint.sh"]
