# ベースイメージ
FROM runpod/worker-comfyui:latest

USER root
# 必須パッケージとFFmpegの導入
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    ffmpeg \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /comfyui/custom_nodes
# LTX-2.5生成用および動画結合用のノード導入
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && \
    pip install --no-cache-dir -r requirements.txt
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    pip install --no-cache-dir -r requirements.txt

WORKDIR /
# 動的シンボリックリンクを生成し、正規の起動プロセスへ引き継ぐラッパースクリプト
RUN echo '#!/bin/bash\n\
CACHE_DIR="/runpod-volume/huggingface-cache/hub/models--lightricks--ltx-2.5/snapshots"\n\
TARGET_DIRS=("/comfyui/models/checkpoints" "/comfyui/models/unet" "/comfyui/models/diffusion_models" "/comfyui/models/clip" "/comfyui/models/text_encoders" "/comfyui/models/vae" "/comfyui/models/upscale_models")\n\
for dir in "${TARGET_DIRS[@]}"; do mkdir -p "$dir"; done\n\
if [ -d "$CACHE_DIR" ]; then\n\
    LATEST_SNAPSHOT=$(ls -dt "$CACHE_DIR"/* | head -n 1)\n\
    if [ -n "$LATEST_SNAPSHOT" ]; then\n\
        echo "Linking models from $LATEST_SNAPSHOT..."\n\
        find "$LATEST_SNAPSHOT" -maxdepth 3 -name "*.safetensors" | while read -r filepath; do\n\
            filename=$(basename "$filepath")\n\
            for dir in "${TARGET_DIRS[@]}"; do ln -sf "$filepath" "$dir/$filename"; done\n\
        done\n\
    fi\n\
else\n\
    echo "Cache directory not found."\n\
fi\n\
exec /start.sh' > /start_wrapper.sh && chmod +x /start_wrapper.sh

# LTX-2.5用のアップスケーラーモデルを直接ダウンロードして配置
RUN mkdir -p /comfyui/models/upscale_models && \
    wget -qO /comfyui/models/upscale_models/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors \
    https://huggingface.co/ibyteohdear/Lightricks-LTX-2/resolve/main/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors

# エントリーポイントの書き換え
CMD ["/start_wrapper.sh"]
