output "frontend_public_ip" {
  value = aws_instance.c8.public_ip
}

output "frontend_private_ip" {
  value = aws_instance.c8.private_ip
}

output "backend_public_ip" {
  value = aws_instance.u21.public_ip
}

output "backend_private_ip" {
  value = aws_instance.u21.private_ip
}

output "ansible_key_path" {
  value = local_file.private_key_pem.filename
}
