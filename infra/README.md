# infra（AWS の EC2 と RDS を Terraform でつくる）

サーバー（EC2）1台と DB（RDS）1台を、なるべく小さいサイズでつくります。
設計は [基本設計書](../docs/basic-design.md) の 9章を参照してください。
アプリを動かす作業（デプロイ）は、次の段階でやります。

## つくるもの

| もの | 中身 |
| --- | --- |
| ネットワーク | VPC 1つ・公開用サブネット 1つ・インターネットゲートウェイ（NAT Gateway は使わない） |
| EC2 | Amazon Linux 2023・t3.micro（メモリ 1GB）・ディスク 20GB・固定の公開 IP（Elastic IP） |
| EC2 に入るもの | Ruby 4.0.9（`/opt/ruby`）・Node.js 26.13.0・Nginx・MySQL クライアント・ビルド用の部品・スワップ 2GB |
| 非公開サブネット | 2つ（1a・1c）。インターネットへの道はない |
| RDS | MySQL 8.4.13・db.t4g.micro・1台（マルチAZなし）・gp3 20GB・自動バックアップ 1日（無料プランの上限）。DB名 `temple_reservation_production`、ユーザー `app` |
| セキュリティグループ | 80番（アプリ）はどこからでも。22番（SSH）は自分の PC の IP からだけ。3306番（DB）は EC2 からだけ |

3000番（Next.js）・3001番（Rails）は外に開けていません。EC2 の中の Nginx が取り次ぎます。

> **注意**：ログイン機能・IP 制限・HTTPS がないため、URL を知っている人は誰でも予約を見たり変えたりできます。本物の個人情報は入れず、ダミーデータだけを使ってください（要件定義書 8.3）。

## 費用の目安（東京リージョン・24時間動かした場合）

| 項目 | 1か月 |
| --- | --- |
| EC2 t3.micro | 約 $9.9 |
| EC2 のディスク 20GB | 約 $1.9 |
| 公開 IPv4（Elastic IP） | 約 $3.7 |
| RDS db.t4g.micro | 約 $18.3 |
| RDS のディスク 20GB | 約 $2.8 |
| 合計 | 約 $36.5 |

- 使わない期間は `terraform destroy` で消すのがいちばんの節約になります。
- EC2 を止めても、Elastic IP の料金（月 約 $3.7）はかかり続けます。

## RDS のパスワード

- Terraform がランダムに作ります。保存されるのは `terraform.tfstate` の中だけで、GitHub には上がりません（`.gitignore` 済み）。
- 見るとき：`terraform output -raw db_password`
- `terraform.tfstate` を消すとパスワードもわからなくなるので、消さないでください。

## はじめにやること（1回だけ）

```bash
# 1. SSH の鍵を作る
ssh-keygen -t ed25519 -f ~/.ssh/temple-ec2 -C "temple-ec2"

# 2. 自分の値を書くファイルを作る
cd infra
cp terraform.tfvars.example terraform.tfvars
curl https://checkip.amazonaws.com   # 出てきた IP を terraform.tfvars の my_ip に書く

# 3. Terraform の準備
terraform init
```

## つくる

```bash
terraform plan    # 何がつくられるかを見る（まだ何もつくられない）
terraform apply   # 内容を見て yes と打つと、つくられる
```

最後に、公開 IP・アプリの URL・SSH のコマンド・RDS の接続先が表示されます。RDS をつくるのに5〜10分かかります。

## 確認する

EC2 が起動してから準備が終わるまで、20〜30分かかります（Ruby をビルドするため）。

```bash
ssh -i ~/.ssh/temple-ec2 ec2-user@<公開IP>
tail -f /var/log/user-data.log   # 準備の記録。最後に "user_data done" と出れば完了
ruby -v          # ruby 4.0.9（ログインしなおすと PATH が通る）
node -v          # v26.13.0
nginx -v
free -h          # Swap が 2.0Gi
```

### RDS につながるか（EC2 の中で）

PC で `terraform output -raw db_address` と `terraform output -raw db_password` を調べてから、EC2 で：

```bash
mysql -h <db_address> -u app -p temple_reservation_production -e 'select version();'
# Enter password: と聞かれたら db_password を貼る → 8.4.13 と出れば OK
```

PC から同じことをしても、つながりません（RDS は EC2 からしか入れないため）。

## IP アドレスが変わったとき

場所が変わると IP アドレスも変わり、SSH で EC2 に入れなくなります（アプリの画面はどこからでも見られます）。
`terraform.tfvars` の `my_ip` を書きなおして、`terraform apply` をもう一度実行してください。

## 使わないときは消す

```bash
terraform destroy   # EC2・RDS・Elastic IP などをまとめて消す（RDS を消すのに5〜10分かかる）
```

RDS のデータも消えます（練習用なので、最後のバックアップは取らない設定です）。
