#!/usr/bin/env bash
set -e
shopt -s nocasematch

########################################
# Config
########################################

MODEL_DIR="/models"

MODEL_FILENAME="${MODEL_FILENAME:-Qwen2-VL-2B-Instruct-Q4_K_M.gguf}"

# mmproj fallback sumber yang valid
MMPROJ_FILENAME="${MMPROJ_FILENAME:-Qwen2-VL-2B-mmproj-q5_1.gguf}"
MMPROJ_FALLBACK_REPO="koboldcpp/mmproj"

# Repo utama model
HF_REPO="${HF_REPO:-second-state/Qwen2-VL-2B-Instruct-GGUF}"

MODEL_PATH="$MODEL_DIR/$MODEL_FILENAME"
MMPROJ_PATH="$MODEL_DIR/$MMPROJ_FILENAME"

MODEL_URL="https://huggingface.co/${HF_REPO}/resolve/main/${MODEL_FILENAME}"
MMPROJ_URL="https://huggingface.co/${HF_REPO}/resolve/main/${MMPROJ_FILENAME}"
MMPROJ_FALLBACK_URL="https://huggingface.co/${MMPROJ_FALLBACK_REPO}/resolve/main/${MMPROJ_FILENAME}"

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

if [ ! -s "$MODEL_PATH" ]; then
  echo "⬇️ Download model: $MODEL_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MODEL_URL" -o "$MODEL_PATH"
fi

########################################
# Download mmproj (utama lalu fallback)
########################################
if [ ! -s "$MMPROJ_PATH" ]; then
  echo "⬇️ Attempting download mmproj: $MMPROJ_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MMPROJ_URL" -o "$MMPROJ_PATH" || true
fi

if [ ! -s "$MMPROJ_PATH" ]; then
  echo "⚠️ mmproj from HF_REPO not found — using fallback source"
  echo "⬇️ Download fallback mmproj: $MMPROJ_FALLBACK_URL"
  curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$MMPROJ_FALLBACK_URL" -o "$MMPROJ_PATH" || true
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
