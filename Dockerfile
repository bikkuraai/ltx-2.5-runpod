# RunPod公式のComfyUIイメージをベースにする
FROM runpod/worker-comfyui:8.1.1

# 作業場所の指定
WORKDIR /workspace/ComfyUI/custom_nodes

# 1. LTX-2.5専用のメインノード群
RUN git clone https://github.com/kijai/ComfyUI-LTXVideo.git && \
    pip install --no-cache-dir -r ComfyUI-LTXVideo/requirements.txt

# 2. 数式やスイッチなどの便利ノード群
RUN git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/evansd/ComfyMath.git

# 3. 画像リサイズや解像度関連のノード群
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    pip install --no-cache-dir -r ComfyUI_essentials/requirements.txt && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git --recursive

# 作業場所をルートに戻して、ワーカー起動用コマンドを設定
WORKDIR /
CMD ["python", "-u", "/handler.py"]
