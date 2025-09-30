# output "c8_public_ip" {
#   value = aws_instance.c8.public_ip
# }

# output "u21_public_ip" {
#   value = aws_instance.u21.public_ip
# }




output "c8_public_ip" {
  value = aws_instance.c8.public_ip
}

output "u21_public_ip" {
  value = aws_instance.u21.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ci_key.private_key_pem
  sensitive = true
}

