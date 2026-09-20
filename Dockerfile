# ベースイメージ (latestではなく、成功実績のあるバージョンを直接指定)
FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

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

# 起動ラッパースクリプトの生成 (大文字・小文字両対応版)
RUN printf '#!/bin/bash\n\
set -e\n\
echo "[Wrapper] Starting ComfyUI initialization sequence..."\n\
\n\
# 大文字・小文字のどちらでマウントされても自動検知する\n\
if [ -d "/runpod-volume/huggingface-cache/hub/models--Lightricks--LTX-2.5" ]; then\n\
    CACHE_ROOT="/runpod-volume/huggingface-cache/hub/models--Lightricks--LTX-2.5"\n\
elif [ -d "/runpod-volume/huggingface-cache/hub/models--lightricks--ltx-2.5" ]; then\n\
    CACHE_ROOT="/runpod-volume/huggingface-cache/hub/models--lightricks--ltx-2.5"\n\
else\n\
    echo "[Error] Model cache directory not found in either case-style."\n\
    exit 1\n\
fi\n\
echo "[Wrapper] Using cache directory: ${CACHE_ROOT}"\n\
\n\
REF_FILE="${CACHE_ROOT}/refs/main"\n\
if [ ! -f "${REF_FILE}" ]; then\n\
    echo "[Error] refs/main not found."\n\
    exit 1\n\
fi\n\
SNAPSHOT_HASH=$(cat "${REF_FILE}")\n\
SNAPSHOT_DIR="${CACHE_ROOT}/snapshots/${SNAPSHOT_HASH}"\n\
if [ ! -d "${SNAPSHOT_DIR}" ]; then\n\
    echo "[Error] Snapshot directory does not exist: ${SNAPSHOT_DIR}"\n\
    exit 1\n\
fi\n\
\n\
COMFY_MODEL_DIR="/comfyui/models"\n\
mkdir -p ${COMFY_MODEL_DIR}/diffusion_models ${COMFY_MODEL_DIR}/text_encoders ${COMFY_MODEL_DIR}/vae ${COMFY_MODEL_DIR}/latent_upscale_models ${COMFY_MODEL_DIR}/upscale_models\n\
\n\
echo "[Wrapper] Creating symlinks for specific LTX-2.5 components..."\n\
if ls ${SNAPSHOT_DIR}/*transformer*.safetensors 1> /dev/null 2>&1; then\n\
    ln -sf ${SNAPSHOT_DIR}/*transformer*.safetensors ${COMFY_MODEL_DIR}/diffusion_models/\n\
fi\n\
if ls ${SNAPSHOT_DIR}/gemma4*.safetensors 1> /dev/null 2>&1; then\n\
    ln -sf ${SNAPSHOT_DIR}/gemma4*.safetensors ${COMFY_MODEL_DIR}/text_encoders/\n\
fi\n\
if [ -d "${SNAPSHOT_DIR}/vae" ]; then\n\
    ln -sf ${SNAPSHOT_DIR}/vae/*.safetensors ${COMFY_MODEL_DIR}/vae/\n\
fi\n\
if [ -d "${SNAPSHOT_DIR}/latent_upscale_models" ]; then\n\
    ln -sf ${SNAPSHOT_DIR}/latent_upscale_models/*.safetensors ${COMFY_MODEL_DIR}/latent_upscale_models/\n\
    ln -sf ${SNAPSHOT_DIR}/latent_upscale_models/*.safetensors ${COMFY_MODEL_DIR}/upscale_models/\n\
fi\n\
if ls ${SNAPSHOT_DIR}/*upscaler*.safetensors 1> /dev/null 2>&1; then\n\
    ln -sf ${SNAPSHOT_DIR}/*upscaler*.safetensors ${COMFY_MODEL_DIR}/latent_upscale_models/\n\
    ln -sf ${SNAPSHOT_DIR}/*upscaler*.safetensors ${COMFY_MODEL_DIR}/upscale_models/\n\
fi\n\
\n\
echo "[Wrapper] Initialization complete. Starting ComfyUI..."\n\
exec /start.sh\n' > /start_wrapper.sh && chmod +x /start_wrapper.sh

CMD ["/start_wrapper.sh"]
