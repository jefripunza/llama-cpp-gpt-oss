#!/usr/bin/env bash
set -e
shopt -s nocasematch

########################################
# Konfigurasi
########################################

# Path tempat model GGUF akan disimpan
MODEL_DIR="/models"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen2-VL-2B-Instruct-Q4_K_M.gguf}"
MODEL_PATH="$MODEL_DIR/$MODEL_FILENAME"

# Repo Hugging Face untuk model sesuai permintaan
# Ganti dengan repo yang kamu mau, misalnya second-state/Qwen2-VL-2B-Instruct-GGUF
HF_REPO="${HF_REPO:-second-state/Qwen2-VL-2B-Instruct-GGUF}"

# URL download model
MODEL_URL="https://huggingface.co/${HF_REPO}/resolve/main/${MODEL_FILENAME}"

########################################
# Cek token Hugging Face
########################################

if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN belum diset!"
  exit 1
fi

########################################
# Download model jika belum ada
########################################

echo "📍 Target model: $HF_REPO -> $MODEL_FILENAME"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ] && [ -s "$MODEL_PATH" ]; then
  echo "✅ Model sudah ada di $MODEL_PATH, skip download"
  ls -lh "$MODEL_PATH"
else
  echo "⬇️ Mengunduh model dari Hugging Face..."
  curl -L \
    -H "Authorization: Bearer ${HF_TOKEN}" \
    "$MODEL_URL" \
    -o "$MODEL_PATH"

  if [ ! -s "$MODEL_PATH" ]; then
    echo "❌ Download gagal atau file kosong!"
    exit 1
  fi

  echo "✅ Download selesai:"
  ls -lh "$MODEL_PATH"
fi

########################################
# Debug Vulkan
########################################

echo "🔧 Mengecek Vulkan devices..."
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo | grep -E "GPU id|deviceName|vendorID" || \
    echo "⚠️ Vulkan terinstal tapi tidak ada devices yang terdeteksi"
else
  echo "⚠️ vulkaninfo tidak ditemukan — Vulkan debug tidak tersedia"
fi

########################################
# Jalankan llama-server
########################################

echo "🚀 Starting llama-server dengan model:"
echo "   - Path: $MODEL_PATH"
echo "   - Context size: 16384"

# Tampilkan versi
/app/llama-server --version || echo "⚠️ Gagal cek versi llama-server, lanjutkan..."

# Jalankan server
exec /app/llama-server \
  -m "$MODEL_PATH" \
  --n-gpu-layers 100 \
  --host 0.0.0.0 \
  --port 11444 \
  --parallel 5 \
  -c 102400 \
  -n 8192 \
  --threads 20
