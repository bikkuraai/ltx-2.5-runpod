FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt
