FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

# 改行を含んだ設定ファイルの文字列を変数として定義し、ファイルに書き出す
RUN echo "runpod_cache:" > /comfyui/extra_model_paths.yaml && \
    echo "  base_path: /runpod-volume/huggingface-cache/hub" >> /comfyui/extra_model_paths.yaml && \
    echo "  unet: models--lightricks--ltx-2.5/snapshots" >> /comfyui/extra_model_paths.yaml && \
    echo "  clip: models--lightricks--ltx-2.5/snapshots" >> /comfyui/extra_model_paths.yaml && \
    echo "  vae: models--lightricks--ltx-2.5/snapshots" >> /comfyui/extra_model_paths.yaml && \
    echo "  upscale_models: models--lightricks--ltx-2.5/snapshots" >> /comfyui/extra_model_paths.yaml
