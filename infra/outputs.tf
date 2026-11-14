output "public_ip" {
  description = "EC2 の固定の公開 IP アドレス（Elastic IP）"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "アプリの URL（デプロイしたあとで使う。講師に伝える URL）"
  value       = "http://${aws_eip.app.public_ip}/"
}

output "ssh_command" {
  description = "EC2 に入るコマンド"
  value       = "ssh -i ${trimsuffix(var.public_key_path, ".pub")} ec2-user@${aws_eip.app.public_ip}"
}

output "db_address" {
  description = "RDS の接続先（EC2 の中からだけつながる）。Rails の DB_HOST に入れる"
  value       = aws_db_instance.main.address
}

output "db_name" {
  description = "Rails の DB_NAME に入れる値"
  value       = var.db_name
}

output "db_username" {
  description = "Rails の DB_USERNAME に入れる値"
  value       = var.db_username
}

output "db_password" {
  description = "RDS のパスワード（terraform output -raw db_password で見る）。Rails の DB_PASSWORD に入れる"
  value       = random_password.db.result
  sensitive   = true
}
