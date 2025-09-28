#!/usr/bin/env bash
set -euo pipefail

# Requires terraform outputs to be available in ./terraform
cd terraform

# Read outputs (terraform must be initialized/applied already)
c8_pub=$(terraform output -raw c8_public_ip)
c8_priv=$(terraform output -raw c8_private_ip)
u21_pub=$(terraform output -raw u21_public_ip)
u21_priv=$(terraform output -raw u21_private_ip)
key_name=$(terraform output -raw ssh_private_key_path_for_ci || true) || true
cd ..

# Determine ansible user per distro
# c8 is Amazon Linux => 'ec2-user'
# u21 is Ubuntu => 'ubuntu'
cat > ansible/inventory.ini <<EOF
[frontend]
c8.local ansible_host=${c8_priv} ansible_user=ec2-user ansible_ssh_private_key_file=$PWD/.ci_keys/id_rsa

[backend]
u21.local ansible_host=${u21_priv} ansible_user=ubuntu ansible_ssh_private_key_file=$PWD/.ci_keys/id_rsa
EOF

echo "Wrote ansible/inventory.ini"
