# RunPod公式のComfyUIベースイメージを使用
FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

# ワーキングディレクトリを移動してComfyUIを新規クローン
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# 依存パッケージのインストール
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# サーバーレス起動用コマンド
WORKDIR /
CMD ["python", "-u", "/handler.py"]
