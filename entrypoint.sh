#!/usr/bin/env bash
set -e

MODEL_PATH="/models/qwen2.5-7b-instruct.gguf"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q5_k_m-00001-of-00002.gguf"

if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN is not set!"
  exit 1
fi

# Download hanya jika file belum ada atau kosong
if [ -f "$MODEL_PATH" ] && [ -s "$MODEL_PATH" ]; then
  echo "✅ Model already exists, skipping download"
  ls -lh "$MODEL_PATH"
else
  echo "⬇️ Downloading GPT-OSS-20B model..."
  mkdir -p /models

  curl -L \
    -H "Authorization: Bearer ${HF_TOKEN}" \
    "$MODEL_URL" \
    -o "$MODEL_PATH"

  echo "✅ Download complete"
  ls -lh "$MODEL_PATH"
fi

# Debug Vulkan sebelum start server
echo "🔧 Debug Vulkan devices..."
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo | grep -E "GPU id|deviceName|vendorID" || echo "⚠️ Vulkan installed but no devices found"
else
  echo "⚠️ vulkaninfo not found, cannot debug Vulkan"
fi

echo "🚀 Starting llama-server with context size 16384..."
echo "📊 Model info:"
/app/llama-server --version || echo "Version check failed"

exec /app/llama-server \
  -m "$MODEL_PATH" \
  --n-gpu-layers 100 \
  --host 0.0.0.0 \
  --port 11444 \
  --parallel 5 \
  -c 102400 \
  -n 8192 \
  --threads 20
