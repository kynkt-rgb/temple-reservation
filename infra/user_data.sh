#!/bin/bash
# EC2 が初めて起動したときに1回だけ動く準備の手順
# アプリの配置・Nginx の設定は、このあとのデプロイの作業で行う
# 結果は /var/log/user-data.log に残る
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

# 1. スワップ 2GB（t3.micro はメモリが 1GB しかなく、Ruby や Next.js のビルドで足りなくなるため）
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 2. 道具と、Ruby をビルドするのに必要な部品、Nginx、MySQL のクライアント（DB 本体は入らない）
#    libatomic は Node.js が動くのに必要（Amazon Linux には最初から入っていない）
dnf install -y git tar xz gcc gcc-c++ make patch \
  openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel \
  libatomic nginx mariadb105
# mysql2 gem をビルドするための部品（パッケージ名が違う場合に備えて、もう一方も試す）
dnf install -y mariadb-connector-c-devel || dnf install -y mariadb105-devel

# 3. Node.js（公式サイトの版をそのまま入れる。dnf には 26 系がないため）
cd /tmp
NODE_FILE="node-v${node_version}-linux-x64.tar.xz"
curl -fsSLO "https://nodejs.org/dist/v${node_version}/$NODE_FILE"
curl -fsSLO "https://nodejs.org/dist/v${node_version}/SHASUMS256.txt"
# ダウンロードしたファイルが壊れていないか、公式の一覧と照らし合わせる
grep " $NODE_FILE\$" SHASUMS256.txt | sha256sum -c -
tar -xJf "$NODE_FILE" -C /usr/local --strip-components=1 --no-same-owner
rm -f "$NODE_FILE" SHASUMS256.txt

# 4. Ruby（ruby-build で /opt/ruby にビルドする。dnf には 4.0 系がないため。15〜20分かかる）
#    Amazon Linux 2023 の /tmp はメモリ上の小さな領域（t3.micro では約 450MB）でビルドに足りないため、
#    ディスク上の /var/tmp を使う
export TMPDIR=/var/tmp
git clone --depth 1 https://github.com/rbenv/ruby-build.git /var/tmp/ruby-build
/var/tmp/ruby-build/install.sh
rm -rf /var/tmp/ruby-build
ruby-build "${ruby_version}" /opt/ruby
echo 'export PATH="/opt/ruby/bin:$PATH"' > /etc/profile.d/ruby.sh

# 5. 入ったものを記録
/opt/ruby/bin/ruby -v
/opt/ruby/bin/gem -v
/usr/local/bin/node -v
/usr/local/bin/npm -v
nginx -v
mysql --version
echo "user_data done"
