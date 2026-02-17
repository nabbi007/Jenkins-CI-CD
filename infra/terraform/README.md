# Terraform Infrastructure

This Terraform module provisions the Jenkins deployment target infrastructure:

- ECR repository
- EC2 instance (Amazon Linux 2)
- EC2 key pair + private key file
- Security group (22/80)
- IAM role/profile for ECR pull access

## Usage (preferred: terraform)

From repository root, run Terraform directly in the `infra/terraform` folder.

Initialize:

```bash
terraform -chdir=infra/terraform init
```

Plan with optional overrides (example):

```bash
terraform -chdir=infra/terraform plan -var "key_name=jenkins" -var "region=eu-west-1"
```

Apply:

```bash
terraform -chdir=infra/terraform apply -auto-approve -var "key_name=jenkins"
```

Destroy:

```bash
terraform -chdir=infra/terraform destroy -auto-approve
```

After `apply`, you can export the Terraform outputs to an env file used by the deployment steps. Example:

```bash
mkdir -p /tmp
cat > /tmp/jenkins-ec2.env <<EOT
EC2_INSTANCE_ID=$(terraform -chdir=infra/terraform output -raw ec2_instance_id)
EC2_HOST=$(terraform -chdir=infra/terraform output -raw ec2_host)
EC2_PUBLIC_IP=$(terraform -chdir=infra/terraform output -raw ec2_public_ip)
EC2_USER=$(terraform -chdir=infra/terraform output -raw ec2_user)
AWS_REGION=$(terraform -chdir=infra/terraform output -raw aws_region)
AWS_ACCOUNT_ID=$(terraform -chdir=infra/terraform output -raw aws_account_id)
ECR_REGISTRY=$(terraform -chdir=infra/terraform output -raw ecr_registry)
ECR_REPOSITORY=$(terraform -chdir=infra/terraform output -raw ecr_repository)
REGISTRY_REPO=$(terraform -chdir=infra/terraform output -raw registry_repo)
HOST_PORT=$(terraform -chdir=infra/terraform output -raw host_port)
HEALTH_PATH=$(terraform -chdir=infra/terraform output -raw health_path)
SSH_KEY_PATH=$(terraform -chdir=infra/terraform output -raw ssh_key_path)
EOT

chmod 600 /tmp/jenkins-ec2.env

echo "Saved deploy env file: /tmp/jenkins-ec2.env"
```

Notes:

- The repository contains a small wrapper script at `scripts/ec2.sh` that automates these Terraform commands; using it is optional. Direct `terraform` commands are the preferred, explicit approach when managing infrastructure.
- Ensure your AWS credentials are configured (for example via `aws configure` or environment variables) before running Terraform.
