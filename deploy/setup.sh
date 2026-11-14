#!/bin/bash
# EC2 で最初に1回だけ実行する：Nginx・systemd の設定を置いて、自動起動を有効にする
# 使い方（EC2 の中で）：sudo bash ~/temple-reservation/deploy/setup.sh
set -euo pipefail
cd "$(dirname "$0")"

install -m 644 nginx/temple-reservation.conf /etc/nginx/conf.d/temple-reservation.conf
install -m 644 systemd/temple-backend.service /etc/systemd/system/temple-backend.service
install -m 644 systemd/temple-frontend.service /etc/systemd/system/temple-frontend.service

nginx -t
systemctl daemon-reload
systemctl enable nginx temple-backend temple-frontend
systemctl restart nginx
echo "setup done"
