#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Provisioning with Terraform"
cd terraform
terraform init -input=false
terraform apply -auto-approve
cd ..

echo "==> Waiting for container to be ready for Ansible"
sleep 3

echo "==> Configuring with Ansible"
cd ansible
ansible-playbook -i inventory.ini playbook.yml
cd ..

echo "==> Done. Page should be live at http://<server-ip>:8081"
