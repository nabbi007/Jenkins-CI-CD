output "ec2_instance_id" {
  value = aws_instance.app.id
}

output "ec2_host" {
  value = aws_instance.app.public_dns
}

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "ec2_user" {
  value = "ec2-user"
}

output "aws_region" {
  value = var.region
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "ecr_registry" {
  value = local.ecr_registry
}

output "ecr_repository" {
  value = var.ecr_repository
}

output "registry_repo" {
  value = local.registry_repo
}

output "host_port" {
  value = tostring(var.host_port)
}

output "health_path" {
  value = var.health_path
}

output "ssh_key_path" {
  value = local.private_key_path
}
