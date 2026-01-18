#!/usr/bin/env bash
set -e
shopt -s nocasematch

########################################
# Konfigurasi
########################################

# Directory model
MODEL_DIR="/models"

# Nama file model GGUF
MODEL_FILENAME="${MODEL_FILENAME:-Qwen2-VL-2B-Instruct-Q4_K_M.gguf}"

# Nama file projector multimodal (mmproj)
MMPROJ_FILENAME="${MMPROJ_FILENAME:-mmproj-Qwen2-VL-2B-Instruct-f16.gguf}"

# Repo Hugging Face untuk model & mmproj
HF_REPO="${HF_REPO:-second-state/Qwen2-VL-2B-Instruct-GGUF}"

# Full path
MODEL_PATH="$MODEL_DIR/$MODEL_FILENAME"
MMPROJ_PATH="$MODEL_DIR/$MMPROJ_FILENAME"

# URLs
MODEL_URL="https://huggingface.co/${HF_REPO}/resolve/main/${MODEL_FILENAME}"
MMPROJ_URL="https://huggingface.co/${HF_REPO}/resolve/main/${MMPROJ_FILENAME}"

########################################
# Cek HF_TOKEN
########################################

if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN belum diset!"
  exit 1
fi

########################################
# Download model
########################################

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ] && [ -s "$MODEL_PATH" ]; then
  echo "✅ Model sudah ada: $MODEL_PATH"
else
  echo "⬇️ Download model: $MODEL_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MODEL_URL" -o "$MODEL_PATH"
  echo "✅ Model downloaded"
fi

########################################
# Download mmproj
########################################

if [ -f "$MMPROJ_PATH" ] && [ -s "$MMPROJ_PATH" ]; then
  echo "✅ mmproj sudah ada: $MMPROJ_PATH"
else
  echo "⬇️ Attempting download mmproj: $MMPROJ_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MMPROJ_URL" -o "$MMPROJ_PATH" || true

  if [ -f "$MMPROJ_PATH" ] && [ -s "$MMPROJ_PATH" ]; then
    echo "✅ mmproj downloaded"
  else
    echo "⚠️ mmproj not found or failed to download"
    rm -f "$MMPROJ_PATH"
  fi
fi

########################################
# Vulkan debug
########################################

echo "🔧 Debug Vulkan..."
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo | grep -E "GPU id|deviceName|vendorID" || \
    echo "⚠️ Vulkan installed but no devices found"
else
  echo "⚠️ vulkaninfo not found"
fi

########################################
# Start server
########################################

echo "🚀 Starting llama-server"
CMD="/app/llama-server -m \"$MODEL_PATH\""

if [ -f "$MMPROJ_PATH" ]; then
  CMD="$CMD --mmproj \"$MMPROJ_PATH\""
  echo "📸 Multimodal enabled with mmproj: $MMPROJ_PATH"
else
  echo "⚠️ Multimodal projector mmproj NOT available — image support disabled"
fi

CMD="$CMD --host 0.0.0.0 --port 11444 --n-gpu-layers 100 -c 102400 -n 8192 --threads 20 --parallel 5"

echo "$CMD"
exec bash -c "$CMD"
