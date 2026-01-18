#!/usr/bin/env bash
set -e
shopt -s nocasematch

########################################
# Konfigurasi
########################################

MODEL_DIR="/models"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen2-VL-2B-Instruct-Q4_K_M.gguf}"
MMPROJ_FILENAME="${MMPROJ_FILENAME:-mmproj-Qwen2-VL-2B-mmproj-q5_1.gguf}"

HF_REPO="${HF_REPO:-second-state/Qwen2-VL-2B-Instruct-GGUF}"

MODEL_PATH="$MODEL_DIR/$MODEL_FILENAME"
MMPROJ_PATH="$MODEL_DIR/$MMPROJ_FILENAME"

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
# Download model GGUF
########################################

mkdir -p "$MODEL_DIR"

if [ ! -s "$MODEL_PATH" ]; then
  echo "⬇️ Download model: $MODEL_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MODEL_URL" -o "$MODEL_PATH"
fi

########################################
# Download mmproj
########################################

if [ ! -s "$MMPROJ_PATH" ]; then
  echo "⬇️ Attempting download mmproj: $MMPROJ_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MMPROJ_URL" -o "$MMPROJ_PATH" || true
fi

########################################
# Vulkan Debug (Optional)
########################################

echo "🔧 Debug Vulkan..."
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo | grep -E "GPU id|deviceName|vendorID" || \
    echo "⚠️ Vulkan installed but no hardware devices detected"
fi

########################################
# Validasi mmproj
########################################

VALID_MMPROJ=false
if [ -f "$MMPROJ_PATH" ] && [ -s "$MMPROJ_PATH" ]; then
  # Cek header magic GGUF
  MAGIC=$(head -c 4 "$MMPROJ_PATH" 2>/dev/null || echo "")
  if [ "$MAGIC" = "GGUF" ]; then
    echo "✅ Valid mmproj found: $MMPROJ_PATH"
    VALID_MMPROJ=true
  else
    echo "⚠️ mmproj invalid format, will skip multimodal: $MMPROJ_PATH"
  fi
else
  echo "⚠️ mmproj not found, image support disabled"
fi

########################################
# Jalankan llama-server
########################################

CMD="/app/llama-server -m \"$MODEL_PATH\""

if $VALID_MMPROJ; then
  CMD="$CMD --mmproj \"$MMPROJ_PATH\""
fi

CMD="$CMD --host 0.0.0.0 --port 11444 --n-gpu-layers 100 -c 102400 -n 8192 --threads 20 --parallel 5"

echo "🚀 Starting llama-server"
exec bash -c "$CMD"
