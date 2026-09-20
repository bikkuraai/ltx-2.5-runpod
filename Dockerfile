# ベースイメージ
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
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# LTX-2.5用ノードの導入とkorniaの互換バージョン固定
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir kornia==0.7.3
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    pip install --no-cache-dir -r requirements.txt

WORKDIR /

# 起動ラッパースクリプトの生成 (findコマンドによる再帰的検索へ修正)
RUN printf '#!/bin/bash\n\
set -e\n\
echo "[Wrapper] Starting ComfyUI initialization sequence..."\n\
\n\
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
\n\
echo "========== [DEBUG] SNAPSHOT_DIR CONTENTS =========="\n\
ls -laR "${SNAPSHOT_DIR}"\n\
echo "==================================================="\n\
\n\
COMFY_MODEL_DIR="/comfyui/models"\n\
mkdir -p ${COMFY_MODEL_DIR}/diffusion_models ${COMFY_MODEL_DIR}/text_encoders ${COMFY_MODEL_DIR}/unet ${COMFY_MODEL_DIR}/clip ${COMFY_MODEL_DIR}/vae ${COMFY_MODEL_DIR}/latent_upscale_models ${COMFY_MODEL_DIR}/upscale_models\n\
\n\
echo "[Wrapper] Creating symlinks for specific LTX-2.5 components via find command..."\n\
\n\
# UNET / Diffusion Models の再帰的リンク生成\n\
find "${SNAPSHOT_DIR}" -type f -name "*transformer*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/diffusion_models/ \\;\n\
find "${SNAPSHOT_DIR}" -type f -name "*transformer*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/unet/ \\;\n\
\n\
# Text Encoders / CLIP の再帰的リンク生成\n\
find "${SNAPSHOT_DIR}" -type f -name "gemma4*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/text_encoders/ \\;\n\
find "${SNAPSHOT_DIR}" -type f -name "gemma4*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/clip/ \\;\n\
\n\
# VAE の再帰的リンク生成\n\
find "${SNAPSHOT_DIR}" -type f -name "*vae*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/vae/ \\;\n\
\n\
# Upscaler の再帰的リンク生成\n\
find "${SNAPSHOT_DIR}" -type f -name "*upscaler*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/latent_upscale_models/ \\;\n\
find "${SNAPSHOT_DIR}" -type f -name "*upscaler*.safetensors" -exec ln -sf {} ${COMFY_MODEL_DIR}/upscale_models/ \\;\n\
\n\
echo "[Wrapper] Initialization complete. Starting ComfyUI..."\n\
exec /start.sh\n' > /start_wrapper.sh && chmod +x /start_wrapper.sh

CMD ["/start_wrapper.sh"]
