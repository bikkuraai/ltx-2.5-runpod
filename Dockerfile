FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

RUN echo "ltx_hf_cache:" > /comfyui/ltx_paths.yaml && \
    echo "    base_path: /runpod-volume/huggingface-cache/hub/models--lightricks--ltx-2.5/snapshots/62a8fc22e70a66d03f0b2f5d76d4ebc5ba213458" >> /comfyui/ltx_paths.yaml && \
    echo "    unet: diffusion_models" >> /comfyui/ltx_paths.yaml && \
    echo "    clip: text_encoders" >> /comfyui/ltx_paths.yaml && \
    echo "    vae: vae" >> /comfyui/ltx_paths.yaml && \
    echo "    upscale_models: latent_upscale_models" >> /comfyui/ltx_paths.yaml
