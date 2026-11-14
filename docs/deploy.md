# デプロイ手順

EC2（`infra/` の Terraform でつくったもの）に、Rails と Next.js を配置する手順です（基本設計書 9.5）。

## 構成

```
ブラウザ ──HTTP 80──▶ Nginx ─┬─ /api/・/up ─▶ Puma（Rails） 127.0.0.1:3001 ─▶ RDS（MySQL）
                             └─ それ以外 ───▶ Next.js       127.0.0.1:3000
```

| もの | 場所 |
| --- | --- |
| アプリのコード | `/home/ec2-user/temple-reservation`（GitHub から clone） |
| Nginx の設定 | `/etc/nginx/conf.d/temple-reservation.conf`（元は `deploy/nginx/`） |
| systemd の設定 | `/etc/systemd/system/temple-backend.service`・`temple-frontend.service`（元は `deploy/systemd/`） |
| 秘密の値 | `/etc/temple-reservation/backend.env`（リポジトリには入れない） |

## はじめの1回だけ

PC の `infra/` フォルダで実行します。

```bash
cd infra
IP=$(terraform output -raw public_ip)
SSH="ssh -i $HOME/.ssh/temple-ec2 ec2-user@$IP"

# 1. コードを取得する
$SSH 'git clone https://github.com/kynkt-rgb/temple-reservation.git ~/temple-reservation'

# 2. 秘密の値のファイルをつくる（パスワードは画面に出さずに渡す）
terraform output -raw db_password | $SSH "read -r P; sudo mkdir -p /etc/temple-reservation; \
  printf 'RAILS_ENV=production\nRAILS_MAX_THREADS=3\nDB_HOST=%s\nDB_NAME=%s\nDB_USERNAME=%s\nDB_PASSWORD=%s\nSECRET_KEY_BASE=%s\n' \
  '$(terraform output -raw db_address)' '$(terraform output -raw db_name)' '$(terraform output -raw db_username)' \
  \"\$P\" \"\$(openssl rand -hex 64)\" | sudo tee /etc/temple-reservation/backend.env >/dev/null; \
  sudo chown root:ec2-user /etc/temple-reservation/backend.env; sudo chmod 640 /etc/temple-reservation/backend.env"

# 3. Nginx・systemd を設定する
$SSH 'sudo bash ~/temple-reservation/deploy/setup.sh'

# 4. アプリをビルドして起動する（t3.micro では 10〜15分かかる）
$SSH 'bash ~/temple-reservation/deploy/deploy.sh'
```

## 2回目から（コードを更新したとき）

GitHub に push してから：

```bash
ssh -i ~/.ssh/temple-ec2 ec2-user@<公開IP> 'bash ~/temple-reservation/deploy/deploy.sh'
```

## 確認する

```bash
curl http://<公開IP>/up                      # 200 が返れば Rails は動いている
curl "http://<公開IP>/api/calendar?month=2026-11"
```

ブラウザで `http://<公開IP>/` を開くと、カレンダーが表示されます。

## 困ったとき（EC2 の中で）

```bash
systemctl status temple-backend temple-frontend nginx
journalctl -u temple-backend -n 100    # Rails のログ
journalctl -u temple-frontend -n 100   # Next.js のログ
sudo tail -n 100 /var/log/nginx/error.log
```
