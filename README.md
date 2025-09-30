# Terraform + Ansible CI pipeline

1. Add GitHub secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (optional: AWS_REGION).
2. Push to `main` branch to trigger workflow, or `workflow_dispatch`.
3. The GitHub workflow will:
   - terraform init/apply (creates EC2s and inventory),
   - extract private key to ansible/ci_id_rsa,
   - run ansible-playbook ansible/site.yml.

Run locally (if desired):
```bash
cd terraform
terraform init
terraform apply -auto-approve
# then
cd ../ansible
python3 -m pip install --upgrade pip
python3 -m pip install ansible
ansible-playbook site.yml -i inventory.ini --private-key ci_id_rsa
