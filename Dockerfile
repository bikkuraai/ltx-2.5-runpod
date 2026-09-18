FROM runpod/worker-comfyui:5.10.0-base-cuda12.8.1

# スクリプトのコピーと実行権限の付与
COPY setup_links.sh /setup_links.sh
RUN chmod +x /setup_links.sh

# エントリーポイントを自作スクリプトに設定
ENTRYPOINT ["/setup_links.sh"]

# デフォルトのハンドラ起動コマンド
CMD ["python", "-u", "/rp_handler.py"]
