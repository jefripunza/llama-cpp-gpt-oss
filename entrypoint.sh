#!/usr/bin/env bash
set -e

MODEL_PATH="/models/gpt-oss-20b.gguf"
MODEL_URL="https://huggingface.co/giladgd/gpt-oss-20b-GGUF/resolve/main/gpt-oss-20b.MXFP4.gguf"

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

echo "🚀 Starting llama-server..."
exec /opt/llama/llama-server \
  --host 0.0.0.0 \
  --port 9000 \
  --model "$MODEL_PATH"
