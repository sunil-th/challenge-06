#!/usr/bin/env bash
set -euo pipefail

# Go to terraform directory
cd "$(dirname "$0")/../terraform"

# Capture Terraform outputs safely
C8_IP=$(terraform output -raw c8_public_ip | tr -d '\r')
U21_IP=$(terraform output -raw u21_public_ip | tr -d '\r')
PRIVATE_KEY=$(terraform output -raw private_key_pem | tr -d '\r')

# Go back to repo root
cd ..

# Ensure ansible directory exists
mkdir -p ansible

# Write SSH key to file
echo "$PRIVATE_KEY" > ansible/ci_id_rsa
chmod 600 ansible/ci_id_rsa

# Write clean inventory.ini
cat > ansible/inventory.ini <<EOF
[frontend]
${C8_IP} ansible_user=ec2-user ansible_ssh_private_key_file=ci_id_rsa

[backend]
${U21_IP} ansible_user=ubuntu ansible_ssh_private_key_file=ci_id_rsa
EOF

echo "✅ Inventory generated at ansible/inventory.ini"
