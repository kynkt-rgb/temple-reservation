# 入力。自分の値は terraform.tfvars に書く（ひな形は terraform.tfvars.example）

variable "my_ip" {
  description = "今使っている PC の IP アドレス。SSH（22番）はここからだけ入れる（curl https://checkip.amazonaws.com で調べる）"
  type        = string

  validation {
    condition     = can(regex("^\\d{1,3}(\\.\\d{1,3}){3}$", var.my_ip))
    error_message = "my_ip は 203.0.113.10 のような IPv4 アドレスで書いてください（/32 はつけない）。"
  }
}

variable "public_key_path" {
  description = "EC2 に登録する SSH 公開鍵の場所"
  type        = string
  default     = "~/.ssh/temple-ec2.pub"
}

variable "region" {
  description = "AWS のリージョン（東京）"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "つくるものの名前の頭につける文字"
  type        = string
  default     = "temple-reservation"
}

# --- EC2 ---

variable "instance_type" {
  description = "EC2 の大きさ（無料プランの対象で小さい t3.micro。メモリ 1GB）"
  type        = string
  default     = "t3.micro"
}

variable "ruby_version" {
  description = "Ruby のバージョン（backend/.ruby-version に合わせる）"
  type        = string
  default     = "4.0.9"
}

variable "node_version" {
  description = "Node.js のバージョン（開発環境に合わせる）"
  type        = string
  default     = "26.13.0"
}

# --- RDS ---

variable "db_name" {
  description = "最初に作るデータベースの名前（backend/config/database.yml の本番用の名前）"
  type        = string
  default     = "temple_reservation_production"
}

variable "db_username" {
  description = "DB にログインするユーザー名"
  type        = string
  default     = "app"
}

variable "db_engine_version" {
  description = "MySQL のバージョン（手元の MySQL 8.4.13 に合わせる）"
  type        = string
  default     = "8.4.13"
}

variable "db_instance_class" {
  description = "RDS の大きさ（MySQL 8.4 で使えるいちばん小さい db.t4g.micro）"
  type        = string
  default     = "db.t4g.micro"
}
