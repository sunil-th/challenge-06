# #!/usr/bin/env bash
# set -euo pipefail

# # Requires terraform outputs to be available in ./terraform
# cd terraform

# # Read outputs (terraform must be initialized/applied already)
# c8_pub=$(terraform output -raw c8_public_ip)
# c8_priv=$(terraform output -raw c8_private_ip)
# u21_pub=$(terraform output -raw u21_public_ip)
# u21_priv=$(terraform output -raw u21_private_ip)
# key_name=$(terraform output -raw ssh_private_key_path_for_ci || true) || true
# cd ..

# # Determine ansible user per distro
# # c8 is Amazon Linux => 'ec2-user'
# # u21 is Ubuntu => 'ubuntu'
# cat > ansible/inventory.ini <<EOF
# [frontend]
# c8.local ansible_host=${c8_priv} ansible_user=ec2-user ansible_ssh_private_key_file=$PWD/.ci_keys/id_rsa

# [backend]
# u21.local ansible_host=${u21_priv} ansible_user=ubuntu ansible_ssh_private_key_file=$PWD/.ci_keys/id_rsa
# EOF

# echo "Wrote ansible/inventory.ini"









# #!/usr/bin/env bash
# set -euo pipefail

# cd terraform

# # Read outputs safely
# c8_priv=$(terraform output -raw c8_private_ip)
# u21_priv=$(terraform output -raw u21_private_ip)

# cd ..

# KEY_FILE="$PWD/.ci_keys/id_rsa"

# # Validate variables
# if [[ -z "$c8_priv" || -z "$u21_priv" ]]; then
#   echo "Error: Terraform outputs are empty. Run 'terraform apply' first."
#   exit 1
# fi

# # Generate inventory
# cat > ansible/inventory.ini <<EOF
# [frontend]
# c8.local ansible_host=${c8_priv} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_FILE}

# [backend]
# u21.local ansible_host=${u21_priv} ansible_user=ubuntu ansible_ssh_private_key_file=${KEY_FILE}

# [all:vars]
# ansible_python_interpreter=/usr/bin/python3
# EOF

# echo "✅ Wrote ansible/inventory.ini successfully"






#!/bin/bash
set -e

cd "$(dirname "$0")"  # cd to ansible/

echo "DEBUG: Running terraform output commands..."

C8_IP=$(terraform -chdir=../terraform output -raw c8_private_ip || echo "")
U21_IP=$(terraform -chdir=../terraform output -raw u21_private_ip || echo "")

echo "DEBUG: C8_IP=$C8_IP"
echo "DEBUG: U21_IP=$U21_IP"

if [[ -z "$C8_IP" || -z "$U21_IP" ]]; then
  echo "ERROR: One or both Terraform IP outputs are empty. Aborting."
  exit 1
fi

cat > inventory.ini <<EOF
[frontend]
c8 ansible_host=$C8_IP ansible_user=ec2-user

[backend]
u21 ansible_host=$U21_IP ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo "✅ Wrote ansible/inventory.ini successfully"
cat inventory.ini
