#!/usr/bin/env bash
set -e
shopt -s nocasematch

########################################
# Config
########################################

MODEL_DIR="/models"

MODEL_FILENAME="${MODEL_FILENAME:-Qwen2-VL-2B-Instruct-Q4_K_M.gguf}"

# mmproj: pakai versi f32 yang benar
MMPROJ_FILENAME="${MMPROJ_FILENAME:-mmproj-Qwen2-VL-2B-Instruct-f32.gguf}"

# Repo utama model
HF_MODEL_REPO="${HF_MODEL_REPO:-second-state/Qwen2-VL-2B-Instruct-GGUF}"

MODEL_PATH="$MODEL_DIR/$MODEL_FILENAME"
MMPROJ_PATH="$MODEL_DIR/$MMPROJ_FILENAME"

MODEL_URL="https://huggingface.co/${HF_MODEL_REPO}/resolve/main/${MODEL_FILENAME}"

# URL mmproj f32 yang valid
MMPROJ_URL="https://huggingface.co/bartowski/Qwen2-VL-2B-Instruct-GGUF/resolve/main/${MMPROJ_FILENAME}"

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
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" \
       "$MODEL_URL" -o "$MODEL_PATH"
else
  echo "✅ Model sudah ada: $MODEL_PATH"
fi

########################################
# Download mmproj f32
########################################
if [ ! -s "$MMPROJ_PATH" ]; then
  echo "⬇️ Download multimodal projector: $MMPROJ_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" \
       "$MMPROJ_URL" -o "$MMPROJ_PATH" || true
else
  echo "✅ mmproj sudah ada: $MMPROJ_PATH"
fi

########################################
# Validate mmproj
########################################
VALID_MMPROJ=false
if [ -f "$MMPROJ_PATH" ] && [ -s "$MMPROJ_PATH" ]; then
  MAGIC=$(head -c 4 "$MMPROJ_PATH" 2>/dev/null || echo "")
  if [ "$MAGIC" = "GGUF" ]; then
    echo "✅ Valid mmproj found: $MMPROJ_PATH"
    VALID_MMPROJ=true
  else
    echo "⚠️ mmproj format invalid — skip multimodal"
  fi
else
  echo "⚠️ mmproj not found or empty"
fi

########################################
# Vulkan debug (optional)
########################################
echo "🔧 Debug Vulkan..."
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo | grep -E "GPU id|deviceName|vendorID" || echo "⚠️ Vulkan installed but no devices"
fi

########################################
# Start llama-server
########################################
CMD="/app/llama-server -m \"$MODEL_PATH\""

if $VALID_MMPROJ; then
  CMD="$CMD --mmproj \"$MMPROJ_PATH\""
fi

CMD="$CMD --host 0.0.0.0 --port 11444 --n-gpu-layers 100 -c 102400 -n 8192 --threads 20 --parallel 5"

echo "🚀 Starting llama-server..."
exec bash -c "$CMD"
