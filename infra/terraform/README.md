# Terraform Infrastructure

This module provisions the Jenkins deployment target infrastructure:

- ECR repository
- EC2 instance (Amazon Linux 2)
- EC2 key pair + private key file
- Security group (22/80)
- IAM role/profile for ECR pull access

## Usage

From repository root:

```bash
bash scripts/ec2.sh apply
```

Plan only:

```bash
bash scripts/ec2.sh plan
```

Destroy:

```bash
bash scripts/ec2.sh destroy
```

The wrapper writes `/tmp/jenkins-ec2.env` for deployment scripts.
