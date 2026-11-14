# セキュリティグループ
# - 80番（HTTP）：講師がレビューで見られるよう、どこからでも入れる（基本設計書 9.2）
# - 22番（SSH）：自分の PC の IP アドレスからだけ
# - 3000番（Next.js）・3001番（Rails）は開けない。EC2 の中の Nginx が取り次ぐ

resource "aws_security_group" "app" {
  name        = "${var.project}-sg"
  description = "HTTP from anywhere, SSH only from my IP"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP (Nginx) from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH from my IP"
  cidr_ipv4         = "${var.my_ip}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# 外向きはすべて許可（インストールのダウンロードなどに使う）
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- RDS 用 ---
# 3306 番に入れるのは、上の EC2 のセキュリティグループがついたものだけ
# 自分の PC の IP やインターネットからのルールは書かない

resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "Allow MySQL only from the app EC2"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from app EC2 only"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}
