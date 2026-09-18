FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

# 1. ComfyUIが期待するモデルフォルダを事前に作成
RUN mkdir -p /comfyui/models/unet && \
    mkdir -p /comfyui/models/clip && \
    mkdir -p /comfyui/models/vae && \
    mkdir -p /comfyui/models/upscale_models

# 2. RunPodキャッシュの固定パス（過去のログから取得した正確なハッシュ値）
ENV LTX_CACHE="/runpod-volume/huggingface-cache/hub/models--lightricks--ltx-2.5/snapshots/62a8fc22e70a66d03f0b2f5d76d4ebc5ba213458"

# 3. 起動を邪魔しないよう、ビルド時にショートカットだけを作成（リンク先が無くてもOK）
RUN ln -sf ${LTX_CACHE}/diffusion_models/ltx-2.5-22b-distilled-transformer-comfy-int8-convrot.safetensors /comfyui/models/unet/ && \
    ln -sf ${LTX_CACHE}/text_encoders/gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors /comfyui/models/clip/ && \
    ln -sf ${LTX_CACHE}/vae/ltx-2.5-video-vae-bf16.safetensors /comfyui/models/vae/ && \
    ln -sf ${LTX_CACHE}/vae/ltx-2.5-audio-vae-bf16.safetensors /comfyui/models/vae/ && \
    ln -sf ${LTX_CACHE}/latent_upscale_models/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors /comfyui/models/upscale_models/

# ※ ENTRYPOINT や CMD は絶対に記述しない（RunPod公式の安全な起動プロセスを維持するため）
