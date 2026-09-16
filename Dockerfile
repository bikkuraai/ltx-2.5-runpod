# RunPod公式のComfyUIイメージをベースにする
FROM runpod/worker-comfyui:8.1.1

# root権限で安全にアップデートを実行する
USER root
WORKDIR /workspace/ComfyUI

# gitの安全ディレクトリ設定を追加し、競合を避けて最新版にアップデート
RUN git config --global --add safe.directory /workspace/ComfyUI && \
    git fetch origin master && \
    git reset --hard origin/master && \
    pip install --no-cache-dir -r requirements.txt

# サーバーレス起動用コマンド
WORKDIR /
CMD ["python", "-u", "/handler.py"]
