#!/usr/bin/env bash
# Generates ansible/inventory.ini dynamically from Terraform outputs

TF_OUTPUT=$(terraform output -json)

C8_IP=$(echo "$TF_OUTPUT" | jq -r '.c8_public_ip.value')
U21_IP=$(echo "$TF_OUTPUT" | jq -r '.u21_public_ip.value')

cat > ansible/inventory.ini <<EOF
[frontend]
$C8_IP ansible_user=ec2-user

[backend]
$U21_IP ansible_user=ubuntu
EOF
