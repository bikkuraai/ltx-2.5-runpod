#!/bin/bash
set -e

# RunPodのHugging Faceキャッシュディレクトリパス
HF_CACHE_DIR="/runpod-volume/huggingface-cache/hub/models--lightricks--ltx-2.5"
COMFY_MODELS_DIR="/comfyui/models"

echo "Starting dynamic symlink generation for LTX-2.5..."

# キャッシュディレクトリとrefs/mainの存在確認
if [ -d "$HF_CACHE_DIR" ] && [ -f "$HF_CACHE_DIR/refs/main" ]; then
    # refs/mainから最新のコミットハッシュを読み取る
    COMMIT_HASH=$(cat "$HF_CACHE_DIR/refs/main")
    SNAPSHOT_DIR="$HF_CACHE_DIR/snapshots/$COMMIT_HASH"
    
    if [ -d "$SNAPSHOT_DIR" ]; then
        echo "Resolved Snapshot Dir: $SNAPSHOT_DIR"
        
        # ComfyUIの各モデルディレクトリを作成（存在しない場合）
        mkdir -p "$COMFY_MODELS_DIR/unet"
        mkdir -p "$COMFY_MODELS_DIR/clip"
        mkdir -p "$COMFY_MODELS_DIR/vae"
        mkdir -p "$COMFY_MODELS_DIR/latent_upscale_models"
        
        # シンボリックリンクの強制作成 (-sfn: シンボリックリンク、上書き、ディレクトリリンクの更新)
        # 1. DiT Transformer (UNet)
        if [ -d "$SNAPSHOT_DIR/diffusion_models" ]; then
            ln -sfn "$SNAPSHOT_DIR/diffusion_models"/* "$COMFY_MODELS_DIR/unet/"
        fi
        
        # 2. Text Encoder (Gemma 4)
        if [ -d "$SNAPSHOT_DIR/text_encoders" ]; then
            ln -sfn "$SNAPSHOT_DIR/text_encoders"/* "$COMFY_MODELS_DIR/clip/"
        fi
        
        # 3. VAE (Video & Audio)
        if [ -d "$SNAPSHOT_DIR/vae" ]; then
            ln -sfn "$SNAPSHOT_DIR/vae"/* "$COMFY_MODELS_DIR/vae/"
        fi

        # 4. Upscaler (Optional)
        if [ -d "$SNAPSHOT_DIR/latent_upscale_models" ]; then
            ln -sfn "$SNAPSHOT_DIR/latent_upscale_models"/* "$COMFY_MODELS_DIR/latent_upscale_models/"
        fi
        
        echo "Symlinks successfully created."
    else
        echo "Error: Snapshot directory not found at $SNAPSHOT_DIR"
    fi
else
    echo "Warning: Hugging Face Cache or refs/main not found. Skipping symlink creation."
fi

# 最後に、DockerfileのCMDで渡された元のプロセス（rp_handler.pyなど）に処理を引き継ぐ
echo "Handing over to the main worker process..."
exec "$@"
