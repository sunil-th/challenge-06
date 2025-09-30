# #!/usr/bin/env bash
# # Generates ansible/inventory.ini dynamically from Terraform outputs

# TF_OUTPUT=$(terraform output -json)

# C8_IP=$(echo "$TF_OUTPUT" | jq -r '.c8_public_ip.value')
# U21_IP=$(echo "$TF_OUTPUT" | jq -r '.u21_public_ip.value')

# cat > ansible/inventory.ini <<EOF
# [frontend]
# $C8_IP ansible_user=ec2-user

# [backend]
# $U21_IP ansible_user=ubuntu
# EOF



#!/usr/bin/env bash
# Generate inventory.ini for Ansible

C8_IP=$(terraform output -raw c8_public_ip)
U21_IP=$(terraform output -raw u21_public_ip)

cat > ansible/inventory.ini <<EOF
[frontend]
$C8_IP ansible_user=ec2-user ansible_ssh_private_key_file=ci_id_rsa

[backend]
$U21_IP ansible_user=ubuntu ansible_ssh_private_key_file=ci_id_rsa
EOF



#!/usr/bin/env bash

# Save Terraform outputs as variables
C8_IP=$(terraform output -raw c8_public_ip)
U21_IP=$(terraform output -raw u21_public_ip)

# Save private key (if not already done)
terraform output -raw private_key_pem > ansible/ci_id_rsa
chmod 600 ansible/ci_id_rsa

# Generate inventory.ini
cat > ansible/inventory.ini <<EOF
[frontend]
$C8_IP ansible_user=ec2-user ansible_ssh_private_key_file=ci_id_rsa

[backend]
$U21_IP ansible_user=ubuntu ansible_ssh_private_key_file=ci_id_rsa
EOF
echo "Inventory generated at ansible/inventory.ini" 
