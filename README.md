# CI Pipeline with Terraform + Ansible

This repository provisions and configures:
- `c8.local` (Amazon Linux, frontend, nginx proxy)
- `u21.local` (Ubuntu 21.04, backend, Netdata on 19999)

## Workflow
1. Terraform provisions 2 VMs in the default VPC.
2. Terraform dynamically generates Ansible inventory (`ansible/inventory.ini`).
3. GitHub Actions runs `ansible-playbook site.yml`.

## Run locally
```bash
cd terraform
terraform init
terraform apply -auto-approve

cd ../ansible
ansible-playbook site.yml -i inventory.ini --private-key ../terraform/ci_id_rsa
