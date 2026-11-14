#!/bin/bash
# EC2 でアプリを最新にする（基本設計書 9.5）
# 使い方（EC2 の中で、ec2-user で）：bash ~/temple-reservation/deploy/deploy.sh
set -euo pipefail
APP_DIR="$HOME/temple-reservation"
export PATH="/opt/ruby/bin:/usr/local/bin:$PATH"
export NEXT_TELEMETRY_DISABLED=1

echo "== 最新のコードを取得"
cd "$APP_DIR"
git pull --ff-only

echo "== バックエンド：gem のインストールと DB のマイグレーション"
cd "$APP_DIR/backend"
bundle config set --local deployment true
bundle config set --local without "development test"
bundle install --jobs 2
set -a
# shellcheck disable=SC1091
source /etc/temple-reservation/backend.env
set +a
bin/rails db:migrate

echo "== フロントエンド：パッケージのインストールとビルド"
cd "$APP_DIR/frontend"
npm ci --no-audit --no-fund
npm run build

echo "== 再起動"
sudo systemctl restart temple-backend temple-frontend
echo "deploy done"
