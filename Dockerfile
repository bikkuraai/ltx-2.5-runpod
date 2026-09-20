# ベースイメージ
FROM runpod/worker-comfyui:latest

USER root

# 環境変数の設定 (Model Cacheおよびメモリ管理の最適化)
ENV HF_HOME=/runpod-volume/huggingface-cache
ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1
ENV PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

# 必須パッケージとツールの導入
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    ffmpeg \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# LTX-2.5用ノードの導入
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && \
    pip install --no-cache-dir -r requirements.txt
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    pip install --no-cache-dir -r requirements.txt

WORKDIR /

# 起動ラッパースクリプトの生成
RUN cat << 'EOF' > /start_wrapper.sh
#!/bin/bash
set -e
echo "[Wrapper] Starting ComfyUI initialization sequence..."

# 1. 大文字小文字を厳密に合わせたキャッシュルート定義
MODEL_ORG="Lightricks"
MODEL_REPO="LTX-2.5"
CACHE_ROOT="/runpod-volume/huggingface-cache/hub/models--${MODEL_ORG}--${MODEL_REPO}"

if [ ! -d "${CACHE_ROOT}" ]; then
    echo "[Error] Model cache directory not found: ${CACHE_ROOT}"
    exit 1
fi

# 2. 最新スナップショットの動的解決
REF_FILE="${CACHE_ROOT}/refs/main"
if [ ! -f "${REF_FILE}" ]; then
    echo "[Error] refs/main not found."
    exit 1
fi

SNAPSHOT_HASH=$(cat "${REF_FILE}")
SNAPSHOT_DIR="${CACHE_ROOT}/snapshots/${SNAPSHOT_HASH}"

if [ ! -d "${SNAPSHOT_DIR}" ]; then
    echo "[Error] Snapshot directory does not exist: ${SNAPSHOT_DIR}"
    exit 1
fi

COMFY_MODEL_DIR="/comfyui/models"
mkdir -p ${COMFY_MODEL_DIR}/diffusion_models \
         ${COMFY_MODEL_DIR}/text_encoders \
         ${COMFY_MODEL_DIR}/vae \
         ${COMFY_MODEL_DIR}/latent_upscale_models \
         ${COMFY_MODEL_DIR}/upscale_models

echo "[Wrapper] Creating symlinks for specific LTX-2.5 components..."

# Diffusion Model
if ls ${SNAPSHOT_DIR}/*transformer*.safetensors 1> /dev/null 2>&1; then
    ln -sf ${SNAPSHOT_DIR}/*transformer*.safetensors ${COMFY_MODEL_DIR}/diffusion_models/
fi

# Text Encoder
if ls ${SNAPSHOT_DIR}/gemma4*.safetensors 1> /dev/null 2>&1; then
    ln -sf ${SNAPSHOT_DIR}/gemma4*.safetensors ${COMFY_MODEL_DIR}/text_encoders/
fi

# VAE
if [ -d "${SNAPSHOT_DIR}/vae" ]; then
    ln -sf ${SNAPSHOT_DIR}/vae/*.safetensors ${COMFY_MODEL_DIR}/vae/
fi

# Latent Upscaler (ComfyUIの認識漏れを防ぐため両フォルダへリンク)
if [ -d "${SNAPSHOT_DIR}/latent_upscale_models" ]; then
    ln -sf ${SNAPSHOT_DIR}/latent_upscale_models/*.safetensors ${COMFY_MODEL_DIR}/latent_upscale_models/
    ln -sf ${SNAPSHOT_DIR}/latent_upscale_models/*.safetensors ${COMFY_MODEL_DIR}/upscale_models/
fi

echo "[Wrapper] Initialization complete. Starting ComfyUI..."
exec /start.sh
EOF

RUN chmod +x /start_wrapper.sh

CMD ["/start_wrapper.sh"]
