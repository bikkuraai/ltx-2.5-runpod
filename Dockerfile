# RunPod公式のComfyUIイメージをベースにする
FROM runpod/worker-comfyui:8.1.1

# 作業場所の指定
WORKDIR /workspace/ComfyUI

# LTX-2.5用のカスタムノードをダウンロードしてインストール
RUN git clone https://github.com/kijai/ComfyUI-LTXVideo.git /workspace/ComfyUI/custom_nodes/ComfyUI-LTXVideo && \
    pip install --no-cache-dir -r /workspace/ComfyUI/custom_nodes/ComfyUI-LTXVideo/requirements.txt

# サーバーレスでリクエストを受け付けるための標準コマンドを実行
CMD ["python", "-u", "/handler.py"]
