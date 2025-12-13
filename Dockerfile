FROM ubuntu:22.04

# Install runtime deps
RUN apt-get update
RUN apt-get install -y ca-certificates curl tar unzip gzip
RUN apt-get install -y vulkan-utils mesa-vulkan-drivers libvulkan1
RUN rm -rf /var/lib/apt/lists/*

# Download prebuilt llama.cpp binaries
ENV LLAMA_RELEASE="b7380"
RUN mkdir -p /opt/llama && \
    cd /opt/llama && \
    curl -L \
      https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_RELEASE}/llama-${LLAMA_RELEASE}-bin-ubuntu-vulkan-x64.tar.gz \
      -o llama-${LLAMA_RELEASE}-bin.tar.gz && \
    tar -xzf llama-${LLAMA_RELEASE}-bin.tar.gz && \
    rm llama-${LLAMA_RELEASE}-bin.tar.gz

# Rename Directory
RUN mv /opt/llama /opt/llama-target
RUN mv /opt/llama-target/llama-${LLAMA_RELEASE} /opt/llama

# Check ...
# RUN ls -l /opt/llama && sleep 10

# Make sure serve binary is executable
RUN chmod +x /opt/llama/llama-server

# Create models folder
RUN mkdir -p /models

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
